// ignore_for_file: unnecessary_const

import 'package:flutter/material.dart';
import '../../managers/lead_manager.dart';
import '../../services/service_manager.dart';
import '../../widgets/app_drawer.dart';
import 'view_leads_screen.dart';

class AllLeadsScreen extends StatefulWidget {
  const AllLeadsScreen({super.key});

  @override
  State<AllLeadsScreen> createState() => _AllLeadsScreenState();
}

class _AllLeadsScreenState extends State<AllLeadsScreen> {
  final _leadManager = LeadManager();
  final _serviceManager = ServiceManager();
  String _searchQuery = '';
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadLeads();
    _serviceManager.refreshServices().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _loadLeads() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      await _leadManager.loadLeads(forceRefresh: true);
    } catch (e) {
      _loadError = e.toString();
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final leads = _leadManager.allLeads;
    final filteredLeads = leads.where((lead) {
      final query = _searchQuery.trim().toLowerCase();
      if (query.isEmpty) return true;
      return lead.contactName.toLowerCase().contains(query) ||
          (lead.email?.toLowerCase().contains(query) ?? false) ||
          (lead.phone?.toLowerCase().contains(query) ?? false) ||
          (lead.service?.toLowerCase().contains(query) ?? false) ||
          (lead.tags?.toLowerCase().contains(query) ?? false);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      drawer: AppDrawer(
        selectedIndex: 1,
        onItemSelected: (_) => Navigator.pop(context),
      ),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Cloop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: const Color(0xFF0B5CFF)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  child: Container(
                    width: 500,
                    padding: const EdgeInsets.all(24),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Search',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter')),
                          const SizedBox(height: 8),
                          TextField(
                            style: const TextStyle(
                                fontFamily: 'Inter', fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Search by Name, Email, Phone ...',
                              hintStyle: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  fontFamily: 'Inter'),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('Status',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter')),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            style: const TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.black,
                                fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'All Statuses',
                              hintStyle: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontFamily: 'Inter'),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'All Statuses',
                                  child: Text('All Statuses',
                                      style: TextStyle(
                                          fontFamily: 'Inter', fontSize: 12))),
                              DropdownMenuItem(
                                  value: 'New Lead',
                                  child: Text('New Lead',
                                      style: TextStyle(
                                          fontFamily: 'Inter', fontSize: 12))),
                              DropdownMenuItem(
                                  value: 'Appointment Scheduled',
                                  child: Text('Appointment Scheduled',
                                      style: TextStyle(
                                          fontFamily: 'Inter', fontSize: 12))),
                              DropdownMenuItem(
                                  value: 'SMS Sent',
                                  child: Text('SMS Sent',
                                      style: TextStyle(
                                          fontFamily: 'Inter', fontSize: 12))),
                              DropdownMenuItem(
                                  value: 'Email Sent',
                                  child: Text('Email Sent',
                                      style: TextStyle(
                                          fontFamily: 'Inter', fontSize: 12))),
                              DropdownMenuItem(
                                  value: 'Call Later',
                                  child: Text('Call Later',
                                      style: TextStyle(
                                          fontFamily: 'Inter', fontSize: 12))),
                              DropdownMenuItem(
                                  value: 'Ringing No Response',
                                  child: Text('Ringing No Response',
                                      style: TextStyle(
                                          fontFamily: 'Inter', fontSize: 12))),
                              DropdownMenuItem(
                                  value: 'Busy',
                                  child: Text('Busy',
                                      style: TextStyle(
                                          fontFamily: 'Inter', fontSize: 12))),
                              DropdownMenuItem(
                                  value: 'Switched Off / Unavailable',
                                  child: Text('Switched Off / Unavailable',
                                      style: TextStyle(
                                          fontFamily: 'Inter', fontSize: 12))),
                              DropdownMenuItem(
                                  value: 'Not Interested',
                                  child: Text('Not Interested',
                                      style: TextStyle(
                                          fontFamily: 'Inter', fontSize: 12))),
                              DropdownMenuItem(
                                  value: 'Invalid Number',
                                  child: Text('Invalid Number',
                                      style: TextStyle(
                                          fontFamily: 'Inter', fontSize: 12))),
                              DropdownMenuItem(
                                  value: 'Lost',
                                  child: Text('Lost',
                                      style: TextStyle(
                                          fontFamily: 'Inter', fontSize: 12))),
                              DropdownMenuItem(
                                  value: 'Converted',
                                  child: Text('Converted',
                                      style: TextStyle(
                                          fontFamily: 'Inter', fontSize: 12))),
                            ],
                            onChanged: (value) {},
                          ),
                          const SizedBox(height: 16),
                          const Text('Service',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter')),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            style: const TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.black,
                                fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'All Services',
                              hintStyle: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontFamily: 'Inter'),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            items: [
                              const DropdownMenuItem(
                                  value: 'All Services',
                                  child: Text('All Services',
                                      style: TextStyle(
                                          fontFamily: 'Inter', fontSize: 12))),
                              ..._serviceManager.services.map((service) =>
                                  DropdownMenuItem(
                                      value: service,
                                      child: Text(service,
                                          style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 12)))),
                            ],
                            onChanged: (value) {},
                          ),
                          const SizedBox(height: 16),
                          const Text('Tag',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter')),
                          const SizedBox(height: 8),
                          Builder(
                            builder: (context) {
                              final uniqueTags = _leadManager.allLeads
                                  .where((lead) =>
                                      lead.tags != null &&
                                      lead.tags!.isNotEmpty)
                                  .map((lead) => lead.tags!)
                                  .toSet()
                                  .toList();

                              return DropdownButtonFormField<String>(
                                isExpanded: true,
                                style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: Colors.black,
                                    fontSize: 12),
                                decoration: InputDecoration(
                                  hintText: 'All Tags',
                                  hintStyle: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                      fontFamily: 'Inter'),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!)),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                items: [
                                  const DropdownMenuItem(
                                      value: 'All Tags',
                                      child: Text('All Tags',
                                          style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 12))),
                                  ...uniqueTags.map((tag) => DropdownMenuItem(
                                      value: tag,
                                      child: Text(tag,
                                          style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 12)))),
                                ],
                                onChanged: (value) {},
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.grey[600],
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4)),
                                ),
                                child: const Text('Reset',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontFamily: 'Inter')),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4)),
                                ),
                                child: const Text('Apply',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                        fontFamily: 'Inter')),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('All Leads',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter')),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search leads by name, email, phone, service...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _loadError != null
                      ? Center(
                          child: Text(
                            _loadError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                              fontFamily: 'Inter',
                            ),
                          ),
                        )
                      : filteredLeads.isEmpty
                          ? const Center(
                              child: Text('No leads found.',
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                      fontFamily: 'Inter')))
                          : ListView.builder(
                              itemCount: filteredLeads.length,
                              itemBuilder: (context, index) {
                                final lead = filteredLeads[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ViewLeadsScreen(lead: lead),
                                      ),
                                    ).then((_) => _loadLeads());
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(lead.contactName,
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontFamily: 'Inter')),
                                            ),
                                            if (lead.isCompleted)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                    color: Colors.green[50],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4)),
                                                child: const Text('Completed',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.green,
                                                        fontFamily: 'Inter')),
                                              ),
                                            if (lead.isOverdue)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                    color: Colors.red[50],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4)),
                                                child: const Text('Overdue',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.red,
                                                        fontFamily: 'Inter')),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        if (lead.phone != null)
                                          Row(
                                            children: [
                                              const Icon(Icons.phone_outlined,
                                                  size: 16, color: Colors.grey),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                    'Phone: ${lead.phone}',
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        fontFamily: 'Inter',
                                                        color: Colors.grey)),
                                              ),
                                            ],
                                          ),
                                        if (lead.email != null)
                                          Row(
                                            children: [
                                              const Icon(Icons.email_outlined,
                                                  size: 16, color: Colors.grey),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                    'Email: ${lead.email}',
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        fontFamily: 'Inter',
                                                        color: Colors.grey)),
                                              ),
                                            ],
                                          ),
                                        if (lead.followUpDate != null)
                                          Row(
                                            children: [
                                              const Icon(
                                                  Icons.access_time_outlined,
                                                  size: 16,
                                                  color:
                                                      const Color(0xFF0B5CFF)),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                    'Follow-up: ${lead.followUpDate!.day}/${lead.followUpDate!.month}/${lead.followUpDate!.year} ${lead.followUpTime ?? ""}',
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        fontFamily: 'Inter',
                                                        color: const Color(
                                                            0xFF0B5CFF))),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
