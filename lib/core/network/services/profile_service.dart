// ─── profile_service.dart ────────────────────────────────────────────────────

import 'dart:convert';
import 'package:bmc_app/core/errors/api_exceptions.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_client/widget.dart';
import '../models/widget.dart'; // Country

class ProfileService {
  final Dio _dio = ApiClient.instance.dio;

  static const _cacheKey = 'cached_countries_states';
  static const _cacheAtKey = 'cached_countries_states_at';
  static const _cacheMaxAge = Duration(days: 7); // country/state lists rarely change

  Future<List<Country>> fetchCountriesWithStates({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await _readCache();
      if (cached != null) return cached;
    }
    final fetched = await _fetchWithRetry();
    await _writeCache(fetched);
    return fetched;
  }

  Future<List<Country>> _fetchWithRetry({int attempts = 3}) async {
    DioException? lastError;
    for (var i = 0; i < attempts; i++) {
      try {
        final response = await _dio.get(
          ApiEndpoints.worldCountries,
          options: Options(
            sendTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
          ),
        );

        final raw = response.data;
        final payload = (raw is Map && raw.containsKey('data'))
            ? raw['data']
            : raw;

        if (payload is! Map<String, dynamic>) {
          debugPrint('⚠️ Unexpected world-countries response shape: ${payload.runtimeType}');
          return [];
        }

        return Country.buildDirectory(payload);
      } on DioException catch (e) {
        lastError = e;
        final status = e.response?.statusCode;
        final isTransient = (status != null && status >= 500) ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError;

        if (isTransient && i < attempts - 1) {
          debugPrint('⚠️ Countries fetch attempt ${i + 1} failed (${status ?? e.type}), retrying...');
          await Future.delayed(Duration(seconds: 1 << i)); // 1s, 2s, 4s
          continue;
        }
        debugPrint('❌ FETCH COUNTRIES/STATES ERROR: ${e.response?.data}');
        throw ApiException(
          message: 'Failed to load countries and states',
          statusCode: status,
        );
      }
    }
    throw ApiException(message: lastError?.message ?? 'Failed to load countries and states');
  }

  Future<List<Country>?> _readCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      final savedAt = prefs.getInt(_cacheAtKey);
      if (raw == null || savedAt == null) return null;

      final age = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(savedAt));
      if (age > _cacheMaxAge) return null;

      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => Country.fromCache(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Failed to read countries cache: $e');
      return null;
    }
  }

  Future<void> _writeCache(List<Country> countries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(countries.map((c) => c.toCacheJson()).toList()));
      await prefs.setInt(_cacheAtKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Failed to write countries cache: $e');
    }
  }

  // ── Call from your login success handler — fire-and-forget ─────────────
  static void preload() {
    ProfileService().fetchCountriesWithStates().then((countries) {
      debugPrint('✅ Preloaded ${countries.length} countries into cache');
    }).catchError((e) {
      debugPrint('⚠️ Country/state preload failed silently, will retry on next open: $e');
    });
  }
}
