import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../services/document_service.dart';

class DocumentProvider extends ChangeNotifier {
  final DocumentService _service = DocumentService();

  static const int maxUploadBytes = 5 * 1024 * 1024; // 5 MB — adjust to taste

  List<DocumentModel> documents = [];
  bool isLoading = false;
  bool isUploading = false;
  String? errorMessage;

  Future<void> loadDocuments(String refId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      documents = await _service.fetchDocuments(refId);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> pickAndUploadDocument({
    required String refId,
    String? title,
    String? description,
  }) async {
    try {
      // Restrict picker to PDF and images alone.
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return false; // user cancelled

      final pickedFile = result.files.first;
      final extension = pickedFile.extension?.toLowerCase() ?? '';

      String mimeType = 'application/pdf';
      if (extension == 'png') mimeType = 'image/png';
      if (extension == 'jpg' || extension == 'jpeg') mimeType = 'image/jpeg';

      Uint8List? bytes = pickedFile.bytes;
      if (bytes == null && pickedFile.path != null) {
        bytes = await File(pickedFile.path!).readAsBytes();
      }
      if (bytes == null || bytes.isEmpty) {
        errorMessage = 'Could not read that file.';
        notifyListeners();
        return false;
      }

      if (bytes.length > maxUploadBytes) {
        errorMessage =
            'Files must be ${(maxUploadBytes / (1024 * 1024)).toStringAsFixed(0)} MB or smaller.';
        notifyListeners();
        return false;
      }

      // Full data URL, NOT bare base64 — same gotcha as chat attachments on
      // this exact endpoint family (see MESSAGING_ATTACHMENTS.md §5). The
      // web builds this with FileReader.readAsDataURL; sending bare base64
      // stores bytes that differ from what the web produces for the same
      // file, with no error at upload time.
      final dataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';

      final uploadData = DocumentUploadData(
        fileName: pickedFile.name,
        mimeType: mimeType,
        docSize: bytes.length, // RAW byte count, not the base64/data-URL length
        base64: dataUrl,
        title: title ?? pickedFile.name,
        description: description,
        refId: refId,
        isPersonal: true,
      );

      isUploading = true;
      errorMessage = null;
      notifyListeners();

      try {
        final success = await _service.uploadDocument(uploadData);
        if (success) {
          await loadDocuments(refId);
        } else {
          errorMessage = 'Upload failed.';
        }
        return success;
      } catch (e) {
        errorMessage = e.toString();
        return false;
      } finally {
        isUploading = false;
        notifyListeners();
      }
    } catch (e) {
      // Catches failures in picking/reading, not just the upload call —
      // without this, a picker/file-read error propagates as an unhandled
      // Future error and the caller's UI never learns anything went wrong.
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
