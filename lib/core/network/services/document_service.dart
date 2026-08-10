import 'dart:io';

import 'package:bmc_app/core/errors/api_exceptions.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../api_client/widget.dart';
import '../models/document_model.dart';

class DocumentService {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<DocumentModel>> fetchDocuments(String refId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.getCorporateDocuments,
        queryParameters: {'refId': refId},
      );

      final raw = response.data;
      final List list = (raw is Map && raw.containsKey('data')) ? raw['data'] : (raw is List ? raw : []);

      return list.map((e) => DocumentModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException(
        message: _extractMessage(e.response?.data) ?? 'Failed to fetch documents',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<bool> uploadDocument(DocumentUploadData data) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.uploadCorporateDocument,
        data: data.toJson(),
        // Large PDFs/images routinely exceed the default 15s timeout on
        // mobile data even when nothing is wrong — same gotcha documented
        // for chat attachments on this endpoint family.
        options: Options(sendTimeout: const Duration(seconds: 90)),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      throw ApiException(
        message: _extractMessage(e.response?.data) ?? 'Failed to upload document',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<String?> getViewUrl(String documentKey) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.readCorporateDocument,
        queryParameters: {'documentKey': documentKey},
      );
      final raw = response.data;
      if (raw is Map && raw.containsKey('data')) {
        return raw['data']?['url'] ?? raw['data']?.toString();
      }
      return raw.toString();
    } on DioException catch (e) {
      throw ApiException(
        message: _extractMessage(e.response?.data) ?? 'Failed to view document',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<File?> downloadDocumentToFile(String documentKey, String fileName) async {
  try {
    // 1. Fetch the view URL using your existing endpoint
    final viewUrl = await getViewUrl(documentKey);
    if (viewUrl == null || viewUrl.isEmpty) return null;

    // 2. Download the bytes
    final response = await _dio.get<List<int>>(
      viewUrl,
      options: Options(responseType: ResponseType.bytes),
    );

    // 3. Save to local temporary directory for flutter_pdfview
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(response.data!);
    return file;
  } catch (e) {
    return null;
  }
}

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// e.response?.data isn't guaranteed to be a Map — a redirect, a gateway
  /// timeout, or a WAF/not-found page all come back as HTML or plain text
  /// (a String), and `someString['message']` throws "type 'String' is not
  /// a subtype of type 'int' of 'index'" (String's [] operator wants a
  /// character index, not a map key). That crash then masks whatever the
  /// REAL error was — exactly what happened with the 308 above. This only
  /// attempts key access when data is actually a Map.
  String? _extractMessage(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      return data['message']?.toString() ?? data['error']?.toString();
    }
    return null; // don't dump raw HTML/redirect text into a user-facing message
  }
}
