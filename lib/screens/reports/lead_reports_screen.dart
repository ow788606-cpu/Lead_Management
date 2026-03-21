// ignore_for_file: unnecessary_const

import 'package:flutter/material.dart';
import '../../managers/lead_manager.dart';
import '../../models/lead.dart';
import '../../widgets/app_drawer.dart';
import '../tags/tag_api.dart';


class LeadReportsScreen extends StatefulWidget {
  const LeadReportsScreen({super.key});

  @override
  State<LeadReportsScreen> createState() => _LeadReportsScreenState();
}

class _LeadReportsScreenState extends State<LeadReportsScreen> {
  final _leadManager = LeadManager();
  List<TagItem> _tags = [];
  Map<String, Color> _tagColors = {};

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    try {
      _tags = await TagApi.fetchTags();
      _tagColors = {};
      for (final tag in _tags) {
        _tagColors[tag.id.toString()] = _parseColor(tag.colorHex);
        _tagColors[tag.name] = _parseColor(tag.colorHex);
        _tagColors[tag.name.toLowerCase()] = _parseColor(tag.colorHex);
        _tagColors[tag.name.trim()] = _parseColor(tag.colorHex);
        _tagColors[tag.name.trim().toLowerCase()] = _parseColor(tag.colorHex);
      }
      if (mounted) setState(() {});
    } catch (e) {
      // silent
    }
  }

  Color _parseColor(String hex) {
    final normalized = hex.replaceFirst('#', '').toUpperCase();
    if (normalized.length != 6) return const Color(0xFF0B5CFF);
    return Color(int.parse('FF$normalized', radix: 16));
  }

  Widget _buildLeadCard(Lead lead) {
    String statusTag = '';
    Color statusColor = Colors.grey;

    if (lead.isCompleted) {
      statusTag = 'Completed';
      statusColor = Colors.green;
    } else if (lead.isOverdue) {
      statusTag = 'Overdue';
      statusColor = Colors.red;
    } else if (lead.isFresh) {
      statusTag = 'Fresh';
      statusColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(lead.contactName,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black)),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Icon(Icons.phone, size: 18, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Icon(Icons.comment, size: 18, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Icon(Icons.email, size: 18, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (lead.service != null)
                Row(
                  children: [
                    Icon(Icons.design_services, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text('${lead.service}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  ],
                ),
              if (lead.notes != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('${lead.notes}',
                          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
              if (lead.tags != null && lead.tags!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: lead.tags!.split(',').map((tag) {
                    final trimmedTag = tag.trim();
                    if (trimmedTag.isEmpty) return const SizedBox.shrink();

                    String mappedTag = trimmedTag;
                    Color? tagColor;
                    String? tagName;

                    if (_tagColors.containsKey(mappedTag)) {
                      tagColor = _tagColors[mappedTag];
                      final matchingTag = _tags.firstWhere(
                        (t) => t.id.toString() == mappedTag,
                        orElse: () => TagItem(id: 0, name: mappedTag, description: '', colorHex: ''),
                      );
                      tagName = matchingTag.name.isNotEmpty ? matchingTag.name : mappedTag;
                    } else {
                      for (final entry in _tagColors.entries) {
                        if (entry.key.toLowerCase() == mappedTag.toLowerCase()) {
                          tagColor = entry.value;
                          tagName = mappedTag;
                          break;
                        }
                      }
                    }

                    Color textColor;
                    Color backgroundColor;
                    if (tagColor == null) {
                      textColor = const Color(0xFF6B46C1);
                      backgroundColor = const Color(0xFF6B46C1).withValues(alpha: 0.1);
                      tagName = trimmedTag;
                    } else {
                      textColor = tagColor;
                      backgroundColor = tagColor.withValues(alpha: 0.1);
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        tagName ?? trimmedTag,
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (lead.followUpDate != null || statusTag.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 0.5, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (lead.followUpDate != null)
                      Text(
                        'Follow-up : ${lead.followUpDate!.day}/${lead.followUpDate!.month}/${lead.followUpDate!.year} ${lead.followUpTime ?? '10:00 AM'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    if (statusTag.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(statusTag,
                            style: TextStyle(
                                fontSize: 11,
                                color: statusColor,
                                fontWeight: FontWeight.w500)),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leads = _leadManager.allLeads;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: AppDrawer(
        selectedIndex: -1,
        onItemSelected: (_) => Navigator.pop(context),
      ),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Lead Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: leads.isEmpty
          ? const Center(
              child: Text('No leads found.',
                  style: TextStyle(
                      color: Colors.grey, fontSize: 14, fontFamily: 'Inter')))
          : Container(
              margin: const EdgeInsets.only(top: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF4F6FA),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: leads.length,
                itemBuilder: (context, index) => _buildLeadCard(leads[index]),
              ),
            ),
    );
  }
}
