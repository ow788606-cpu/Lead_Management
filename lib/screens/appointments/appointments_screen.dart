import 'package:flutter/material.dart';
import '../../managers/lead_manager.dart';
import '../../models/lead.dart';
import '../leads/detail_lead_screen.dart';
import '../tags/tag_api.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final _leadManager = LeadManager();
  final _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;
  List<TagItem> _tags = [];
  Map<String, Color> _tagColors = {};

  @override
  void initState() {
    super.initState();
    _loadAppointments();
    _loadTags();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    try {
      await _leadManager.loadLeads(forceRefresh: true);
      if (!mounted) return;
      setState(() {
        _error = null;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load appointments.';
        _isLoading = false;
      });
    }
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
      // Handle error silently
    }
  }

  Color _parseColor(String hex) {
    final normalized = hex.replaceFirst('#', '').toUpperCase();
    if (normalized.length != 6) return const Color(0xFF0B5CFF);
    return Color(int.parse('FF$normalized', radix: 16));
  }

  List<Lead> _getFilteredAppointments() {
    final appointments = _leadManager.allLeads
        .where((lead) =>
            lead.followUpDate != null && !lead.isOverdue && !lead.isCompleted)
        .toList()
      ..sort((a, b) => a.followUpDate!.compareTo(b.followUpDate!));

    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return appointments;
    
    return appointments
        .where((lead) =>
            lead.contactName.toLowerCase().contains(query) ||
            (lead.email?.toLowerCase().contains(query) ?? false) ||
            (lead.phone?.contains(query) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final appointments = _getFilteredAppointments();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // White section with search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(Icons.search, color: Colors.grey, size: 20),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Search',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: const Icon(Icons.tune, color: Colors.grey, size: 20),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Gray section with rounded top corners
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF4F6FA),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Text(_error!,
                              style: const TextStyle(color: Colors.red, fontSize: 14)),
                        )
                      : appointments.isEmpty
                          ? const Center(
                              child: Text('No appointments found.',
                                  style: TextStyle(color: Colors.grey, fontSize: 14)),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: appointments.length,
                              itemBuilder: (context, index) =>
                                  _buildLeadCard(appointments[index]),
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadCard(Lead lead) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
                    if (trimmedTag == 'bh') {
                      mappedTag = '15';
                    }

                    Color? tagColor;
                    String? tagName;

                    if (_tagColors.containsKey(mappedTag)) {
                      tagColor = _tagColors[mappedTag];
                      final matchingTag = _tags.firstWhere(
                        (t) => t.id.toString() == mappedTag,
                        orElse: () => TagItem(
                            id: 0, name: mappedTag, description: '', colorHex: ''),
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
              if (lead.followUpDate != null) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 0.5, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Follow-up : ${lead.followUpDate!.day}/${lead.followUpDate!.month}/${lead.followUpDate!.year} ${lead.followUpTime ?? '10:00 AM'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Scheduled',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
