import 'package:flutter/material.dart';
import '../../managers/lead_manager.dart';

class AllLeadsScreen extends StatefulWidget {
  const AllLeadsScreen({super.key});

  @override
  State<AllLeadsScreen> createState() => _AllLeadsScreenState();
}

class _AllLeadsScreenState extends State<AllLeadsScreen> {
  final _leadManager = LeadManager();

  @override
  Widget build(BuildContext context) {
    final leads = _leadManager.allLeads;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('All Leads', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.blue),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  child: Container(
                    width: 500,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Search', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                        const SizedBox(height: 8),
                        TextField(
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search by Name, Email, Phone ...',
                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Inter'),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey[300]!)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey[300]!)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          style: const TextStyle(fontFamily: 'Inter', color: Colors.black, fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'All Statuses',
                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Inter'),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey[300]!)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey[300]!)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'All Statuses', child: Text('All Statuses', style: TextStyle(fontFamily: 'Inter', fontSize: 12))),
                            DropdownMenuItem(value: 'New Lead', child: Text('New Lead', style: TextStyle(fontFamily: 'Inter', fontSize: 12))),
                            DropdownMenuItem(value: 'Appointment Scheduled', child: Text('Appointment Scheduled', style: TextStyle(fontFamily: 'Inter', fontSize: 12))),
                            DropdownMenuItem(value: 'SMS Sent', child: Text('SMS Sent', style: TextStyle(fontFamily: 'Inter', fontSize: 12))),
                            DropdownMenuItem(value: 'Email Sent', child: Text('Email Sent', style: TextStyle(fontFamily: 'Inter', fontSize: 12))),
                            DropdownMenuItem(value: 'Call Later', child: Text('Call Later', style: TextStyle(fontFamily: 'Inter', fontSize: 12))),
                            DropdownMenuItem(value: 'Ringing No Response', child: Text('Ringing No Response', style: TextStyle(fontFamily: 'Inter', fontSize: 12))),
                            DropdownMenuItem(value: 'Busy', child: Text('Busy', style: TextStyle(fontFamily: 'Inter', fontSize: 12))),
                            DropdownMenuItem(value: 'Switched Off / Unavailable', child: Text('Switched Off / Unavailable', style: TextStyle(fontFamily: 'Inter', fontSize: 12))),
                            DropdownMenuItem(value: 'Not Interested', child: Text('Not Interested', style: TextStyle(fontFamily: 'Inter', fontSize: 12))),
                            DropdownMenuItem(value: 'Invalid Number', child: Text('Invalid Number', style: TextStyle(fontFamily: 'Inter', fontSize: 12))),
                            DropdownMenuItem(value: 'Lost', child: Text('Lost', style: TextStyle(fontFamily: 'Inter', fontSize: 12))),
                            DropdownMenuItem(value: 'Converted', child: Text('Converted', style: TextStyle(fontFamily: 'Inter', fontSize: 12))),
                          ],
                          onChanged: (value) {},
                        ),
                        const SizedBox(height: 16),
                        const Text('Service', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          style: const TextStyle(fontFamily: 'Inter', color: Colors.black, fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'All Services',
                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Inter'),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey[300]!)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey[300]!)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: const [],
                          onChanged: (value) {},
                        ),
                        const SizedBox(height: 16),
                        const Text('Tag', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          style: const TextStyle(fontFamily: 'Inter', color: Colors.black, fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'All Tags',
                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Inter'),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey[300]!)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey[300]!)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: const [],
                          onChanged: (value) {},
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.grey[600],
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              child: const Text('Reset', style: TextStyle(fontSize: 14, color: Colors.white, fontFamily: 'Inter')),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              child: const Text('Apply', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white, fontFamily: 'Inter')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
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
                const Text('All Leads', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                const SizedBox(height: 4),
                const Text('View all your leads.', style: TextStyle(color: Colors.grey, fontSize: 13, fontFamily: 'Inter')),
                const SizedBox(height: 24),
                Expanded(
                  child: leads.isEmpty
                      ? const Center(child: Text('No leads found.', style: TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Inter')))
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
                                      if (lead.isCompleted)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(4)),
                                          child: const Text('Completed', style: TextStyle(fontSize: 12, color: Colors.green, fontFamily: 'Inter')),
                                        ),
                                      if (lead.isOverdue)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(4)),
                                          child: const Text('Overdue', style: TextStyle(fontSize: 12, color: Colors.red, fontFamily: 'Inter')),
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
