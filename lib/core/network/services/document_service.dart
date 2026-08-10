import 'dart:convert';
import 'dart:typed_data';
import 'package:bmc_app/core/errors/api_exceptions.dart';
import 'package:dio/dio.dart';
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

  /// Fetches the raw file bytes for viewing, NOT a URL.
  ///
  /// getViewUrl() above assumes /corporate-documents/view returns
  /// JSON like {data: {url: ...}}. That's unconfirmed and, going by the
  /// sibling /messaging/attachment route (documented in
  /// MESSAGING_ATTACHMENTS.md, confirmed working with a real 200 earlier
  /// in this conversation), quite possibly wrong — that route returns raw
  /// bytes directly, Content-Type: application/octet-stream, no JSON
  /// wrapper at all. This method treats /corporate-documents/view the same
  /// way. If it 404s or errors unexpectedly, that's the first thing to
  /// check — you may need to fall back to getViewUrl() + a second fetch on
  /// whatever URL it returns instead.
  Future<Uint8List> downloadDocumentBytes(String documentKey) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.readCorporateDocument,
        queryParameters: {'documentKey': documentKey},
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 45),
        ),
      );
      return Uint8List.fromList(response.data as List<int>);
    } on DioException catch (e) {
      // Error bodies arrive as bytes too, even though responseType is
      // fixed to bytes for the success path — same gotcha as
      // AttachmentService.download().
      String? message;
      final raw = e.response?.data;
      if (raw is List<int>) {
        try {
          final decoded = jsonDecode(utf8.decode(raw));
          message = decoded is Map ? decoded['message']?.toString() : null;
        } catch (_) {
          // Not JSON — leave message null.
        }
      } else {
        message = _extractMessage(raw);
      }
      throw ApiException(
        message: message ?? 'Failed to load document content.',
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
