import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../core/network/models/widget.dart';
import '../../core/network/services/widget.dart';

class DocumentViewerScreen extends StatefulWidget {
  final DocumentModel document;

  const DocumentViewerScreen({super.key, required this.document});

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  final DocumentService _service = DocumentService();
  bool _isLoading = true;
  File? _localFile;
  String? _errorMessage;

  bool get _isPdf =>
      (widget.document.mimeType?.contains('pdf') ?? false) ||
      (widget.document.fileName?.toLowerCase().endsWith('.pdf') ?? false);

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<void> _loadFile() async {
    final file = await _service.downloadDocumentToFile(
      widget.document.id,
      widget.document.fileName ?? 'temp_doc',
    );

    if (mounted) {
      setState(() {
        _localFile = file;
        _isLoading = false;
        if (file == null) _errorMessage = 'Failed to load document content.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.document.title ?? 'Document Viewer',
          style: const TextStyle(fontFamily: 'Lexend', fontSize: 16),
        ),
      ),
      body: _isLoading
          ? Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                color: Colors.white,
                size: 20,
              ),
            )
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : _isPdf
          ? PDFView(
              filePath: _localFile!.path,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
            )
          : Center(child: InteractiveViewer(child: Image.file(_localFile!))),
    );
  }
}
