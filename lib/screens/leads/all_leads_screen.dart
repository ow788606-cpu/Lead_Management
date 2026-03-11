import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../managers/lead_manager.dart';
import '../../models/lead.dart';
import '../tags/tag_api.dart';
import '../../widgets/app_drawer.dart';
import 'detail_lead_screen.dart';

class AllLeadsScreen extends StatefulWidget {
  const AllLeadsScreen({super.key});

  @override
  State<AllLeadsScreen> createState() => _AllLeadsScreenState();
}

class _AllLeadsScreenState extends State<AllLeadsScreen>
    with SingleTickerProviderStateMixin {
  final _leadManager = LeadManager();
  final _searchController = TextEditingController();
  late TabController _tabController;
  int _selectedTab = 0;
  List<TagItem> _tags = [];
  Map<String, Color> _tagColors = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTab = _tabController.index);
    });
    _loadLeads();
    _loadTags();
    _startRealTimeUpdates();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _startRealTimeUpdates() {
    // Refresh data every 5 seconds for real-time updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadLeads();
      _loadTags();
    });
  }

  Future<void> _loadLeads() async {
    try {
      await _leadManager.loadLeads(forceRefresh: true);
      // Ensure tags are loaded before displaying leads
      if (_tagColors.isEmpty) {
        await _loadTags();
      }
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

  List<Lead> _getFilteredLeads() {
    List<Lead> leads;
    switch (_selectedTab) {
      case 1:
        leads = _leadManager.freshLeads;
        break;
      case 2:
        leads = _leadManager.allLeads
            .where(
                (l) => l.followUpDate != null && !l.isCompleted && !l.isOverdue)
            .toList();
        break;
      case 3:
        leads = _leadManager.overdueLeads;
        break;
      case 4:
        leads = _leadManager.completedLeads;
        break;
      default:
        leads = _leadManager.allLeads;
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('All Leads',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B5CFF),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                elevation: 0,
              ),
              child: const Text('Add Lead',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      drawer: AppDrawer(
        selectedIndex: 1,
        onItemSelected: (index) {},
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search leads...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8)),
                  child: IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.black),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: const Color(0xFF0B5CFF),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF0B5CFF),
            tabs: const [
              Tab(text: 'All Leads'),
              Tab(text: 'Fresh Leads'),
              Tab(text: 'Follow-ups'),
              Tab(text: 'Overdue'),
              Tab(text: 'Completed'),
            ],
          ),
          Expanded(
            child: filteredLeads.isEmpty
                ? const Center(child: Text('No leads found'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredLeads.length,
                    itemBuilder: (context, index) =>
                        _buildLeadCard(filteredLeads[index]),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
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
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  if (lead.phone != null)
                    IconButton(
                      icon: const Icon(Icons.phone, size: 20),
                      onPressed: () =>
                          launchUrl(Uri.parse('tel:${lead.phone}')),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.comment,
                      size: 20,
                    ),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  if (lead.email != null)
                    IconButton(
                      icon: const Icon(Icons.email, size: 20),
                      onPressed: () =>
                          launchUrl(Uri.parse('mailto:${lead.email}')),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              if (lead.service != null)
                Row(
                  children: [
                    const Icon(Icons.design_services,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text('${lead.service}',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87)),
                  ],
                ),
              if (lead.notes != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.note_outlined,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('${lead.notes}',
                          style:
                              const TextStyle(fontSize: 13, color: Colors.grey),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
              if (lead.tags != null && lead.tags!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
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
                    if (tagColor == null) {
                      tagColor = const Color(0xFF9CA3AF);
                      tagName = trimmedTag;
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: tagColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tagName ?? trimmedTag,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (lead.followUpDate != null)
                    Text(
                        'Follow-up: ${lead.followUpDate!.day}/${lead.followUpDate!.month}/${lead.followUpDate!.year}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                  if (statusTag.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text(statusTag,
                          style: TextStyle(
                              fontSize: 11,
                              color: statusColor,
                              fontWeight: FontWeight.w500)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
