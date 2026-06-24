import 'package:bmc_app/features/common/show_message.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class Documents extends StatefulWidget {
  const Documents({super.key});

  @override
  State<Documents> createState() => _DocumentsState();
}

class _DocumentsState extends State<Documents> {
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'count': 123},
    {'name': 'Identification', 'count': 10},
    {'name': 'License', 'count': 15},
    {'name': 'Certifications', 'count': 20},
    {'name': 'Employment', 'count': 9},
    {'name': 'Department', 'count': 5},
    {'name': 'Health Records', 'count': 7},
    {'name': 'Admin Records', 'count': 6},
  ];

  final List<Map<String, dynamic>> _documents = [
    {
      'title': 'Staff_ID_Card.png',
      'expiry': '05 2030',
      'status': 'Verified',
      'statusColor': const Color(0xFF22C55E),
    },
    {
      'title': 'Nursing License_2026.pdf',
      'expiry': '05 2030',
      'status': 'Pending',
      'statusColor': const Color(0xFFF59E0B),
    },
    {
      'title': 'BMC_Appointment_Letter.pdf',
      'expiry': '05 2030',
      'status': 'Verified',
      'statusColor': const Color(0xFF22C55E),
    },
  ];

  @override
  Widget build(BuildContext context) {
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
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search document',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                hintStyle: const TextStyle(fontFamily: 'Lexend'),
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          // Categories
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat['name'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat['name'] as String),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor.withOpacity(0.2)
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${cat['name']} (${cat['count']})',
                      style: TextStyle(
                        color: isSelected ? Theme.of(context).primaryColor : null,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 13,
                        fontFamily: 'Lexend',
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // My Documents Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'My Documents',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Lexend',),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Documents List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _documents.length,
              itemBuilder: (context, index) {
                final doc = _documents[index];
                return _buildDocumentCard(doc);
              },
            ),
          ),
        ],
      ),

      // Upload Button
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement upload functionality
              showMessage('Upload feature coming soon', context, status: MessageStatus.info);
            },
            icon: const Icon(Icons.upload, color: Colors.white),
            label: const Text('Upload', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white,  fontFamily: 'Lexend')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
          // Document Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Iconsax.document_text, color: Theme.of(context).primaryColor, size: 28),
          ),
          const SizedBox(width: 14),

          // Document Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc['title'],
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, fontFamily: 'Lexend'),
                ),
                const SizedBox(height: 4),
                Text(
                  'Expires: ${doc['expiry']}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (doc['statusColor'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              doc['status'],
              style: TextStyle(
                color: doc['statusColor'],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
