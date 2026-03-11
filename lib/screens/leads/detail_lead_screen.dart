import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/lead.dart';
import '../../managers/lead_manager.dart';

class DetailLeadScreen extends StatefulWidget {
  final Lead lead;
  final bool startInEditMode;

  const DetailLeadScreen({
    super.key,
    required this.lead,
    this.startInEditMode = false,
  });

  @override
  State<DetailLeadScreen> createState() => _DetailLeadScreenState();
}

class _DetailLeadScreenState extends State<DetailLeadScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _leadManager = LeadManager();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showPersonalDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Personal Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Name', widget.lead.contactName),
                    _buildDetailRow('Email', widget.lead.email ?? 'N/A'),
                    _buildDetailRow('Phone', widget.lead.phone ?? 'N/A'),
                    _buildDetailRow('Service', widget.lead.service ?? 'N/A'),
                    _buildDetailRow('Address', widget.lead.address ?? 'N/A'),
                    _buildDetailRow('City', widget.lead.city ?? 'N/A'),
                    _buildDetailRow('State', widget.lead.state ?? 'N/A'),
                    _buildDetailRow('Country', widget.lead.country ?? 'N/A'),
                    _buildDetailRow('Zip', widget.lead.zip ?? 'N/A'),
                    _buildDetailRow('Tags', widget.lead.tags ?? 'N/A'),
                    _buildDetailRow('Notes', widget.lead.notes ?? 'N/A'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActivityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activity Timeline'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildActivityItem(
                  'Lead Created',
                  '${widget.lead.createdAt.day}/${widget.lead.createdAt.month}/${widget.lead.createdAt.year}',
                  Icons.person_add,
                ),
                if (widget.lead.followUpDate != null)
                  _buildActivityItem(
                    'Follow-up Scheduled',
                    '${widget.lead.followUpDate!.day}/${widget.lead.followUpDate!.month}/${widget.lead.followUpDate!.year}',
                    Icons.schedule,
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Task'),
        content: const Text('Task creation functionality'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showNotesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lead Notes'),
        content: Text(widget.lead.notes ?? 'No notes available'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF4285F4)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(subtitle, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(String title, String priority, String dueDate, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Lead Details',
            style: TextStyle(color: Colors.black, fontSize: 16),
          ),
          centerTitle: true,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.black),
              onSelected: (value) async {
                if (value == 'personal') {
                  _showPersonalDetails();
                } else if (value == 'delete') {
                  final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Delete Lead'),
                      content: const Text('Are you sure you want to delete this lead?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (shouldDelete == true && context.mounted) {
                    _leadManager.deleteLead(widget.lead.id);
                    Navigator.pop(context);
                  }
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem<String>(
                  value: 'personal',
                  child: Text('Personal Details'),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // Lead Header Card
            Container(
              margin: const EdgeInsets.all(16),
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(widget.lead.contactName,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                          if (widget.lead.phone != null)
                            IconButton(
                              icon: const Icon(Icons.phone, size: 20),
                              onPressed: () =>
                                  launchUrl(Uri.parse('tel:${widget.lead.phone}')),
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
                          if (widget.lead.email != null)
                            IconButton(
                              icon: const Icon(Icons.email, size: 20),
                              onPressed: () =>
                                  launchUrl(Uri.parse('mailto:${widget.lead.email}')),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (widget.lead.service != null)
                        Row(
                          children: [
                            const Icon(Icons.design_services,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text('${widget.lead.service}',
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.black87)),
                          ],
                        ),
                      if (widget.lead.notes != null && widget.lead.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.note_outlined,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text('${widget.lead.notes}',
                                  style:
                                      const TextStyle(fontSize: 13, color: Colors.grey),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ],
                      if (widget.lead.tags != null && widget.lead.tags!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: widget.lead.tags!.split(',').map((tag) {
                            final trimmedTag = tag.trim();
                            if (trimmedTag.isEmpty) return const SizedBox.shrink();
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B5CFF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                trimmedTag,
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
                          if (widget.lead.followUpDate != null)
                            Text(
                                'Follow-up: ${widget.lead.followUpDate!.day}/${widget.lead.followUpDate!.month}/${widget.lead.followUpDate!.year}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: widget.lead.isCompleted
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : widget.lead.isOverdue
                                        ? Colors.red.withValues(alpha: 0.1)
                                        : widget.lead.isFresh
                                            ? Colors.blue.withValues(alpha: 0.1)
                                            : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4)),
                            child: Text(
                                widget.lead.isCompleted
                                    ? 'Completed'
                                    : widget.lead.isOverdue
                                        ? 'Overdue'
                                        : widget.lead.isFresh
                                            ? 'Fresh'
                                            : 'Active',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: widget.lead.isCompleted
                                        ? Colors.green
                                        : widget.lead.isOverdue
                                            ? Colors.red
                                            : widget.lead.isFresh
                                                ? Colors.blue
                                                : Colors.grey,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Tab Bar
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey, width: 0.2)),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue,
                tabs: const [
                  Tab(text: 'Activity'),
                  Tab(text: 'Notes'),
                  Tab(text: 'Tasks'),
                ],
              ),
            ),
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Activity Tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildActivityItem(
                          'Lead Created',
                          '${widget.lead.createdAt.day}/${widget.lead.createdAt.month}/${widget.lead.createdAt.year}',
                          Icons.person_add,
                        ),
                        if (widget.lead.followUpDate != null)
                          _buildActivityItem(
                            'Follow-up Scheduled',
                            '${widget.lead.followUpDate!.day}/${widget.lead.followUpDate!.month}/${widget.lead.followUpDate!.year}',
                            Icons.schedule,
                          ),
                      ],
                    ),
                  ),
                  // Notes Tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Text(widget.lead.notes ?? 'No notes available'),
                  ),
                  // Tasks Tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (widget.lead.followUpDate != null)
                          _buildTaskItem('Follow up call', 'High', '${widget.lead.followUpDate!.day}/${widget.lead.followUpDate!.month}/${widget.lead.followUpDate!.year}', widget.lead.isCompleted),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey, width: 0.2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.message, color: Colors.grey),
                  label: const Text('Send Message', style: TextStyle(color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.lead.phone != null
                      ? () => launchUrl(Uri.parse('tel:${widget.lead.phone}'))
                      : null,
                  icon: const Icon(Icons.phone, color: Colors.white),
                  label: const Text('Make a Call', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FloatingActionButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.timeline),
                            title: const Text('Activity'),
                            onTap: () {
                              Navigator.pop(context);
                              _showActivityDialog();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.task),
                            title: const Text('Task'),
                            onTap: () {
                              Navigator.pop(context);
                              _showTaskDialog();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.note),
                            title: const Text('Notes'),
                            onTap: () {
                              Navigator.pop(context);
                              _showNotesDialog();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                backgroundColor: Colors.blue,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}