import 'package:flutter/material.dart';
import '../../managers/lead_manager.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final _leadManager = LeadManager();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    try {
      await _leadManager.loadLeads(forceRefresh: true);
      if (!mounted) return;
      setState(() {
        _error = null;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load appointments.';
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final appointments = _leadManager.allLeads
        .where((lead) =>
            lead.followUpDate != null && !lead.isOverdue && !lead.isCompleted)
        .toList()
      ..sort((a, b) => a.followUpDate!.compareTo(b.followUpDate!));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(title: const Text('Scheduled Appointments')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.red, fontSize: 14)),
                )
              : appointments.isEmpty
                  ? const Center(
                      child: Text('No appointments found.',
                          style: TextStyle(color: Colors.grey, fontSize: 14)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: appointments.length,
                      itemBuilder: (context, index) {
                        final lead = appointments[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lead.contactName,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Follow-up: ${_formatDate(lead.followUpDate!)}'
                                '${lead.followUpTime != null ? ' at ${lead.followUpTime}' : ''}',
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.black87),
                              ),
                              if ((lead.phone ?? '').isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text('Phone: ${lead.phone}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
