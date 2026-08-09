// lib/core/socket/attachment_service.dart
//
// Chat attachments no longer travel inline over the socket — only a
// documentKey reference does. This is the one place that talks to the
// actual bytes, per MESSAGING_ATTACHMENTS.md. Read that file before
// changing anything here; several details below are load-bearing (the data
// URL shape, the description marker, the timeouts) and look like arbitrary
// choices if you haven't seen why they're there.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../api_client/widget.dart';
import '../models/widget.dart';


enum AttachmentFailure { gone, forbidden, unauthorized, serverError, unknown }

class AttachmentException implements Exception {
  final AttachmentFailure kind;
  final String message;

  const AttachmentException(this.kind, this.message);

  @override
  String toString() => 'AttachmentException($kind: $message)';
}

class AttachmentService {
  AttachmentService._();
  static final AttachmentService instance = AttachmentService._();

  final Dio _dio = ApiClient.instance.dio;

  /// The cache IS a map of Futures, not bytes — this is deliberate, not
  /// just an implementation detail. FutureBuilder resets to "loading" any
  /// time it's handed a `future:` object that isn't IDENTICAL to the one
  /// it was already tracking, even if the new one would resolve to the
  /// same data. A naive "return Future.value(cachedBytes)" on every call
  /// creates a brand-new Future object each time — so on any rebuild that
  /// happens before that Future has a chance to settle (new message,
  /// typing indicator, presence change, anything), the attachment bubble
  /// gets reset to "loading" again, forever, even though the bytes were
  /// available instantly. Storing and reusing the SAME Future object per
  /// key is what makes FutureBuilder actually stay "done" once it's done.
  ///
  /// Per-process only, scoped to whoever is currently signed in. The
  /// download response is Cache-Control: private — this must be cleared on
  /// disconnect/logout so one user's files can't survive into the next
  /// sign-in on the same device. Call clear() from ChatProvider's
  /// disconnect handling.
  final Map<String, Future<Uint8List>> _futures = {};

  static const int _maxCacheEntries = 40; // bounded — see the doc's gotcha
  static const int maxUploadBytes = 5 * 1024 * 1024; // 5 MB cap

  // ── Upload ──────────────────────────────────────────────────────────────

  /// Uploads bytes and returns the documentKey to put on the message.
  ///
  /// Throws AttachmentException on failure. Callers MUST NOT send the
  /// message if this throws — that's what makes a message with no file
  /// silent rather than an error. See ChatProvider.sendWithAttachment.
  Future<String> upload({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    void Function(int sent, int total)? onProgress,
  }) async {
    if (bytes.length > maxUploadBytes) {
      throw const AttachmentException(
        AttachmentFailure.unknown,
        'File is larger than 5 MB.',
      );
    }

    // Full data URL, NOT bare base64 — the web builds it with
    // FileReader.readAsDataURL and the app must produce the identical
    // shape, or the two clients store byte-different data for the same
    // file with no error at upload time.
    final dataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';

    try {
      final response = await _dio.post(
        ApiEndpoints.uploadDocument,
        data: {
          'fileName': fileName,
          'mimeType': mimeType,
          'docSize': bytes.length, // RAW byte count, not the base64 length
          'base64': dataUrl,
          'title': fileName,
          // Load-bearing: the only thing separating a chat attachment from
          // a real corporate document, and what the nightly reaper matches
          // on. Must stay byte-identical to CHAT_ATTACHMENT_MARKER in
          // server.ts. Omit this and the file is never reaped.
          'description': 'BMC-CHAT-ATTACHMENT',
        },
        options: Options(sendTimeout: const Duration(seconds: 90)),
        onSendProgress: onProgress,
      );

      final raw = response.data;
      final payload = (raw is Map && raw.containsKey('data'))
          ? raw['data'] as Map<String, dynamic>
          : raw as Map<String, dynamic>;

      final documentKey = payload['documentKey'] as String?;
      if (documentKey == null || documentKey.isEmpty) {
        throw const AttachmentException(
          AttachmentFailure.unknown,
          'Upload succeeded but no documentKey was returned.',
        );
      }
      return documentKey;
    } on DioException catch (e) {
      throw AttachmentException(
        _classify(e.response?.statusCode),
        _extractMessage(e.response?.data) ?? e.message ?? 'Upload failed.',
      );
    }
  }

  // ── Download ────────────────────────────────────────────────────────────

  /// De-duplicates concurrent calls for the same key — several widgets
  /// rendering the same attachment produce exactly one network request —
  /// AND, just as importantly, returns the exact same Future object for
  /// every call once resolved, so FutureBuilder doesn't reset to "loading"
  /// on every unrelated rebuild. See the doc comment on _futures above.
  Future<Uint8List> download(MessageAttachment attachment) {
    final key = attachment.documentKey;
    return _futures.putIfAbsent(key, () => _trackedDownload(key));
  }

  Future<Uint8List> _trackedDownload(String key) async {
    try {
      final bytes = await _downloadNow(key);
      _capIfNeeded();
      return bytes;
    } catch (_) {
      // Don't let a failed attempt cache forever — a transient network
      // error should be retryable on the next rebuild/explicit retry, not
      // permanently stuck. Only a SUCCESSFUL future stays cached.
      _futures.remove(key);
      rethrow;
    }
  }

  void _capIfNeeded() {
    if (_futures.length > _maxCacheEntries) {
      _futures.remove(_futures.keys.first); // crude FIFO — fine for this size
    }
  }

  Future<Uint8List> _downloadNow(String documentKey) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.messagingAttachment,
        queryParameters: {'documentKey': documentKey},
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 45),
        ),
      );

      final bytes = Uint8List.fromList(response.data as List<int>);
      return bytes;
    } on DioException catch (e) {
      final status = e.response?.statusCode;

      // Success streams raw bytes; failure returns JSON, but both arrive as
      // bytes at this layer since responseType is fixed — decode manually.
      String? message;
      final raw = e.response?.data;
      if (raw is List<int>) {
        try {
          final decoded = jsonDecode(utf8.decode(raw));
          message = decoded is Map ? decoded['message']?.toString() : null;
        } catch (_) {
          // Not JSON — leave message null, fall through to the default.
        }
      }

      if (status == 404) {
        // Expected after 7 days, or if the message was deleted for
        // everyone — NOT an error state. Callers should style this muted.
        throw AttachmentException(
          AttachmentFailure.gone,
          message ?? 'This attachment is no longer available.',
        );
      }
      if (status == 403) {
        throw AttachmentException(
          AttachmentFailure.forbidden,
          message ?? 'You do not have access to this attachment.',
        );
      }
      if (status == 401) {
        // AuthInterceptor should already have tried a refresh before this
        // surfaces — treat as a dead session, not a retryable attachment
        // failure.
        throw AttachmentException(
          AttachmentFailure.unauthorized,
          message ?? 'Your session has expired.',
        );
      }
      throw AttachmentException(
        AttachmentFailure.serverError,
        message ?? 'Could not load attachment — try again.',
      );
    }
  }

  // ── Cache maintenance ──────────────────────────────────────────────────

  /// Call when ChatProvider receives `message-deleted`. The server deletes
  /// the underlying bytes when a message is deleted (for everyone,
  /// regardless of keptBy), so a cached copy would show content that no
  /// longer exists anywhere.
  void evict(String documentKey) => _futures.remove(documentKey);

  /// Call on disconnect/logout.
  void clear() => _futures.clear();

  // ── Helpers ─────────────────────────────────────────────────────────────

  AttachmentFailure _classify(int? statusCode) => switch (statusCode) {
    404 => AttachmentFailure.gone,
    403 => AttachmentFailure.forbidden,
    401 => AttachmentFailure.unauthorized,
    _ => AttachmentFailure.serverError,
  };

  String? _extractMessage(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      return data['message']?.toString() ?? data['error']?.toString();
    }
    return data.toString();
  }
}
