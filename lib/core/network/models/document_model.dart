class DocumentModel {
  final String id;
  final String? title;
  final String? fileName;
  final String? description;
  final String? mimeType;
  final int? docSize;
  final String? refId;
  final bool? isPersonal;
  final String? status;
  final String? expiryDate;

  DocumentModel({
    required this.id,
    this.title,
    this.fileName,
    this.description,
    this.mimeType,
    this.docSize,
    this.refId,
    this.isPersonal,
    this.status,
    this.expiryDate,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: (json['id'] ?? json['documentKey'] ?? json['_id'] ?? '').toString(),
      title: json['title'] as String? ?? json['fileName'] as String? ?? 'Untitled',
      fileName: json['fileName'] as String?,
      description: json['description'] as String?,
      mimeType: json['mimeType'] as String?,
      docSize: json['docSize'] is num ? (json['docSize'] as num).toInt() : null,
      refId: json['refId'] as String?,
      isPersonal: _toBool(json['isPersonal']),
      status: json['status'] as String? ?? 'Uploaded',
      expiryDate: json['expiryDate'] as String?,
    );
  }

  /// The backend sends isPersonal as a SQL-style 0/1 int (confirmed live:
  /// `"isPersonal":1`), not a JSON bool. `json['isPersonal'] as bool?`
  /// throws "type 'int' is not a subtype of type 'bool?'" on that — which
  /// is what silently broke the whole list: the exception isn't a
  /// DioException, so DocumentProvider.loadDocuments()'s generic catch
  /// swallowed it, leaving `documents` on its previous (empty) value with
  /// no visible error anywhere in the UI.
  static bool? _toBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return null;
  }
}

class DocumentUploadData {
  final String fileName;
  final String mimeType;
  final int docSize;
  final String base64;
  final String? title;
  final String? description;
  final String? refId;
  final bool isPersonal;

  DocumentUploadData({
    required this.fileName,
    required this.mimeType,
    required this.docSize,
    required this.base64,
    this.title,
    this.description,
    this.refId,
    this.isPersonal = true,
  });

  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'mimeType': mimeType,
        'docSize': docSize,
        'base64': base64,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (refId != null) 'refId': refId,
        'isPersonal': isPersonal,
      };
}
