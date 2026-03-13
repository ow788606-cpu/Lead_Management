// ignore_for_file: unnecessary_const

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/lead.dart';
import '../../managers/lead_manager.dart';
import '../../managers/task_manager.dart';
import '../../services/service_manager.dart';
import '../../widgets/app_drawer.dart';

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
  final _taskManager = TaskManager();
  
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load tasks from database
      final tasks = await _taskManager.getTasksByLeadId(widget.lead.id);
      _tasks = tasks.map((task) => {
        'title': task.title,
        'description': task.description,
        'priority': task.priority,
        'dueDate': task.dueDate,
        'isCompleted': task.isCompleted,
      }).toList();
      
      // Load activities (mock data for now)
      _activities = [
        {
          'title': 'Lead Created',
          'description': 'Lead was created in the system',
          'date': widget.lead.createdAt,
          'icon': Icons.person_add,
        },
        if (widget.lead.followUpDate != null)
          {
            'title': 'Follow-up Scheduled',
            'description': 'Follow-up scheduled for ${widget.lead.followUpDate!.day}/${widget.lead.followUpDate!.month}/${widget.lead.followUpDate!.year}',
            'date': widget.lead.followUpDate!,
            'icon': Icons.schedule,
          },
      ];
      
      // Load notes (mock data for now)
      _notes = [
        if (widget.lead.notes != null && widget.lead.notes!.isNotEmpty)
          {
            'content': widget.lead.notes!,
            'date': widget.lead.createdAt,
          }
      ];
    } catch (e) {
      print('Error loading data: $e');
      // Fallback to mock data
      _activities = [
        {
          'title': 'Lead Created',
          'description': 'Lead was created in the system',
          'date': widget.lead.createdAt,
          'icon': Icons.person_add,
        },
      ];
      _notes = [];
      _tasks = [];
    }
    
    setState(() => _isLoading = false);
  }

  void _showAddActivityDialog() {
    final remarksController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        title: Row(
          children: [
            const SizedBox(width: 32), // Space equivalent to back button
            Expanded(
              child: Text(
                'Lead Activity',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 32), // Balance the spacing
          ],
        ),
        content: SizedBox(
          width: 320,
          height: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Activity Options
              Expanded(
                child: ListView(
                  children: ['Called', 'SMS Sent', 'Email Sent', 'Lead Lost', 'Lead Converted']
                      .map((activity) => ListTile(
                            title: Text(activity, style: const TextStyle(fontSize: 14)),
                            onTap: () {
                              if (activity == 'Called') {
                                Navigator.pop(context);
                                _showCallOutcomeDialog(remarksController);
                              } else {
                                Navigator.pop(context);
                                _showActivityDetailsDialog(activity, remarksController);
                              }
                            },
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  void _showActivityDetailsDialog(String activity, TextEditingController remarksController) {
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    String? selectedLostReason;
    final dealAmountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          title: Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _showAddActivityDialog();
                },
                icon: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Expanded(
                child: Text(
                  activity,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 32), // Balance the back button
            ],
          ),
          content: SizedBox(
            width: 320,
            height: 280,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Date and Time fields for SMS Sent and Email Sent
                  if (activity == 'SMS Sent' || activity == 'Email Sent') ...[
                    // Date Field
                    const Text(
                      'Date',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: dialogContext,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setDialogState(() => selectedDate = date);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedDate != null
                                    ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                                    : 'Select date',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Time Field
                    const Text(
                      'Time',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: dialogContext,
                          initialTime: selectedTime ?? TimeOfDay.now(),
                        );
                        if (time != null) {
                          setDialogState(() => selectedTime = time);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedTime != null
                                    ? selectedTime!.format(dialogContext)
                                    : 'Select time',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            const Icon(Icons.access_time, size: 20, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Lost Reason dropdown for Lead Lost
                  if (activity == 'Lead Lost') ...[
                    const Text(
                      'Lost Reason *',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedLostReason,
                      hint: const Text('Select reason', style: TextStyle(fontSize: 14)),
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                      isExpanded: true,
                      items: [
                        'No Budget',
                        'Not Interested',
                        'Postponed / Will decide later',
                        'No Response',
                        'Bought service from someone else'
                      ].map((reason) => 
                        DropdownMenuItem(value: reason, child: Text(reason, overflow: TextOverflow.ellipsis))
                      ).toList(),
                      onChanged: (value) => setDialogState(() => selectedLostReason = value),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Deal Amount field for Lead Converted
                  if (activity == 'Lead Converted') ...[
                    const Text(
                      'Deal Amount',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: dealAmountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter Amount',
                        contentPadding: EdgeInsets.all(12),
                        prefixText: '₹ ',
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Remarks Section
                  const Text(
                    'Remark *',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: activity == 'Lead Lost' ? 80 : 
                           activity == 'Lead Converted' ? 80 :
                           (activity == 'SMS Sent' || activity == 'Email Sent') ? 60 : 120,
                    child: TextField(
                      controller: remarksController,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter remarks...',
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _showAddActivityDialog();
              },
              child: const Text('Back', style: TextStyle(fontSize: 14)),
            ),
            ElevatedButton(
              onPressed: () {
                bool isValid = remarksController.text.isNotEmpty;
                if (activity == 'Lead Lost') {
                  isValid = isValid && selectedLostReason != null;
                }
                
                if (isValid) {
                  String description = remarksController.text;
                  
                  // Add date and time info for SMS Sent and Email Sent
                  if ((activity == 'SMS Sent' || activity == 'Email Sent') && 
                      selectedDate != null && selectedTime != null) {
                    description += '\nSent on: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year} at ${selectedTime!.format(dialogContext)}';
                  }
                  
                  // Add lost reason for Lead Lost
                  if (activity == 'Lead Lost' && selectedLostReason != null) {
                    description += '\nReason: $selectedLostReason';
                  }
                  
                  // Add deal amount for Lead Converted
                  if (activity == 'Lead Converted' && dealAmountController.text.isNotEmpty) {
                    description += '\nDeal Amount: ₹${dealAmountController.text}';
                  }
                  
                  setState(() {
                    _activities.add({
                      'title': activity,
                      'description': description,
                      'date': DateTime.now(),
                      'icon': _getActivityIcon(activity),
                    });
                  });
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Activity added successfully')),
                  );
                } else {
                  String errorMessage = 'Please enter remarks';
                  if (activity == 'Lead Lost' && selectedLostReason == null) {
                    errorMessage = 'Please select a lost reason and enter remarks';
                  }
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text(errorMessage)),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0b5cff),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Save', style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCallOutcomeDialog(TextEditingController remarksController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        title: Row(
          children: [
            IconButton(
              onPressed: () {
                Navigator.pop(context);
                _showAddActivityDialog();
              },
              icon: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            Expanded(
              child: Text(
                'Call Outcome',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 32), // Balance the back button
          ],
        ),
        content: SizedBox(
          width: 320,
          height: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Call Outcome Options
              Expanded(
                child: ListView(
                  children: [
                    'Appointment Scheduled',
                    'Call Later',
                    'Ringing – No Response',
                    'Busy',
                    'Switched Off / Unavailable',
                    'Invalid Number'
                  ].map((outcome) => ListTile(
                        title: Text(outcome, style: const TextStyle(fontSize: 14)),
                        onTap: () {
                          Navigator.pop(context);
                          _showOutcomeDetailsDialog(outcome, remarksController);
                        },
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showAddActivityDialog();
            },
            child: const Text('Back', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  void _showOutcomeDetailsDialog(String outcome, TextEditingController remarksController) {
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          title: Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _showCallOutcomeDialog(remarksController);
                },
                icon: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Expanded(
                child: Text(
                  outcome,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 32), // Balance the back button
            ],
          ),
          content: SizedBox(
            width: 320,
            height: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Date Field
                const Text(
                  'Date',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: dialogContext,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDate != null
                                ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                                : 'Select date',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Time Field
                const Text(
                  'Time',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: dialogContext,
                      initialTime: selectedTime ?? TimeOfDay.now(),
                    );
                    if (time != null) {
                      setDialogState(() => selectedTime = time);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedTime != null
                                ? selectedTime!.format(dialogContext)
                                : 'Select time',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const Icon(Icons.access_time, size: 20, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Remarks Section
                const Text(
                  'Remark *',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: TextField(
                    controller: remarksController,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter remarks...',
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _showCallOutcomeDialog(remarksController);
              },
              child: const Text('Back', style: TextStyle(fontSize: 14)),
            ),
            ElevatedButton(
              onPressed: () {
                if (remarksController.text.isNotEmpty) {
                  String activityTitle = 'Called - $outcome';
                  String description = remarksController.text;
                  
                  if (selectedDate != null && selectedTime != null) {
                    description += '\n${_getDateTimeLabel(outcome)}: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year} at ${selectedTime!.format(dialogContext)}';
                  }
                  
                  setState(() {
                    _activities.add({
                      'title': activityTitle,
                      'description': description,
                      'date': DateTime.now(),
                      'icon': Icons.phone,
                    });
                  });
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Call activity added successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Please enter remarks')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0b5cff),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Save', style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  String _getDateTimeLabel(String outcome) {
    switch (outcome) {
      case 'Appointment Scheduled':
        return 'Appointment';
      case 'Call Later':
        return 'Callback';
      case 'Ringing – No Response':
        return 'Next attempt';
      case 'Busy':
        return 'Retry';
      case 'Switched Off / Unavailable':
        return 'Retry';
      case 'Invalid Number':
        return 'Follow-up';
      default:
        return 'Follow-up';
    }
  }

  IconData _getActivityIcon(String activity) {
    switch (activity) {
      case 'Called':
        return Icons.phone;
      case 'SMS Sent':
        return Icons.sms;
      case 'Email Sent':
        return Icons.email;
      case 'Lead Lost':
        return Icons.cancel;
      case 'Lead Converted':
        return Icons.check_circle;
      default:
        return Icons.event;
    }
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String priority = 'Medium';
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          title: Row(
            children: [
              const SizedBox(width: 32), // Space equivalent to back button
              Expanded(
                child: Text(
                  'Create Task',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 32), // Balance the spacing
            ],
          ),
          content: SizedBox(
            width: 320,
            height: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Task Title *',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 36,
                  child: TextField(
                    controller: titleController,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter task title...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Priority',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 36,
                  child: DropdownButtonFormField<String>(
                    value: priority,
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                    items: ['Low', 'Medium', 'High'].map((p) => 
                      DropdownMenuItem(value: p, child: Text(p))
                    ).toList(),
                    onChanged: (value) => setDialogState(() => priority = value!),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Due Date',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 36,
                            child: GestureDetector(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: dialogContext,
                                  initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 1)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2100),
                                );
                                if (date != null) {
                                  setDialogState(() => selectedDate = date);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        selectedDate != null
                                            ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                                            : 'Select date',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Due Time',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 36,
                            child: GestureDetector(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: dialogContext,
                                  initialTime: selectedTime ?? TimeOfDay.now(),
                                );
                                if (time != null) {
                                  setDialogState(() => selectedTime = time);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        selectedTime != null
                                            ? selectedTime!.format(dialogContext)
                                            : 'Select time',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Description',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: TextField(
                    controller: descriptionController,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter description...',
                      contentPadding: EdgeInsets.all(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(fontSize: 14)),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  DateTime dueDate = selectedDate ?? DateTime.now().add(const Duration(days: 1));
                  if (selectedTime != null) {
                    dueDate = DateTime(
                      dueDate.year,
                      dueDate.month,
                      dueDate.day,
                      selectedTime!.hour,
                      selectedTime!.minute,
                    );
                  }
                  
                  setState(() {
                    _tasks.add({
                      'title': titleController.text,
                      'description': descriptionController.text,
                      'priority': priority,
                      'dueDate': dueDate,
                      'isCompleted': false,
                    });
                  });
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Task created successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Please enter task title')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0b5cff),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Create', style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddNoteDialog() {
    final noteController = TextEditingController();
    bool isBold = false;
    bool isItalic = false;
    bool isUnderline = false;
    String textStyle = 'Normal';
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          title: Row(
            children: [
              const SizedBox(width: 32), // Space equivalent to back button
              Expanded(
                child: Text(
                  'Add Notes',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 32), // Balance the spacing
            ],
          ),
          content: SizedBox(
            width: 380, // Slightly smaller width
            height: 350,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Formatting Toolbar - Scrollable
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.grey.shade50,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Text Style Dropdown
                        Container(
                          width: 90,
                          child: DropdownButton<String>(
                            value: textStyle,
                            underline: const SizedBox(),
                            style: const TextStyle(fontSize: 11, color: Colors.black),
                            isExpanded: true,
                            items: ['Normal', 'H1', 'H2', 'H3']
                                .map((style) => DropdownMenuItem(
                                      value: style == 'H1' ? 'Heading 1' :
                                             style == 'H2' ? 'Heading 2' :
                                             style == 'H3' ? 'Heading 3' : style,
                                      child: Text(style, style: const TextStyle(fontSize: 11)),
                                    ))
                                .toList(),
                            onChanged: (value) => setDialogState(() => textStyle = value!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 20,
                          width: 1,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 8),
                        // Bold Button
                        GestureDetector(
                          onTap: () => setDialogState(() => isBold = !isBold),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isBold ? const Color(0xFF0b5cff) : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'B',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Italic Button
                        GestureDetector(
                          onTap: () => setDialogState(() => isItalic = !isItalic),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isItalic ? const Color(0xFF0b5cff) : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'I',
                              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Underline Button
                        GestureDetector(
                          onTap: () => setDialogState(() => isUnderline = !isUnderline),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isUnderline ? const Color(0xFF0b5cff) : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'U',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 20,
                          width: 1,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 8),
                        // Link Button
                        GestureDetector(
                          onTap: () {
                            // Link functionality placeholder
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.link, size: 14),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Bullet List Button
                        GestureDetector(
                          onTap: () {
                            _insertBulletPoint(noteController);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.format_list_bulleted, size: 14),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Numbered List Button
                        GestureDetector(
                          onTap: () {
                            _insertNumberedPoint(noteController);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.format_list_numbered, size: 14),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Text Format Button
                        GestureDetector(
                          onTap: () {
                            // Text format functionality placeholder
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.text_format, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Note Content Field
                Expanded(
                  child: TextField(
                    controller: noteController,
                    maxLines: null,
                    expands: true,
                    style: TextStyle(
                      fontSize: textStyle == 'Heading 1' ? 18 :
                               textStyle == 'Heading 2' ? 16 :
                               textStyle == 'Heading 3' ? 15 : 14,
                      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                      decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
                    ),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Add your notes here...',
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(fontSize: 14)),
            ),
            ElevatedButton(
              onPressed: () {
                if (noteController.text.isNotEmpty) {
                  // Create formatted note content
                  String formattedContent = noteController.text;
                  List<String> formatTags = [];
                  
                  if (textStyle != 'Normal') formatTags.add(textStyle);
                  if (isBold) formatTags.add('Bold');
                  if (isItalic) formatTags.add('Italic');
                  if (isUnderline) formatTags.add('Underline');
                  
                  if (formatTags.isNotEmpty) {
                    formattedContent += '\n[Formatting: ${formatTags.join(', ')}]';
                  }
                  
                  setState(() {
                    _notes.add({
                      'content': formattedContent,
                      'date': DateTime.now(),
                    });
                  });
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Note added successfully')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0b5cff),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Add', style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  void _insertBulletPoint(TextEditingController controller) {
    final text = controller.text;
    final selection = controller.selection;
    
    if (selection.isValid) {
      final cursorPosition = selection.baseOffset;
      
      // Find the start of the current line
      int lineStart = text.lastIndexOf('\n', cursorPosition - 1) + 1;
      if (lineStart < 0) lineStart = 0;
      
      // Check if we're at the beginning of a line or if the line is empty
      final currentLine = text.substring(lineStart, cursorPosition);
      
      String newText;
      int newCursorPosition;
      
      if (currentLine.trim().isEmpty) {
        // Insert bullet at current position
        newText = text.substring(0, lineStart) + '• ' + text.substring(cursorPosition);
        newCursorPosition = lineStart + 2;
      } else {
        // Insert bullet on new line
        newText = text.substring(0, cursorPosition) + '\n• ' + text.substring(cursorPosition);
        newCursorPosition = cursorPosition + 3;
      }
      
      controller.text = newText;
      controller.selection = TextSelection.collapsed(offset: newCursorPosition);
    }
  }

  void _insertNumberedPoint(TextEditingController controller) {
    final text = controller.text;
    final selection = controller.selection;
    
    if (selection.isValid) {
      final cursorPosition = selection.baseOffset;
      
      // Find the start of the current line
      int lineStart = text.lastIndexOf('\n', cursorPosition - 1) + 1;
      if (lineStart < 0) lineStart = 0;
      
      // Count existing numbered items to determine next number
      final lines = text.substring(0, cursorPosition).split('\n');
      int nextNumber = 1;
      for (String line in lines) {
        final trimmed = line.trim();
        if (RegExp(r'^\d+\.\s').hasMatch(trimmed)) {
          final match = RegExp(r'^(\d+)\.').firstMatch(trimmed);
          if (match != null) {
            final num = int.tryParse(match.group(1)!) ?? 0;
            if (num >= nextNumber) {
              nextNumber = num + 1;
            }
          }
        }
      }
      
      // Check if we're at the beginning of a line or if the line is empty
      final currentLine = text.substring(lineStart, cursorPosition);
      
      String newText;
      int newCursorPosition;
      
      if (currentLine.trim().isEmpty) {
        // Insert numbered point at current position
        newText = text.substring(0, lineStart) + '$nextNumber. ' + text.substring(cursorPosition);
        newCursorPosition = lineStart + '$nextNumber. '.length;
      } else {
        // Insert numbered point on new line
        newText = text.substring(0, cursorPosition) + '\n$nextNumber. ' + text.substring(cursorPosition);
        newCursorPosition = cursorPosition + '\n$nextNumber. '.length;
      }
      
      controller.text = newText;
      controller.selection = TextSelection.collapsed(offset: newCursorPosition);
    }
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
            // Header with close button
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 24), // Balance the close button
                  const Text(
                    'Contact Details',
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
                    // Profile Section
                    Center(
                      child: Column(
                        children: [
                          // Profile Avatar
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0b5cff),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                widget.lead.contactName.isNotEmpty 
                                    ? widget.lead.contactName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Name and Service
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.lead.contactName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (widget.lead.service != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Phone Number
                          if (widget.lead.phone != null)
                            Text(
                              widget.lead.phone!,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Personal Details Section
                    const Text(
                      'Personal Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Address
                    if (widget.lead.address != null && widget.lead.address!.isNotEmpty)
                      _buildPersonalDetailItem(
                        Icons.location_on_outlined,
                        widget.lead.address!,
                      ),
                    // Email
                    if (widget.lead.email != null && widget.lead.email!.isNotEmpty)
                      _buildPersonalDetailItem(
                        Icons.email_outlined,
                        widget.lead.email!,
                      ),
                    // Phone (if different from header or additional numbers)
                    if (widget.lead.phone != null && widget.lead.phone!.isNotEmpty)
                      _buildPersonalDetailItem(
                        Icons.phone_outlined,
                        widget.lead.phone!,
                      ),
                    // Joined Date
                    _buildPersonalDetailItem(
                      Icons.access_time_outlined,
                      'Joined on ${_formatDate(widget.lead.createdAt)}',
                    ),
                    // Service
                    if (widget.lead.service != null && widget.lead.service!.isNotEmpty)
                      _buildPersonalDetailItem(
                        Icons.work_outline,
                        widget.lead.service!,
                      ),
                    // Tags
                    if (widget.lead.tags != null && widget.lead.tags!.isNotEmpty)
                      _buildPersonalDetailItem(
                        Icons.label_outline,
                        widget.lead.tags!,
                      ),
                    // Notes
                    if (widget.lead.notes != null && widget.lead.notes!.isNotEmpty)
                      _buildPersonalDetailItem(
                        Icons.note_outlined,
                        widget.lead.notes!,
                      ),
                    // Follow-up info
                    if (widget.lead.followUpDate != null)
                      _buildPersonalDetailItem(
                        Icons.schedule_outlined,
                        'Follow-up: ${_formatDate(widget.lead.followUpDate!)}${widget.lead.followUpTime != null ? ' at ${widget.lead.followUpTime}' : ''}',
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalDetailItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _showEditDialog() {
    final nameController = TextEditingController(text: widget.lead.contactName);
    final emailController = TextEditingController(text: widget.lead.email ?? '');
    final phoneController = TextEditingController(text: widget.lead.phone ?? '');
    final notesController = TextEditingController(text: widget.lead.notes ?? '');
    final tagsController = TextEditingController(text: widget.lead.tags ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Lead'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tags',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Here you would typically update the lead in the database
              // For now, just show a success message
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lead updated successfully')),
              );
            },
            child: const Text('Save'),
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

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(activity['icon'], color: const Color(0xFF0b5cff)),
        title: Text(activity['title']),
        subtitle: Text(activity['description']),
        trailing: Text(
          '${activity['date'].day}/${activity['date'].month}/${activity['date'].year}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildNoteItem(Map<String, dynamic> note) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note['content'],
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              '${note['date'].day}/${note['date'].month}/${note['date'].year}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(Map<String, dynamic> task) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          task['isCompleted'] ? Icons.check_circle : Icons.radio_button_unchecked,
          color: task['isCompleted'] ? Colors.green : Colors.grey,
        ),
        title: Text(task['title']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task['description']),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: task['priority'] == 'High' ? Colors.red.withOpacity(0.1) :
                           task['priority'] == 'Medium' ? Colors.orange.withOpacity(0.1) :
                           Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    task['priority'],
                    style: TextStyle(
                      fontSize: 10,
                      color: task['priority'] == 'High' ? Colors.red :
                             task['priority'] == 'Medium' ? Colors.orange :
                             Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Due: ${task['dueDate'].day}/${task['dueDate'].month}/${task['dueDate'].year}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          setState(() {
            task['isCompleted'] = !task['isCompleted'];
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      drawer: AppDrawer(
        selectedIndex: 1,
        onItemSelected: (_) => Navigator.pop(context),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Lead Details', style: TextStyle(color: Colors.black)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) async {
              if (value == 'edit') {
                // Navigate to edit mode or show edit dialog
                _showEditDialog();
              } else if (value == 'personal') {
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
                if (!context.mounted) return;
                if (shouldDelete == true) {
                  _leadManager.deleteLead(widget.lead.id);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lead deleted successfully')),
                  );
                }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'personal',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 20),
                    SizedBox(width: 8),
                    Text('Personal Details'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Lead Header Section (attached to app bar)
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(widget.lead.contactName,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    if (widget.lead.phone != null)
                      IconButton(
                        icon: const Icon(Icons.phone, size: 24, color: Color(0xFF6B7280)),
                        onPressed: () => launchUrl(Uri.parse('tel:${widget.lead.phone}')),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.comment,
                        size: 24,
                        color: Color(0xFF6B7280),
                      ),
                      onPressed: widget.lead.phone != null
                          ? () => launchUrl(Uri.parse('sms:${widget.lead.phone}'))
                          : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    if (widget.lead.email != null)
                      IconButton(
                        icon: const Icon(Icons.email, size: 24, color: Color(0xFF6B7280)),
                        onPressed: () => launchUrl(Uri.parse('mailto:${widget.lead.email}')),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                if (widget.lead.service != null)
                  Row(
                    children: [
                      const SizedBox(width: 24),
                Expanded(
                  child: Text(
                    widget.lead.service!,
                    style: const TextStyle(
                      fontSize: 14, 
                      color: Colors.black87
                    ),
                  ),
                ),
                    ],
                  ),
                if (widget.lead.followUpDate != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const SizedBox(width: 24),
                Expanded(
                  child: Text(
                    'Follow-up: ${widget.lead.followUpDate!.day}/${widget.lead.followUpDate!.month}/${widget.lead.followUpDate!.year} ${widget.lead.followUpTime ?? "10:00 AM"}',
                    style: const TextStyle(
                      fontSize: 14, 
                      color: Colors.black87
                    ),
                  ),
                ),
                    ],
                  ),
                ],
                if (widget.lead.notes != null && widget.lead.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const SizedBox(width: 24),
                Expanded(
                  child: Text(
                    widget.lead.notes!,
                    style: const TextStyle(
                      fontSize: 13, 
                      color: Colors.grey
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                    ],
                  ),
                ],
                if (widget.lead.tags != null && widget.lead.tags!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 24),
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: widget.lead.tags!.split(',').map((tag) {
                            final trimmedTag = tag.trim();
                            if (trimmedTag.isEmpty) return const SizedBox.shrink();
                            
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                trimmedTag,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Gap before tabs
          const SizedBox(height: 8),
          // Tab Bar with border radius
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey, width: 0.2)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF0b5cff),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF0b5cff),
              tabs: const [
                Tab(text: 'Activity'),
                Tab(text: 'Notes'),
                Tab(text: 'Tasks'),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.white,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Activity Tab
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _activities.length,
                          itemBuilder: (context, index) => _buildActivityItem(_activities[index]),
                        ),
                  // Notes Tab
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _notes.isEmpty
                          ? const Center(child: Text('No notes available'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: _notes.length,
                              itemBuilder: (context, index) => _buildNoteItem(_notes[index]),
                            ),
                  // Tasks Tab
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _tasks.isEmpty
                          ? const Center(child: Text('No tasks available'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: _tasks.length,
                              itemBuilder: (context, index) => _buildTaskItem(_tasks[index]),
                            ),
                ],
              ),
            ),
            ),
          ],
        ),
      ),
      floatingActionButton: null,
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
                onPressed: widget.lead.phone != null
                    ? () => launchUrl(Uri.parse('sms:${widget.lead.phone}'))
                    : widget.lead.email != null
                        ? () => launchUrl(Uri.parse('mailto:${widget.lead.email}'))
                        : null,
                icon: const Icon(Icons.message, color: Colors.grey, size: 18),
                label: const Text('Send Message', style: TextStyle(color: Colors.grey, fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: widget.lead.phone != null
                    ? () => launchUrl(Uri.parse('tel:${widget.lead.phone}'))
                    : null,
                icon: const Icon(Icons.phone, color: Colors.white, size: 18),
                label: const Text('Make a Call', style: TextStyle(color: Colors.white, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0b5cff),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF0b5cff),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
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
                            title: const Text('Add Activity'),
                            onTap: () {
                              Navigator.pop(context);
                              _showAddActivityDialog();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.task),
                            title: const Text('Create Task'),
                            onTap: () {
                              Navigator.pop(context);
                              _showAddTaskDialog();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.note),
                            title: const Text('Add Note'),
                            onTap: () {
                              Navigator.pop(context);
                              _showAddNoteDialog();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add, color: Colors.white, size: 24),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}