import 'package:flutter/material.dart';
import '../../managers/lead_manager.dart';
import '../leads/detail_lead_screen.dart';
import '../leads/view_leads_screen.dart';

class LeadReportsScreen extends StatefulWidget {
  const LeadReportsScreen({super.key});

  @override
  State<LeadReportsScreen> createState() => _LeadReportsScreenState();
}

class _LeadReportsScreenState extends State<LeadReportsScreen> {
  final _leadManager = LeadManager();

  @override
  Widget build(BuildContext context) {
    final leads = _leadManager.allLeads;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lead Reports', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 2),
            Text('View and analyze lead reports', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('All Leads',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter')),
                const SizedBox(height: 4),
                const Text('View all your leads.',
                    style: TextStyle(
                        color: Colors.grey, fontSize: 13, fontFamily: 'Inter')),
                const SizedBox(height: 24),
                Expanded(
                  child: leads.isEmpty
                      ? const Center(
                          child: Text('No leads found.',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  fontFamily: 'Inter')))
                      : ListView.builder(
                          itemCount: leads.length,
                          itemBuilder: (context, index) {
                            final lead = leads[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailLeadScreen(lead: lead),
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
                                          icon: const Icon(Icons.visibility_outlined, color: Colors.blue, size: 20),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ViewLeadsScreen(lead: lead),
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
        ),
      ),
    );
  }
}

