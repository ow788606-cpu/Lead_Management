// ignore_for_file: unnecessary_const

import 'package:flutter/material.dart';
import '../../managers/lead_manager.dart';
import '../../widgets/app_drawer.dart';
import 'view_leads_screen.dart';

class FreshLeadsScreen extends StatefulWidget {
  const FreshLeadsScreen({super.key});

  @override
  State<FreshLeadsScreen> createState() => _FreshLeadsScreenState();
}

class _FreshLeadsScreenState extends State<FreshLeadsScreen> {
  final _leadManager = LeadManager();
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadLeads();
  }

  Future<void> _loadLeads() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _leadManager.loadLeads(forceRefresh: true);
    } catch (e) {
      _error = e.toString();
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final leads = _leadManager.freshLeads;
    final filteredLeads = leads.where((lead) {
      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return lead.contactName.toLowerCase().contains(q) ||
          (lead.phone?.toLowerCase().contains(q) ?? false) ||
          (lead.email?.toLowerCase().contains(q) ?? false) ||
          (lead.service?.toLowerCase().contains(q) ?? false) ||
          (lead.tags?.toLowerCase().contains(q) ?? false);
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fresh Leads',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter')),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search fresh leads...',
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
                  : _error != null
                      ? Center(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                                fontFamily: 'Inter'),
                          ),
                        )
                      : filteredLeads.isEmpty
                          ? const Center(
                              child: Text('No fresh leads found.',
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                      fontFamily: 'Inter')))
                          : ListView.builder(
                              itemCount: filteredLeads.length,
                              itemBuilder: (context, index) {
                                final lead = filteredLeads[index];
                                return InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ViewLeadsScreen(lead: lead),
                                      ),
                                    ).then((_) => _loadLeads());
                                  },
                                  borderRadius: BorderRadius.circular(8),
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
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                  color: Colors.green[50],
                                                  borderRadius:
                                                      BorderRadius.circular(4)),
                                              child: const Text('Fresh',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.green,
                                                      fontFamily: 'Inter')),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        if (lead.phone != null)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(left: 12),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.phone_outlined,
                                                    size: 16,
                                                    color: Colors.grey),
                                                const SizedBox(width: 8),
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
                                          ),
                                        if (lead.email != null)
                                          const SizedBox(height: 8),
                                        if (lead.email != null)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(left: 12),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.email_outlined,
                                                    size: 16,
                                                    color: Colors.grey),
                                                const SizedBox(width: 8),
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
                                          ),
                                        if (lead.service != null)
                                          const SizedBox(height: 8),
                                        if (lead.service != null)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(left: 12),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                    Icons
                                                        .miscellaneous_services_outlined,
                                                    size: 16,
                                                    color: Colors.grey),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                      'Service: ${lead.service}',
                                                      style: const TextStyle(
                                                          fontSize: 14,
                                                          fontFamily: 'Inter',
                                                          color: Colors.grey)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        if (lead.followUpDate != null)
                                          const SizedBox(height: 8),
                                        if (lead.followUpDate != null)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(left: 12),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                    Icons.access_time_outlined,
                                                    size: 16,
                                                    color:
                                                        Color(0xFF0B5CFF)),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                      'Follow-up: ${lead.followUpDate!.day}/${lead.followUpDate!.month}/${lead.followUpDate!.year} ${lead.followUpTime ?? ""}',
                                                      style: const TextStyle(
                                                          fontSize: 14,
                                                          fontFamily: 'Inter',
                                                          color: Color(
                                                              0xFF0B5CFF))),
                                                ),
                                              ],
                                            ),
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
