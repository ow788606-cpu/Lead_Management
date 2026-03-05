import 'package:flutter/material.dart';
import '../../managers/lead_manager.dart';
import '../../widgets/app_drawer.dart';
import 'view_leads_screen.dart';

class OverdueScreen extends StatefulWidget {
  const OverdueScreen({super.key});

  @override
  State<OverdueScreen> createState() => _OverdueScreenState();
}

class _OverdueScreenState extends State<OverdueScreen> {
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
    final leads = _leadManager.overdueLeads;
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
            const Text('Overdue Leads',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter')),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search overdue leads...',
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
                              child: Text('No overdue leads found.',
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
                                                  color: Colors.red[50],
                                                  borderRadius:
                                                      BorderRadius.circular(4)),
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
                                          Text('Phone: ${lead.phone}',
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontFamily: 'Inter',
                                                  color: Colors.grey)),
                                        if (lead.email != null)
                                          Text('Email: ${lead.email}',
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontFamily: 'Inter',
                                                  color: Colors.grey)),
                                        if (lead.service != null)
                                          Text('Service: ${lead.service}',
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontFamily: 'Inter',
                                                  color: Colors.grey)),
                                        if (lead.followUpDate != null)
                                          Text(
                                              'Follow-up: ${lead.followUpDate!.day}/${lead.followUpDate!.month}/${lead.followUpDate!.year} ${lead.followUpTime ?? ""}',
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontFamily: 'Inter',
                                                  color: Colors.red)),
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
