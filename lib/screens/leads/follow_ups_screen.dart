import 'package:flutter/material.dart';
import '../../managers/lead_manager.dart';
import '../../widgets/app_drawer.dart';
import 'detail_lead_screen.dart';
import 'view_leads_screen.dart';

class FollowUpsScreen extends StatefulWidget {
  const FollowUpsScreen({super.key});

  @override
  State<FollowUpsScreen> createState() => _FollowUpsScreenState();
}

class _FollowUpsScreenState extends State<FollowUpsScreen> {
  final _leadManager = LeadManager();

  @override
  Widget build(BuildContext context) {
    final followUpLeads = _leadManager.allLeads
        .where((lead) => lead.followUpDate != null)
        .toList();

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
            const Text('Follow-ups',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter')),
            const SizedBox(height: 16),
            Expanded(
              child: followUpLeads.isEmpty
                  ? const Center(
                      child: Text('No follow-ups scheduled.',
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontFamily: 'Inter')))
                  : ListView.builder(
                          itemCount: followUpLeads.length,
                          itemBuilder: (context, index) {
                            final lead = followUpLeads[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DetailLeadScreen(lead: lead),
                                  ),
                                ).then((_) => setState(() {}));
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(lead.contactName,
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Inter')),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.visibility_outlined,
                                              color: Colors.blue,
                                              size: 20),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ViewLeadsScreen(lead: lead),
                                              ),
                                            );
                                          },
                                        ),
                                        if (lead.isCompleted)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                                color: Colors.green[50],
                                                borderRadius:
                                                    BorderRadius.circular(4)),
                                            child: const Text('Completed',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.green,
                                                    fontFamily: 'Inter')),
                                          ),
                                        if (lead.isOverdue)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
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
                                    if (lead.followUpDate != null)
                                      Text(
                                          'Follow-up: ${lead.followUpDate!.day}/${lead.followUpDate!.month}/${lead.followUpDate!.year} ${lead.followUpTime ?? ""}',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'Inter',
                                              color: Colors.blue)),
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

