import 'package:bmc_app/core/network/provider/widget.dart';
import 'package:bmc_app/features/common/show_message.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import '../../core/network/models/widget.dart';
import '../common/router.dart';

class Documents extends StatefulWidget {
  const Documents({super.key});

  @override
  State<Documents> createState() => _DocumentsState();
}

class _DocumentsState extends State<Documents> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // refId is the personnelId, NOT the REST id — this previously read
      // user?.id, which meant the very first load of this screen fetched
      // under the wrong identity. The upload button below already used
      // personnelId correctly, which is why a freshly-uploaded doc would
      // "fix" the list (its own post-upload refresh uses the right id) even
      // though the initial load never did.
      final personnelId = context.read<UserProvider>().user?.personnelId ?? '';
      if (personnelId.isNotEmpty) {
        context.read<DocumentProvider>().loadDocuments(personnelId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final personnelId = context.watch<UserProvider>().user?.personnelId ?? '';

    return Consumer<DocumentProvider>(
      builder: (context, provider, _) {
        final filteredDocs = provider.documents.where((doc) {
          final query = _searchController.text.toLowerCase();
          return (doc.title ?? '').toLowerCase().contains(query) ||
              (doc.fileName ?? '').toLowerCase().contains(query);
        }).toList();

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 18),
            ),
            title: const Text(
              "Documents",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                fontFamily: 'Lexend',
              ),
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search document',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    hintStyle: const TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 12,
                    ),
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'My Documents',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lexend',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: provider.isLoading
                    ? LoadingAnimationWidget.staggeredDotsWave(
                        color: Colors.white,
                        size: 50,
                      )
                    : provider.errorMessage != null &&
                          provider.documents.isEmpty
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
                                provider.errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Lexend',
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: personnelId.isEmpty
                                    ? null
                                    : () => provider.loadDocuments(personnelId),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : filteredDocs.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.document_text, size: 50),
                          const SizedBox(height: 10),
                          Text(
                            'No documents found.',
                            style: TextStyle(
                              fontFamily: 'Lexend',
                              fontSize: 15,
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          return _buildDocumentCard(filteredDocs[index]);
                        },
                      ),
              ),
            ],
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: provider.isUploading
                    ? null
                    : () async {
                        if (personnelId.isEmpty) {
                          showMessage(
                            'Personnel ID missing',
                            context,
                            status: MessageStatus.error,
                          );
                          return;
                        }
                        final success = await provider.pickAndUploadDocument(
                          refId: personnelId,
                        );
                        if (!mounted) return;
                        if (success) {
                          showMessage(
                            'Document uploaded successfully!',
                            context,
                            status: MessageStatus.success,
                          );
                        } else if (provider.errorMessage != null) {
                          showMessage(
                            provider.errorMessage!,
                            context,
                            status: MessageStatus.error,
                          );
                        }
                      },
                icon: provider.isUploading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: LoadingAnimationWidget.staggeredDotsWave(
                          color: Colors.white,
                          size: 20,
                        ),
                      )
                    : const Icon(Icons.upload, color: Colors.white),
                label: Text(
                  provider.isUploading ? 'Uploading...' : 'Upload PDF/Image',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Lexend',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocumentCard(DocumentModel doc) {
    return GestureDetector(
      onTap: () => GoRouter.of(context).go(
        '${BMCRouter.homePath}/${BMCRouter.documentsPath}/${BMCRouter.documentViewerPath}',
        extra: doc,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Iconsax.document_text,
                color: Theme.of(context).primaryColor,
                size: 25,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title ?? doc.fileName ?? 'Document',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      fontFamily: 'Lexend',
                    ),
                  ),
                  if (doc.expiryDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Expires: ${doc.expiryDate}',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                doc.status ?? 'Uploaded',
                style: const TextStyle(
                  color: Color(0xFF22C55E),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
