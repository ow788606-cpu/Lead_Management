// Bulk Upload Screen - Commented out
/*
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../managers/contact_manager.dart';
import '../../widgets/app_drawer.dart';

class BulkUploadScreen extends StatefulWidget {
  const BulkUploadScreen({super.key});

  @override
  State<BulkUploadScreen> createState() => _BulkUploadScreenState();
}

class _BulkUploadScreenState extends State<BulkUploadScreen> {
  String? _fileName;
  PlatformFile? _selectedFile;
  bool _scheduleFollowUp = false;
  bool _isImporting = false;
  final _contactManager = ContactManager();

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.single;
        _fileName = result.files.single.name;
      });
    }
  }

  void _downloadDemoData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demo data download started')),
    );
  }

  Future<void> _importData() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a CSV file first')),
      );
      return;
    }

    final bytes = _selectedFile!.bytes;
    if (bytes == null || bytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected file is empty or unreadable')),
      );
      return;
    }

    setState(() => _isImporting = true);
    try {
      final result = await _contactManager.bulkUploadCsv(
        bytes: bytes,
        fileName: _selectedFile!.name,
      );
      if (!mounted) return;
      setState(() => _isImporting = false);
      final inserted = result['inserted'] ?? 0;
      final skipped = result['skipped'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Import completed. Inserted: $inserted, Skipped: $skipped')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isImporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to import CSV')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        selectedIndex: 3,
        onItemSelected: (_) => Navigator.pop(context),
      ),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Bulk Import Contact Profiles'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // const Text(
                    //   'Bulk Import Contact Profiles',
                    //   style: TextStyle(
                    //     fontSize: 20,
                    //     fontWeight: FontWeight.bold,
                    //   ),
                    // ),
                    const SizedBox(height: 8),
                    const Text(
                      'Upload multiple contact records via CSV or Excel.',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _downloadDemoData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF131416),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Download Demo Data'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // File Selection Section
              const Text(
                'Choose CSV file',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _pickFile,
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Choose File'),
              ),
              if (_fileName != null) const SizedBox(height: 8),
              if (_fileName != null)
                Text(
                  'Selected: $_fileName',
                  style: const TextStyle(color: Colors.green),
                ),
              const SizedBox(height: 24),

              // Schedule Section
              const Text(
                'Schedule Follow-up for Contacts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _scheduleFollowUp,
                onChanged: (value) {
                  setState(() {
                    _scheduleFollowUp = value ?? false;
                  });
                },
                title: const Text('Enable scheduled follow-up'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 24),

              // Import Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isImporting ? null : _importData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF131416),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _isImporting ? 'Importing...' : 'Import Data',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Instructions Section
              const Text(
                'Instructions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildInstruction(
                '1',
                'Download the demo file from above and use it as a CSV template.',
              ),
              _buildInstruction(
                '2',
                'Add contact details in the template. Required fields: "Name", "Email", "Contact Number", "Address", "State", "City", "Lead Source", "Lead Status".',
              ),
              _buildInstruction(
                '3',
                'Each contact will be added on a new row.',
              ),
              _buildInstruction(
                '4',
                'Duplicate email or contact number entries will be automatically skipped during import.',
              ),
              const SizedBox(height: 32),

              // Auto Create Section
              const Text(
                'Auto Create Leads & Schedule Follow-up',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildInstruction(
                '1',
                'Create basic leads for imported contacts.',
              ),
              _buildInstruction(
                '2',
                'Select the number of leads to be created per interval.',
              ),
              _buildInstruction(
                '3',
                'Choose the interval (time gap) between each lead creation.',
              ),
              _buildInstruction(
                '4',
                'Leads will be created automatically based on the first and interval.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstruction(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
*/
