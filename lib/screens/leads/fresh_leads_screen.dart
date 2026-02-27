import 'package:flutter/material.dart';
import '../../managers/lead_manager.dart';

class FreshLeadsScreen extends StatefulWidget {
  const FreshLeadsScreen({super.key});

  @override
  State<FreshLeadsScreen> createState() => _FreshLeadsScreenState();
}

class _FreshLeadsScreenState extends State<FreshLeadsScreen> {
  final _leadManager = LeadManager();

  @override
  Widget build(BuildContext context) {
    final leads = _leadManager.freshLeads;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
                const Text('Fresh Leads', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                const SizedBox(height: 4),
                const Text('Leads created within last 7 days.', style: TextStyle(color: Colors.grey, fontSize: 13, fontFamily: 'Inter')),
                const SizedBox(height: 24),
                Expanded(
                  child: leads.isEmpty
                      ? const Center(child: Text('No fresh leads found.', style: TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Inter')))
                      : ListView.builder(
                          itemCount: leads.length,
                          itemBuilder: (context, index) {
                            final lead = leads[index];
                            return Container(
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
                                        child: Text(lead.contactName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(4)),
                                        child: const Text('Fresh', style: TextStyle(fontSize: 12, color: Colors.green, fontFamily: 'Inter')),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (lead.phone != null) Text('Phone: ${lead.phone}', style: const TextStyle(fontSize: 14, fontFamily: 'Inter', color: Colors.grey)),
                                  if (lead.email != null) Text('Email: ${lead.email}', style: const TextStyle(fontSize: 14, fontFamily: 'Inter', color: Colors.grey)),
                                  if (lead.service != null) Text('Service: ${lead.service}', style: const TextStyle(fontSize: 14, fontFamily: 'Inter', color: Colors.grey)),
                                  if (lead.followUpDate != null)
                                    Text('Follow-up: ${lead.followUpDate!.day}/${lead.followUpDate!.month}/${lead.followUpDate!.year} ${lead.followUpTime ?? ""}',
                                        style: const TextStyle(fontSize: 14, fontFamily: 'Inter', color: Colors.blue)),
                                ],
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
