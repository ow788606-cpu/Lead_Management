// ignore_for_file: unnecessary_const

import 'package:flutter/material.dart';
import '../../managers/lead_manager.dart';
import '../../widgets/app_drawer.dart';
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                                  builder: (context) =>
                                      ViewLeadsScreen(lead: lead),
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
                                      // const Icon(Icons.person_outline_rounded,
                                      //     size: 18, color: Color(0xFF0B5CFF)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(lead.contactName,
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Inter')),
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
                                      if (lead.isCompleted && lead.isOverdue)
                                        const SizedBox(width: 8),
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
                                  const SizedBox(height: 10),
                                  if (lead.phone != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 12),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.phone_outlined,
                                              size: 16, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text('Phone: ${lead.phone}',
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
                                      padding: const EdgeInsets.only(left: 12),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.email_outlined,
                                              size: 16, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text('Email: ${lead.email}',
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
                                      padding: const EdgeInsets.only(left: 12),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.access_time_outlined,
                                              size: 16,
                                              color: Color(0xFF0B5CFF)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                                'Follow-up: ${lead.followUpDate!.day}/${lead.followUpDate!.month}/${lead.followUpDate!.year} ${lead.followUpTime ?? ""}',
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    fontFamily: 'Inter',
                                                    color: Color(0xFF0B5CFF))),
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
      ),
    );
  }
}
