import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
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
  Uint8List? _bytes;
  String? _errorMessage;

  bool get _isPdf =>
      (widget.document.mimeType?.contains('pdf') ?? false) ||
      (widget.document.fileName?.toLowerCase().endsWith('.pdf') ?? false);

  @override
  void initState() {
    super.initState();
    _loadBytes();
  }

  Future<void> _loadBytes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // document.id is the documentKey — see DocumentModel.fromJson, which
      // falls back through id/documentKey/_id depending on which endpoint
      // produced the record.
      final bytes = await _service.downloadDocumentBytes(widget.document.id);
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
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
                color: Theme.of(context).primaryColor,
                size: 40,
              ),
            )
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'Lexend', fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextButton(onPressed: _loadBytes, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          : _isPdf
          ? SfPdfViewer.memory(
              _bytes!,
              // Loading indicator during page rendering (separate from the
              // initial byte-fetch spinner above — this covers Syncfusion's
              // own internal page-render time on large PDFs).
              canShowPaginationDialog: true,
            )
          : InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Center(child: Image.memory(_bytes!)),
            ),
    );
  }
}
