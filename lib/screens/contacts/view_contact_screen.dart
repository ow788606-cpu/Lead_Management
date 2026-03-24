import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hugeicons/hugeicons.dart';
import '../camera_screen.dart';
import '../../managers/lead_manager.dart';
import '../../models/contact.dart';
import '../../widgets/app_drawer.dart';
import '../leads/detail_lead_screen.dart';
import 'edit_contact_screen.dart';

class ViewContactScreen extends StatefulWidget {
  final Contact contact;

  const ViewContactScreen({super.key, required this.contact});

  @override
  State<ViewContactScreen> createState() => _ViewContactScreenState();
}

class _ViewContactScreenState extends State<ViewContactScreen> {
  String? _profileImagePath;

  Future<void> _pickImage() async {
    if (!mounted) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedCamera01,
                color: Color(0xFF131416),
                size: 24,
              ),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedImage02,
                color: Color(0xFF131416),
                size: 24,
              ),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;

    String? imagePath;

    if (choice == 'camera') {
      imagePath = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const CameraScreen()),
      );
    } else {
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      imagePath = image?.path;
    }

    if (imagePath != null && mounted) {
      setState(() => _profileImagePath = imagePath);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture updated'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final leadManager = LeadManager();
    final activeLeads = leadManager.allLeads
        .where((lead) => lead.contactName == widget.contact.name && !lead.isCompleted)
        .toList();
    final closedLeads = leadManager.allLeads
        .where((lead) => lead.contactName == widget.contact.name && lead.isCompleted)
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      drawer: AppDrawer(
        selectedIndex: 3,
        onItemSelected: (_) => Navigator.pop(context),
      ),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedMenu01,
              color: Colors.black,
              size: 24.0,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Client Profile'),
        actions: [
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedNotification03,
              color: Colors.black,
              size: 24.0,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: const Color(0xFF131416),
                              child: _profileImagePath != null
                                  ? ClipOval(
                                      child: Image.file(
                                        File(_profileImagePath!),
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Text(
                                            widget.contact.name[0].toUpperCase(),
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold),
                                          );
                                        },
                                      ),
                                    )
                                  : Text(
                                      widget.contact.name[0].toUpperCase(),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold),
                                    ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const HugeIcon(
                                    icon: HugeIcons.strokeRoundedCamera01,
                                    color: Color(0xFF131416),
                                    size: 16.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(widget.contact.name,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Inter')),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.verified,
                                      color: Colors.green, size: 20),
                                ],
                              ),
                              Text(
                                  '${widget.contact.city ?? ''}${widget.contact.city != null ? ', ' : ''}',
                                  style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                      fontFamily: 'Inter')),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditContactScreen(contact: widget.contact),
                              ),
                            );
                            if (result == true && context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedPencilEdit01,
                            color: Color(0xFF131416),
                            size: 24.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Personal Details',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter')),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                        HugeIcons.strokeRoundedLocation01, widget.contact.address),
                    const SizedBox(height: 12),
                    if (widget.contact.email != null)
                      _buildDetailRow(HugeIcons.strokeRoundedMail01, widget.contact.email!),
                    if (widget.contact.email != null) const SizedBox(height: 12),
                    _buildDetailRow(HugeIcons.strokeRoundedCall,
                        '${widget.contact.phone}${widget.contact.phone2 != null ? ' , ${widget.contact.phone2}' : ''}'),
                    const SizedBox(height: 12),
                    _buildDetailRow(HugeIcons.strokeRoundedClock01,
                        'Joined on ${_formatDate(widget.contact.createdAt)}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Active Leads',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter')),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('(${activeLeads.length})',
                        style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontFamily: 'Inter')),
                    const SizedBox(height: 16),
                    if (activeLeads.isEmpty)
                      const Center(
                        child: Text('No active leads for this contact.',
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                                fontFamily: 'Inter')),
                      )
                    else
                      ...activeLeads.asMap().entries.map((entry) {
                        final index = entry.key;
                        final lead = entry.value;
                        return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailLeadScreen(
                                    lead: lead,
                                    startInEditMode: false,
                                    initialTabIndex: 0,
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (index > 0) const Divider(height: 24, thickness: 0.5),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                          'New Lead Created at ${_formatDate(lead.createdAt)}',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Inter')),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF131416),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('New Lead',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.white,
                                              fontFamily: 'Inter')),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text('Services',
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                        fontFamily: 'Inter')),
                                const SizedBox(height: 4),
                                Text(lead.service ?? 'N/A',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black,
                                        fontFamily: 'Inter')),
                                const SizedBox(height: 12),
                                const Text('Remark',
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                        fontFamily: 'Inter')),
                                const SizedBox(height: 4),
                                Text(lead.notes ?? 'N/A',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black,
                                        fontFamily: 'Inter')),
                                const SizedBox(height: 12),
                                const Text('Last Updated',
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                        fontFamily: 'Inter')),
                                const SizedBox(height: 4),
                                Text(_formatDateTime(lead.createdAt),
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black,
                                        fontFamily: 'Inter')),
                              ],
                            ),
                          );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Closed Leads',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter')),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('(${closedLeads.length})',
                        style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontFamily: 'Inter')),
                    const SizedBox(height: 16),
                    if (closedLeads.isEmpty)
                      const Center(
                        child: Text('No closed leads for this contact.',
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                                fontFamily: 'Inter')),
                      )
                    else
                      ...closedLeads.asMap().entries.map((entry) {
                        final index = entry.key;
                        final lead = entry.value;
                        return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailLeadScreen(
                                    lead: lead,
                                    startInEditMode: false,
                                    initialTabIndex: 0,
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (index > 0) const Divider(height: 24, thickness: 0.5),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                          'Lead Created at ${_formatDate(lead.createdAt)}',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Inter')),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('Completed',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.white,
                                              fontFamily: 'Inter')),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text('Services',
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                        fontFamily: 'Inter')),
                                const SizedBox(height: 4),
                                Text(lead.service ?? 'N/A',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black,
                                        fontFamily: 'Inter')),
                                const SizedBox(height: 12),
                                const Text('Remark',
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                        fontFamily: 'Inter')),
                                const SizedBox(height: 4),
                                Text(lead.notes ?? 'N/A',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black,
                                        fontFamily: 'Inter')),
                                const SizedBox(height: 12),
                                const Text('Last Updated',
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                        fontFamily: 'Inter')),
                                const SizedBox(height: 4),
                                Text(_formatDateTime(lead.createdAt),
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black,
                                        fontFamily: 'Inter')),
                              ],
                            ),
                          );
                      }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        HugeIcon(icon: icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 14, fontFamily: 'Inter')),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    return '${months[date.month - 1]} ${date.day}, ${date.year} $hour:$minute';
  }
}
