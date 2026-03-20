import 'dart:async';
import 'package:flutter/material.dart';
import '../../managers/lead_manager.dart';
import '../../models/lead.dart';
import '../tags/tag_api.dart';
import '../../widgets/app_drawer.dart';
import '../../services/notification_service.dart';
import '../main_screen.dart';
import 'detail_lead_screen.dart';
import 'add_new_lead_screen.dart';

class AllLeadsScreen extends StatefulWidget {
  final int initialTabIndex;

  const AllLeadsScreen({super.key, this.initialTabIndex = 0});

  @override
  State<AllLeadsScreen> createState() => _AllLeadsScreenState();
}

class _AllLeadsScreenState extends State<AllLeadsScreen>
    with SingleTickerProviderStateMixin {
  final _leadManager = LeadManager();
  final _searchController = TextEditingController();
  final _notificationService = NotificationService();
  late TabController _tabController;
  int _selectedTab = 0;
  List<TagItem> _tags = [];
  Map<String, Color> _tagColors = {};
  Timer? _refreshTimer;
  final Set<String> _notifiedLeadIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: widget.initialTabIndex);
    _tabController.addListener(() {
      setState(() => _selectedTab = _tabController.index);
    });
    _selectedTab = widget.initialTabIndex;
    _loadLeads();
    _loadTags();
    _startRealTimeUpdates();
    _notificationService.addListener(_onLeadNotification);
    _notificationService.startMonitoring(_leadManager.allLeads);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    _notificationService.removeListener(_onLeadNotification);
    _notificationService.stopMonitoring();
    super.dispose();
  }

  void _startRealTimeUpdates() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _loadLeads();
      _loadTags();
    });
  }

  Future<void> _loadLeads() async {
    try {
      await _leadManager.loadLeads(forceRefresh: true);
      if (_tagColors.isEmpty) {
        await _loadTags();
      }
      _notificationService.startMonitoring(_leadManager.allLeads);
      if (mounted) setState(() {});
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadTags() async {
    try {
      _tags = await TagApi.fetchTags();
      _tagColors = {};
      for (final tag in _tags) {
        // Store by ID as well as name for flexible matching
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

  void _onLeadNotification(Lead lead) {
    if (_notifiedLeadIds.contains(lead.id)) return;
    _notifiedLeadIds.add(lead.id);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder: Follow-up with ${lead.contactName} in 5 minutes'),
        duration: const Duration(seconds: 5),
        backgroundColor: const Color(0xFF0B5CFF),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailLeadScreen(
                  lead: lead,
                  startInEditMode: false,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Lead> _getFilteredLeads() {
    List<Lead> leads;
    switch (_selectedTab) {
      case 1:
        leads = _leadManager.freshLeads;
        break;
      case 2:
        leads = _leadManager.followUpLeads;
        break;
      case 3:
        leads = _leadManager.overdueLeads;
        break;
      case 4:
        leads = _leadManager.completedLeads;
        break;
      default:
        leads = _leadManager.allLeads.where((lead) => !lead.isCompleted).toList();
    }

    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return leads;
    return leads
        .where((l) =>
            l.contactName.toLowerCase().contains(query) ||
            (l.email?.toLowerCase().contains(query) ?? false) ||
            (l.phone?.contains(query) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredLeads = _getFilteredLeads();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // White section with search and tabs
          Container(
            color: Colors.white,
            child: Column(
              children: [
                Padding(
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
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: const Color(0xFF0B5CFF),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF0B5CFF),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'All Leads'),
                    Tab(text: 'Fresh Leads'),
                    Tab(text: 'Follow-ups'),
                    Tab(text: 'Overdue'),
                    Tab(text: 'Completed'),
                  ],
                ),
              ],
            ),
          ),
          // Gray section with rounded top corners containing the lead cards
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
              child: filteredLeads.isEmpty
                  ? const Center(child: Text('No leads found'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredLeads.length,
                      itemBuilder: (context, index) =>
                          _buildLeadCard(filteredLeads[index]),
                    ),
            ),
          ),
        ],
      ),
    );
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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailLeadScreen(
                lead: lead,
                startInEditMode: false,
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
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey[700])),
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

                    // Map invalid tags to valid database tags
                    String mappedTag = trimmedTag;
                    if (trimmedTag == 'bh') {
                      mappedTag = '15'; // Map 'bh' to 'Office' tag
                    }

                    // Try to find matching tag color (by ID first, then by name)
                    Color? tagColor;
                    String? tagName;

                    // First try to match by ID
                    if (_tagColors.containsKey(mappedTag)) {
                      tagColor = _tagColors[mappedTag];
                      // Find the tag name for this ID
                      final matchingTag = _tags.firstWhere(
                        (t) => t.id.toString() == mappedTag,
                        orElse: () => TagItem(
                            id: 0,
                            name: mappedTag,
                            description: '',
                            colorHex: ''),
                      );
                      tagName = matchingTag.name.isNotEmpty
                          ? matchingTag.name
                          : mappedTag;
                    } else {
                      // Try to match by name (case insensitive)
                      for (final entry in _tagColors.entries) {
                        if (entry.key.toLowerCase() ==
                            mappedTag.toLowerCase()) {
                          tagColor = entry.value;
                          tagName = mappedTag;
                          break;
                        }
                      }
                    }

                    // Use default color for tags not in database
                    Color textColor;
                    Color backgroundColor;
                    
                    if (tagColor == null) {
                      textColor = const Color(0xFF6B46C1); // Purple for unknown tags
                      backgroundColor = const Color(0xFF6B46C1).withValues(alpha: 0.1);
                      tagName = trimmedTag;
                    } else {
                      textColor = tagColor;
                      backgroundColor = tagColor.withValues(alpha: 0.1);
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
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
      ),
    );
  }
}
