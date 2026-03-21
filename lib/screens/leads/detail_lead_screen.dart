// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:hugeicons/hugeicons.dart';
import '../../models/lead.dart';
import '../../managers/lead_manager.dart';
import '../../managers/auth_manager.dart';
import '../../managers/task_manager.dart';
import '../../services/lead_activity_api.dart';
import '../../widgets/app_drawer.dart';
import '../main_screen.dart';
import '../../services/notification_service.dart';

class DetailLeadScreen extends StatefulWidget {
  final Lead lead;
  final bool startInEditMode;
  final int initialTabIndex;

  const DetailLeadScreen({
    super.key,
    required this.lead,
    this.startInEditMode = false,
    this.initialTabIndex = 0,
  });

  @override
  State<DetailLeadScreen> createState() => _DetailLeadScreenState();
}

class _DetailLeadScreenState extends State<DetailLeadScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  final _leadManager = LeadManager();
  final _notificationService = NotificationService();

  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update floating action button
    });
    _loadData();
    
    // Initialize notification service if not already initialized
    _initializeNotificationService();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Save data when app goes to background or is paused
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _saveAllDataToStorage().catchError((e) {
        debugPrint('Error saving data on lifecycle change: $e');
      });
    }
  }
  
  Future<void> _initializeNotificationService() async {
    try {
      if (!_notificationService.isInitialized) {
        await _notificationService.initialize();
        debugPrint('✅ NotificationService initialized in detail screen');
      }
      
      // Force immediate notification check for this lead's data
      await _updateNotificationMonitoring();
    } catch (e) {
      debugPrint('❌ Failed to initialize notification service in detail screen: $e');
    }
  }

  @override
  void dispose() {
    // Remove observer and dispose resources
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userId = await AuthManager().getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Load activities from database - show ALL activities for this lead
      final activitiesData = await LeadActivityApi.getActivities(widget.lead.id);
      _activities = activitiesData
          .map((activity) => {
        'id': activity['id'],
        'title': activity['activity_type'] ?? 'Activity',
        'description': _fixActivityDescription(activity['activity_type'] ?? 'Activity', activity['description'] ?? ''),
        'date': DateTime.parse(activity['created_at'] ?? DateTime.now().toIso8601String()),
        'icon': _getActivityIcon(activity['activity_type'] ?? 'Activity'),
        'user_id': activity['user_id'],
        'user_name': activity['user_name'] ?? 'Unknown User',
      }).toList();

      // Add default lead created activity if no activities exist
      if (_activities.isEmpty) {
        _activities.add({
          'id': null,
          'title': 'Lead Created',
          'description': 'Lead was created in the system',
          'date': widget.lead.createdAt,
          'icon': Icons.person_add,
          'user_id': userId,
        });
      }

      // Add follow-up activity if exists - but only if not already in database
      if (widget.lead.followUpDate != null) {
        // Check if follow-up activity already exists in database
        final hasFollowUpActivity = _activities.any((activity) => 
          activity['title'] == 'Follow-up Scheduled' || 
          activity['activity_type'] == 'Follow-up Scheduled'
        );
        
        if (!hasFollowUpActivity) {
          String followUpTimeString = widget.lead.followUpTime ?? '10:00 AM';
          
          _activities.add({
            'id': null,
            'title': 'Follow-up Scheduled',
            'description': 'Follow-up scheduled at $followUpTimeString',
            'date': widget.lead.followUpDate!,
            'icon': Icons.schedule,
            'user_id': userId,
          });
        }
      }

      // Load notes from database - show ALL notes for this lead
      final notesData = await LeadActivityApi.getNotes(widget.lead.id);
      _notes = notesData
          .map((note) => {
        'id': note['id'],
        'content': note['content'] ?? '',
        'date': DateTime.parse(note['created_at'] ?? DateTime.now().toIso8601String()),
        'user_id': note['user_id'],
        'user_name': note['user_name'] ?? 'Unknown User',
      }).toList();

      // Add default note if exists and no notes in database
      if (_notes.isEmpty && widget.lead.notes != null && widget.lead.notes!.isNotEmpty) {
        print('Adding default note from lead: ${widget.lead.notes}'); // Debug print
        final currentUser = await AuthManager().getUsername() ?? 'System';
        _notes.add({
          'id': null,
          'content': widget.lead.notes!,
          'date': widget.lead.createdAt,
          'user_id': userId,
          'user_name': currentUser,
        });
      }

      // Load tasks from database ONLY - show ALL tasks for this lead
      final tasksData = await LeadActivityApi.getTasks(widget.lead.id);
      _tasks = tasksData
          .map((task) => {
        'id': task['id'],
        'title': (task['title'] ?? '').toString().trim(),
        'description': (task['description'] ?? '').toString().trim(),
        'priority': (task['priority'] ?? 'Medium').toString().trim(),
        'dueDate': DateTime.parse(task['due_date'] ?? DateTime.now().add(const Duration(days: 1)).toIso8601String()),
        'dueTime': (task['due_time'] ?? '12:00 PM').toString().trim(),
        'isCompleted': (task['is_completed'] ?? 0) == 1,
        'user_id': task['user_id'],
        'user_name': task['user_name'] ?? task['username'] ?? 'Unknown User',
      }).toList();
      
      debugPrint('📋 Loaded ${_tasks.length} tasks from database for lead: ${widget.lead.contactName}');
      
      // Load local data for activities and notes only (not tasks)
      await _loadLocalData();
    } catch (e) {
      print('Error loading data: $e');
      // Fallback to default data
      final userId = await AuthManager().getUserId() ?? 0;
      _activities = [
        {
          'id': null,
          'title': 'Lead Created',
          'description': 'Lead was created in the system',
          'date': widget.lead.createdAt,
          'icon': Icons.person_add,
          'user_id': userId,
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
        title: const Row(
          children: [
            SizedBox(width: 32), // Space equivalent to back button
            Expanded(
              child: Text(
                'Lead Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(width: 32), // Balance the spacing
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
                  children: [
                    'Called',
                    'SMS Sent',
                    'Email Sent',
                    'Lead Lost',
                    'Lead Converted'
                  ]
                      .map((activity) => ListTile(
                            title: Text(activity,
                                style: const TextStyle(fontSize: 14)),
                            onTap: () {
                              if (activity == 'Called') {
                                Navigator.pop(context);
                                _showCallOutcomeDialog(remarksController);
                              } else {
                                Navigator.pop(context);
                                _showActivityDetailsDialog(
                                    activity, remarksController);
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

  void _showActivityDetailsDialog(
      String activity, TextEditingController remarksController) {
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
                icon:
                    const Icon(Icons.arrow_back, size: 20, color: Colors.black),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Expanded(
                child: Text(
                  activity,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
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
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87),
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
                            const Icon(Icons.calendar_today,
                                size: 20, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Time Field
                    const Text(
                      'Time',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87),
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
                            const Icon(Icons.access_time,
                                size: 20, color: Colors.grey),
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
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedLostReason,
                      hint: const Text('Select reason',
                          style: TextStyle(fontSize: 14)),
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
                      ]
                          .map((reason) => DropdownMenuItem(
                              value: reason,
                              child: Text(reason,
                                  overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (value) =>
                          setDialogState(() => selectedLostReason = value),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Deal Amount field for Lead Converted
                  if (activity == 'Lead Converted') ...[
                    const Text(
                      'Deal Amount',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87),
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
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: activity == 'Lead Lost'
                        ? 80
                        : activity == 'Lead Converted'
                            ? 80
                            : (activity == 'SMS Sent' ||
                                    activity == 'Email Sent')
                                ? 60
                                : 120,
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
              onPressed: () async {
                bool isValid = remarksController.text.isNotEmpty;
                if (activity == 'Lead Lost') {
                  isValid = isValid && selectedLostReason != null;
                }

                if (isValid) {
                  String description = remarksController.text;

                  if ((activity == 'SMS Sent' || activity == 'Email Sent') &&
                      selectedDate != null &&
                      selectedTime != null) {
                    description +=
                        '\nSent on: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year} at ${selectedTime!.format(dialogContext)}';
                  }

                  if (activity == 'Lead Lost' && selectedLostReason != null) {
                    description += '\nReason: $selectedLostReason';
                  }

                  if (activity == 'Lead Converted' &&
                      dealAmountController.text.isNotEmpty) {
                    description +=
                        '\nDeal Amount: ₹${dealAmountController.text}';
                  }

                  // Save to database immediately and automatically
                  final userId = await AuthManager().getUserId() ?? 0;
                  DateTime? scheduledDateTime;
                  
                  // Create scheduled datetime if date and time are provided
                  if ((activity == 'SMS Sent' || activity == 'Email Sent') &&
                      selectedDate != null && selectedTime != null) {
                    scheduledDateTime = DateTime(
                      selectedDate!.year,
                      selectedDate!.month,
                      selectedDate!.day,
                      selectedTime!.hour,
                      selectedTime!.minute,
                    );
                  }

                  final activityData = {
                    'id': null, // Will be assigned by database
                    'title': activity,
                    'description': description,
                    'date': DateTime.now(),
                    'icon': _getActivityIcon(activity),
                    'user_id': await AuthManager().getUserId(),
                  };
                  
                  // Add scheduled date if this is a scheduled activity
                  if (scheduledDateTime != null) {
                    activityData['scheduledDate'] = scheduledDateTime;
                  }
                  
                  try {
                    await LeadActivityApi.saveActivity(
                      leadId: widget.lead.id,
                      activityType: activity,
                      description: description,
                      userId: userId,
                      scheduledAt: scheduledDateTime,
                    );
                    
                    // Update activity with database confirmation
                    activityData['id'] = DateTime.now().millisecondsSinceEpoch;
                  } catch (e) {
                    print('Database save failed: $e');
                    // Continue silently with local storage as backup
                  }
                  
                  // Add to UI immediately
                  setState(() {
                    _activities.insert(0, activityData);
                  });
                  
                  // Save to local storage as backup
                  await _saveActivitiesToStorage();
                  
                  // Update notification monitoring with new activity data
                  await _updateNotificationMonitoring();
                  
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                        content: Text('Activity added successfully')),
                  );
                } else {
                  String errorMessage = 'Please enter remarks';
                  if (activity == 'Lead Lost' && selectedLostReason == null) {
                    errorMessage =
                        'Please select a lost reason and enter remarks';
                  }
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text(errorMessage)),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0b5cff),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
            const Expanded(
              child: Text(
                'Call Outcome',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  ]
                      .map((outcome) => ListTile(
                            title: Text(outcome,
                                style: const TextStyle(fontSize: 14)),
                            onTap: () {
                              Navigator.pop(context);
                              _showOutcomeDetailsDialog(
                                  outcome, remarksController);
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

  void _showOutcomeDetailsDialog(
      String outcome, TextEditingController remarksController) {
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
                icon:
                    const Icon(Icons.arrow_back, size: 20, color: Colors.black),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Expanded(
                child: Text(
                  outcome,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
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
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87),
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
                        const Icon(Icons.calendar_today,
                            size: 20, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Time Field
                const Text(
                  'Time',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87),
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
                        const Icon(Icons.access_time,
                            size: 20, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Remarks Section
                const Text(
                  'Remark *',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87),
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
              onPressed: () async {
                if (remarksController.text.isNotEmpty) {
                  try {
                    String activityTitle = 'Called - $outcome';
                    String description = remarksController.text;

                    if (selectedDate != null && selectedTime != null) {
                      description +=
                          '\n${_getDateTimeLabel(outcome)}: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year} at ${selectedTime!.format(dialogContext)}';
                    }

                    // Save to database immediately and automatically
                    final userId = await AuthManager().getUserId() ?? 0;
                    DateTime? scheduledDateTime;
                    
                    // Create scheduled datetime if date and time are provided
                    if (selectedDate != null && selectedTime != null) {
                      scheduledDateTime = DateTime(
                        selectedDate!.year,
                        selectedDate!.month,
                        selectedDate!.day,
                        selectedTime!.hour,
                        selectedTime!.minute,
                      );
                    }

                    // Create activity data
                    final callActivityData = {
                      'id': null, // Will be assigned by database
                      'title': activityTitle,
                      'description': description,
                      'date': DateTime.now(),
                      'icon': Icons.phone,
                      'user_id': await AuthManager().getUserId(),
                    };
                    
                    // Add scheduled date if this is a scheduled call activity
                    if (scheduledDateTime != null) {
                      callActivityData['scheduledDate'] = scheduledDateTime;
                    }
                    
                    try {
                      await LeadActivityApi.saveActivity(
                        leadId: widget.lead.id,
                        activityType: activityTitle,
                        description: description,
                        userId: userId,
                        scheduledAt: scheduledDateTime,
                      );
                      
                      // Update activity with database confirmation
                      callActivityData['id'] = DateTime.now().millisecondsSinceEpoch;
                    } catch (e) {
                      print('Database save failed: $e');
                      // Continue silently with local storage as backup
                    }
                    
                    // Add to UI immediately
                    setState(() {
                      _activities.insert(0, callActivityData);
                    });
                    
                    // Save to local storage as backup
                    await _saveActivitiesToStorage();
                    
                    // Update notification monitoring with new activity data
                    await _updateNotificationMonitoring();
                    
                    if (!mounted) return;
                    Navigator.pop(dialogContext);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Call activity added successfully')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error saving activity: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter remarks')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0b5cff),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

  IconData _getIconFromCodePoint(int codePoint) {
    // Map common icon code points to their IconData
    switch (codePoint) {
      case 0xe0b0: // Icons.phone
        return Icons.phone;
      case 0xe0be: // Icons.sms
        return Icons.sms;
      case 0xe0be: // Icons.email
        return Icons.email;
      case 0xe5c9: // Icons.cancel
        return Icons.cancel;
      case 0xe5ca: // Icons.check_circle
        return Icons.check_circle;
      case 0xe878: // Icons.person_add
        return Icons.person_add;
      case 0xe8b5: // Icons.schedule
        return Icons.schedule;
      case 0xe878: // Icons.event
        return Icons.event;
      default:
        return Icons.event; // Default fallback icon
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
              IconButton(
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const Expanded(
                child: Text(
                  'Create Task',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 32),
            ],
          ),
          content: SizedBox(
            width: 320,
            height: 320,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Task Title *',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 40,
                    child: TextField(
                      controller: titleController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF0b5cff)),
                        ),
                        hintText: 'Enter task title...',
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Priority',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 40,
                    child: DropdownButtonFormField<String>(
                      initialValue: priority,
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF0b5cff)),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: ['Low', 'Medium', 'High']
                          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (value) =>
                          setDialogState(() => priority = value!),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Due Date',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 40,
                              child: GestureDetector(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: dialogContext,
                                    initialDate: selectedDate ??
                                        DateTime.now()
                                            .add(const Duration(days: 1)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2100),
                                  );
                                  if (date != null) {
                                    setDialogState(() => selectedDate = date);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade300),
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
                                      const Icon(Icons.calendar_today,
                                          size: 16, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Due Time',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 40,
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          selectedTime != null
                                              ? selectedTime!
                                                  .format(dialogContext)
                                              : 'Select time',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      const Icon(Icons.access_time,
                                          size: 16, color: Colors.grey),
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
                  const SizedBox(height: 12),
                  const Text(
                    'Description',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 80,
                    child: TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF0b5cff)),
                        ),
                        hintText: 'Enter description...',
                        contentPadding: const EdgeInsets.all(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(fontSize: 14)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  try {
                    DateTime dueDate = selectedDate ??
                        DateTime.now().add(const Duration(days: 1));
                    if (selectedTime != null) {
                      dueDate = DateTime(
                        dueDate.year,
                        dueDate.month,
                        dueDate.day,
                        selectedTime!.hour,
                        selectedTime!.minute,
                      );
                    }

                    // Check for duplicates before creating the task
                    final isDuplicate = _tasks.any((t) => 
                      t['title']?.toString().trim() == titleController.text.trim() && 
                      t['description']?.toString().trim() == descriptionController.text.trim() &&
                      t['dueDate']?.toString() == dueDate.toString() &&
                      t['dueTime']?.toString().trim() == (selectedTime?.format(dialogContext) ?? '12:00 PM').trim() &&
                      t['priority']?.toString().trim() == priority.trim()
                    );
                    
                    if (isDuplicate) {
                      debugPrint('❌ Duplicate task not created: ${titleController.text}');
                      if (!mounted) return;
                      Navigator.pop(dialogContext);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Task already exists')),
                      );
                      return;
                    }

                    final newTask = {
                      'id': DateTime.now().millisecondsSinceEpoch, // Generate local ID
                      'title': titleController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'priority': priority.trim(),
                      'dueDate': dueDate,
                      'dueTime': (selectedTime?.format(dialogContext) ?? '12:00 PM').trim(),
                      'isCompleted': false,
                      'user_id': await AuthManager().getUserId(),
                    };

                    // Save to database first
                    final userId = await AuthManager().getUserId() ?? 0;
                    try {
                      await LeadActivityApi.saveTask(
                        leadId: widget.lead.id,
                        title: titleController.text,
                        description: descriptionController.text,
                        priority: priority,
                        dueDate: dueDate,
                        userId: userId,
                        dueTime: selectedTime?.format(dialogContext) ?? '12:00 PM',
                      );
                      debugPrint('✅ Task saved to database: ${titleController.text}');
                    } catch (e) {
                      debugPrint('❌ Database save failed: $e');
                    }
                    
                    // Reload tasks from database to get the latest data
                    await _loadData();
                    debugPrint('✅ Task created and data reloaded: ${titleController.text}');
                    
                    // Update notification monitoring with new task data
                    await _updateNotificationMonitoring();
                    
                    if (!mounted) return;
                    Navigator.pop(dialogContext);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Task created successfully')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error creating task: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter task title')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0b5cff),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
              IconButton(
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const Expanded(
                child: Text(
                  'Add Notes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 32),
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
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.white,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Text Style Dropdown
                        SizedBox(
                          width: 90,
                          child: DropdownButton<String>(
                            value: textStyle,
                            underline: const SizedBox(),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.black),
                            isExpanded: true,
                            items: ['Normal', 'H1', 'H2', 'H3']
                                .map((style) => DropdownMenuItem(
                                      value: style == 'H1'
                                          ? 'Heading 1'
                                          : style == 'H2'
                                              ? 'Heading 2'
                                              : style == 'H3'
                                                  ? 'Heading 3'
                                                  : style,
                                      child: Text(style,
                                          style: const TextStyle(fontSize: 11)),
                                    ))
                                .toList(),
                            onChanged: (value) =>
                                setDialogState(() => textStyle = value!),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isBold
                                  ? const Color(0xFF0b5cff)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'B',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Italic Button
                        GestureDetector(
                          onTap: () =>
                              setDialogState(() => isItalic = !isItalic),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isItalic
                                  ? const Color(0xFF0b5cff)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'I',
                              style: TextStyle(
                                  fontStyle: FontStyle.italic, fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Underline Button
                        GestureDetector(
                          onTap: () =>
                              setDialogState(() => isUnderline = !isUnderline),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isUnderline
                                  ? const Color(0xFF0b5cff)
                                  : Colors.transparent,
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
                            child: const Icon(Icons.format_list_bulleted,
                                size: 14),
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
                            child: const Icon(Icons.format_list_numbered,
                                size: 14),
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
                      fontSize: textStyle == 'Heading 1'
                          ? 18
                          : textStyle == 'Heading 2'
                              ? 16
                              : textStyle == 'Heading 3'
                                  ? 15
                                  : 14,
                      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                      decoration: isUnderline
                          ? TextDecoration.underline
                          : TextDecoration.none,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF0b5cff)),
                      ),
                      hintText: 'Add your notes here...',
                      contentPadding: const EdgeInsets.all(12),
                      filled: true,
                      fillColor: Colors.white,
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
              onPressed: () async {
                if (noteController.text.isNotEmpty) {
                  try {
                    final userId = await AuthManager().getUserId() ?? 0;
                    final userName = await AuthManager().getUsername() ?? 'Current User';
                    
                    final newNote = {
                      'id': null, // Will be assigned by database
                      'content': noteController.text,
                      'date': DateTime.now(),
                      'user_id': userId,
                      'user_name': userName,
                    };

                    // Save to database immediately and automatically
                    try {
                      await LeadActivityApi.saveNote(
                        leadId: widget.lead.id,
                        content: noteController.text,
                        userId: userId,
                      );
                      
                      // Update note with database confirmation
                      newNote['id'] = DateTime.now().millisecondsSinceEpoch;
                    } catch (e) {
                      print('Database save failed: $e');
                      // Continue silently with local storage as backup
                    }
                    
                    // Add to UI immediately
                    setState(() {
                      _notes.add(newNote);
                    });
                    
                    // Save to local storage as backup
                    await _saveNotesToStorage();
                    
                    // Update notification monitoring with new note data
                    await _updateNotificationMonitoring();
                    
                    if (!mounted) return;
                    Navigator.pop(dialogContext);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Note added successfully')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error saving note: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0b5cff),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
        newText =
            '${text.substring(0, lineStart)}• ${text.substring(cursorPosition)}';
        newCursorPosition = lineStart + 2;
      } else {
        // Insert bullet on new line
        newText =
            '${text.substring(0, cursorPosition)}\n• ${text.substring(cursorPosition)}';
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
        newText =
            '${text.substring(0, lineStart)}$nextNumber. ${text.substring(cursorPosition)}';
        newCursorPosition = lineStart + '$nextNumber. '.length;
      } else {
        // Insert numbered point on new line
        newText =
            '${text.substring(0, cursorPosition)}\n$nextNumber. ${text.substring(cursorPosition)}';
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
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
                    if (widget.lead.address != null &&
                        widget.lead.address!.isNotEmpty)
                      _buildPersonalDetailItem(
                        Icons.location_on_outlined,
                        widget.lead.address!,
                      ),
                    // Email
                    if (widget.lead.email != null &&
                        widget.lead.email!.isNotEmpty)
                      _buildPersonalDetailItem(
                        Icons.email_outlined,
                        widget.lead.email!,
                      ),
                    // Phone (if different from header or additional numbers)
                    if (widget.lead.phone != null &&
                        widget.lead.phone!.isNotEmpty)
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
                    if (widget.lead.service != null &&
                        widget.lead.service!.isNotEmpty)
                      _buildPersonalDetailItem(
                        Icons.work_outline,
                        widget.lead.service!,
                      ),
                    // Tags
                    if (widget.lead.tags != null &&
                        widget.lead.tags!.isNotEmpty)
                      _buildPersonalDetailItem(
                        Icons.label_outline,
                        widget.lead.tags!,
                      ),
                    // Notes
                    if (widget.lead.notes != null &&
                        widget.lead.notes!.isNotEmpty)
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

  String _fixActivityDescription(String activityType, String description) {
    // Fix old follow-up descriptions that contain dates instead of times
    if (activityType == 'Follow-up Scheduled' && description.contains('scheduled for')) {
      final followUpTime = widget.lead.followUpTime ?? '10:00 AM';
      return 'Follow-up scheduled at $followUpTime';
    }
    // Also fix descriptions that still show dates - replace with time
    if (activityType == 'Follow-up Scheduled' && description.contains('18/3/2026')) {
      final followUpTime = widget.lead.followUpTime ?? '10:00 AM';
      return 'Follow-up scheduled at $followUpTime';
    }
    return description;
  }

  String _formatTime(DateTime dateTime) {
    int hour = dateTime.hour;
    int minute = dateTime.minute;
    String period = 'AM';
    
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour = hour - 12;
      period = 'PM';
    } else if (hour == 12) {
      period = 'PM';
    }
    
    return '${hour.toString()}:${minute.toString().padLeft(2, '0')} $period';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTaskDueDateTime(DateTime dueDate) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    // Format date
    String dateStr = '${dueDate.day} ${months[dueDate.month - 1]} ${dueDate.year}';
    
    // Format time
    String hour = dueDate.hour > 12 ? '${dueDate.hour - 12}' : dueDate.hour == 0 ? '12' : '${dueDate.hour}';
    String minute = dueDate.minute.toString().padLeft(2, '0');
    String period = dueDate.hour >= 12 ? 'PM' : 'AM';
    String timeStr = '$hour:$minute $period';
    
    return '$dateStr, $timeStr';
  }

  String _formatDateTime(dynamic date) {
    if (date == null) return 'No date';
    DateTime parsedDate = date is String ? DateTime.parse(date) : date;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    String hour = parsedDate.hour > 12 ? '${parsedDate.hour - 12}' : parsedDate.hour == 0 ? '12' : '${parsedDate.hour}';
    String minute = parsedDate.minute.toString().padLeft(2, '0');
    String period = parsedDate.hour >= 12 ? 'PM' : 'AM';
    return '${parsedDate.day} ${months[parsedDate.month - 1]} ${parsedDate.year}, $hour:$minute $period';
  }

  void _showEditDialog() {
    final nameController = TextEditingController(text: widget.lead.contactName);
    final emailController =
        TextEditingController(text: widget.lead.email ?? '');
    final phoneController =
        TextEditingController(text: widget.lead.phone ?? '');
    final notesController =
        TextEditingController(text: widget.lead.notes ?? '');
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

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF0b5cff).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(activity['icon'],
                      color: const Color(0xFF0b5cff), size: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            activity['title'],
                            style: const TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${activity['date'].day}/${activity['date'].month}/${activity['date'].year}',
                          style: const TextStyle(
                            fontSize: 12, 
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity['description'],
                      style: const TextStyle(
                        fontSize: 14, 
                        color: Colors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (activity['user_name'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Added by: ${activity['user_name']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: Colors.grey.shade200,
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildNoteItem(Map<String, dynamic> note) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and user info at the top
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    note['date'] != null 
                      ? _formatDateTime(note['date'])
                      : 'No date',
                    style: const TextStyle(
                      fontSize: 14, 
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Notes Added',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Action row
              Row(
                children: [
                  const SizedBox(
                    width: 60,
                    child: Text(
                      'Action',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Notes Added',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Notes row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 60,
                    child: Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      note['content'] ?? 'No content',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              // User info row
              if (note['user_name'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(
                      width: 60,
                      child: Text(
                        'Added by',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      note['user_name'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: Colors.grey.shade200,
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Future<void> _saveAllDataToStorage() async {
    try {
      // Save to database first
      await _saveAllDataToDatabase();
      
      // Then save to local storage as backup
      await _saveActivitiesToStorage();
      await _saveTasksToStorage();
      await _saveNotesToStorage();
      print('All data saved to database and storage successfully');
    } catch (e) {
      print('Error saving all data: $e');
    }
  }

  Future<void> _saveAllDataToDatabase() async {
    try {
      final userId = await AuthManager().getUserId() ?? 0;
      
      // Save all activities to database
      for (final activity in _activities) {
        if (activity['id'] == null) { // Only save new activities
          try {
            await LeadActivityApi.saveActivity(
              leadId: widget.lead.id,
              activityType: activity['title'],
              description: activity['description'],
              userId: userId,
            );
          } catch (e) {
            print('Failed to save activity to database: $e');
          }
        }
      }
      
      // Save all notes to database
      for (final note in _notes) {
        if (note['id'] == null) { // Only save new notes
          try {
            await LeadActivityApi.saveNote(
              leadId: widget.lead.id,
              content: note['content'],
              userId: userId,
            );
          } catch (e) {
            print('Failed to save note to database: $e');
          }
        }
      }
      
      // Save all tasks to database
      for (final task in _tasks) {
        if (task['id'] == null || task['id'] is! int) { // Only save new tasks
          try {
            await LeadActivityApi.saveTask(
              leadId: widget.lead.id,
              title: task['title'],
              description: task['description'],
              priority: task['priority'],
              dueDate: task['dueDate'],
              userId: userId,
            );
          } catch (e) {
            print('Failed to save task to database: $e');
          }
        }
      }
      
      print('All data saved to database successfully');
    } catch (e) {
      print('Error saving data to database: $e');
    }
  }

  Future<void> _saveActivitiesToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await AuthManager().getUserId();
      final activitiesJson = _activities.map((activity) => {
        'id': activity['id'],
        'title': activity['title'],
        'description': activity['description'],
        'date': activity['date'].toIso8601String(),
        'icon': activity['icon'].codePoint,
        'user_id': activity['user_id'] ?? userId,
      }).toList();
      await prefs.setString('lead_${widget.lead.id}_activities', json.encode(activitiesJson));
    } catch (e) {
      print('Error saving activities: $e');
    }
  }

  Future<void> _saveTasksToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await AuthManager().getUserId();
      final tasksJson = _tasks.map((task) => {
        'id': task['id'],
        'title': task['title'],
        'description': task['description'],
        'priority': task['priority'],
        'dueDate': task['dueDate'].toIso8601String(),
        'dueTime': task['dueTime'] ?? '12:00 PM',
        'isCompleted': task['isCompleted'],
        'user_id': task['user_id'] ?? userId,
      }).toList();
      await prefs.setString('lead_${widget.lead.id}_tasks', json.encode(tasksJson));
    } catch (e) {
      print('Error saving tasks: $e');
    }
  }

  Future<void> _saveNotesToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await AuthManager().getUserId();
      final notesJson = _notes.map((note) => {
        'id': note['id'],
        'content': note['content'],
        'date': note['date'].toIso8601String(),
        'user_id': note['user_id'] ?? userId,
        'user_name': note['user_name'] ?? 'Unknown User',
      }).toList();
      await prefs.setString('lead_${widget.lead.id}_notes', json.encode(notesJson));
    } catch (e) {
      print('Error saving notes: $e');
    }
  }

  Future<void> _loadLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await AuthManager().getUserId();
      
      // Load local activities
      final activitiesString = prefs.getString('lead_${widget.lead.id}_activities');
      if (activitiesString != null) {
        final activitiesList = json.decode(activitiesString) as List;
        final localActivities = activitiesList.map((activity) => {
          'id': activity['id'],
          'title': activity['title'],
          'description': activity['description'],
          'date': DateTime.parse(activity['date']),
          'icon': _getIconFromCodePoint(activity['icon'] ?? 0xe878),
          'user_id': activity['user_id'] ?? userId,
        }).toList();
        
        // Merge with API activities (avoid duplicates)
        for (final localActivity in localActivities) {
          final exists = _activities.any((a) => 
            a['title'] == localActivity['title'] && 
            a['description'] == localActivity['description']
          );
          if (!exists) {
            // Fix old follow-up descriptions that contain dates
            if (localActivity['title'] == 'Follow-up Scheduled' && 
                localActivity['description'].toString().contains('scheduled for')) {
              // Extract time from follow-up date and update description
              final followUpTime = widget.lead.followUpTime ?? '10:00 AM';
              localActivity['description'] = 'Follow-up scheduled at $followUpTime';
            }
            _activities.add(localActivity);
          }
        }
      }
      
      // Skip loading local tasks - use database only
      
      // Load local notes
      final notesString = prefs.getString('lead_${widget.lead.id}_notes');
      if (notesString != null) {
        final notesList = json.decode(notesString) as List;
        final localNotes = notesList.map((note) => {
          'id': note['id'],
          'content': note['content'],
          'date': DateTime.parse(note['date']),
          'user_id': note['user_id'] ?? userId,
          'user_name': note['user_name'] ?? 'Unknown User',
        }).toList();
        
        // Merge with API notes (avoid duplicates)
        for (final localNote in localNotes) {
          final exists = _notes.any((n) => 
            n['content'] == localNote['content']
          );
          if (!exists) {
            _notes.add(localNote);
          }
        }
      }
      
      // Sort lists by date
      _activities.sort((a, b) => b['date'].compareTo(a['date']));
      _notes.sort((a, b) => b['date'].compareTo(a['date']));
      
    } catch (e) {
      print('Error loading local data: $e');
    }
  }

  void _clearTaskDuplicates() {
    final Map<String, Map<String, dynamic>> uniqueTasksMap = {};
    
    for (final task in _tasks) {
      // Create a more comprehensive key for duplicate detection
      final taskKey = '${task['title']?.toString().trim().toLowerCase()}_${task['description']?.toString().trim().toLowerCase()}_${task['dueDate']?.toString()}_${task['dueTime']?.toString().trim()}_${task['priority']?.toString().trim().toLowerCase()}';
      
      // Keep the first occurrence of each unique task
      if (!uniqueTasksMap.containsKey(taskKey)) {
        uniqueTasksMap[taskKey] = task;
      } else {
        debugPrint('🗑️ Removed duplicate task: ${task['title']}');
      }
    }
    
    final originalCount = _tasks.length;
    _tasks = uniqueTasksMap.values.toList();
    
    if (originalCount != _tasks.length) {
      debugPrint('📋 Aggressive deduplication: ${originalCount} → ${_tasks.length} tasks');
    }
  }

  void _removeDuplicateTasks() {
    final uniqueTasks = <Map<String, dynamic>>[];
    final seenTasks = <String>{};
    
    for (final task in _tasks) {
      // Create a comprehensive key for duplicate detection
      final taskKey = '${task['title']?.toString().trim()}_${task['description']?.toString().trim()}_${task['dueDate']?.toString()}_${task['dueTime']?.toString().trim()}_${task['priority']?.toString().trim()}';
      if (!seenTasks.contains(taskKey)) {
        seenTasks.add(taskKey);
        uniqueTasks.add(task);
      } else {
        debugPrint('🗑️ Removed duplicate task: ${task['title']}');
      }
    }
    
    final originalCount = _tasks.length;
    _tasks = uniqueTasks;
    
    if (originalCount != _tasks.length) {
      debugPrint('📋 Task deduplication: ${originalCount} → ${_tasks.length} tasks');
    }
  }

  Future<void> _updateNotificationMonitoring() async {
    if (!mounted) return;

    try {
      // Ensure the current lead is always included even if leadManager is stale
      final allLeads = _leadManager.allLeads;
      final leadsToCheck = allLeads.any((l) => l.id == widget.lead.id)
          ? allLeads
          : [...allLeads, widget.lead];

      final taskManager = TaskManager();
      await taskManager.loadTasks();
      if (!mounted) return;

      final globalTasks = [
        ...taskManager.pendingTasks,
        ...taskManager.completedTasks
      ].map((task) => {
            'id': task.id,
            'title': task.title,
            'description': task.description,
            'dueDate': task.dueDate,
            'dueTime': task.dueTime,
            'isCompleted': task.isCompleted,
            'priority': task.priority,
          }).toList();

      final allTasks = <Map<String, dynamic>>[...globalTasks];
      final allActivities = <Map<String, dynamic>>[];

      for (final lead in leadsToCheck) {
        if (!mounted) return;
        try {
          final leadTasks = await LeadActivityApi.getTasks(lead.id);
          for (final task in leadTasks) {
            allTasks.add({
              'id': task['id'],
              'title': task['title'] ?? '',
              'description': task['description'] ?? '',
              'dueDate': DateTime.parse(task['due_date'] ??
                  DateTime.now()
                      .add(const Duration(days: 1))
                      .toIso8601String()),
              'dueTime': task['due_time'] ?? '12:00 PM',
              'isCompleted': (task['is_completed'] ?? 0) == 1,
              'priority': task['priority'] ?? 'Medium',
              'leadId': lead.id,
            });
          }
        } catch (e) {
          debugPrint('Error loading tasks for lead ${lead.contactName}: $e');
        }

        if (!mounted) return;
        try {
          final activities = await LeadActivityApi.getActivities(lead.id);
          for (final activity in activities) {
            final scheduledAt = activity['scheduled_at'];
            if (scheduledAt != null &&
                scheduledAt.toString().isNotEmpty &&
                scheduledAt != 'null') {
              try {
                allActivities.add({
                  'id': activity['id'],
                  'title': activity['activity_type'] ?? 'Activity',
                  'description': activity['description'] ?? '',
                  'scheduledDate': DateTime.parse(scheduledAt),
                  'leadId': lead.id,
                });
              } catch (e) {
                debugPrint(
                    'Error parsing scheduled_at for activity: ${activity['activity_type']} - $e');
              }
            }
          }
        } catch (e) {
          debugPrint(
              'Error loading activities for lead ${lead.contactName}: $e');
        }
      }

      if (!mounted) return;

      _notificationService.startMonitoring(
        leadsToCheck,
        allTasks: allTasks,
        allActivities: allActivities,
      );
      _notificationService.updateCachedData(
        leads: leadsToCheck,
        tasks: allTasks,
        activities: allActivities,
      );

      debugPrint('🔄 Notification data updated from detail screen');
      debugPrint('   Total leads: ${leadsToCheck.length}');
      debugPrint('   Total tasks: ${allTasks.length}');
      debugPrint('   Total scheduled activities: ${allActivities.length}');
    } catch (e) {
      if (mounted) debugPrint('❌ Error updating notification monitoring: $e');
    }
  }

  Widget _buildTaskItem(Map<String, dynamic> task) {
    return Column(
      children: [
        ListTile(
          leading: Icon(
            task['isCompleted']
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: task['isCompleted'] ? Colors.green : Colors.grey,
          ),
          title: Text(
            task['title'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task['description'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: task['priority'] == 'High'
                          ? Colors.red.withValues(alpha: 0.1)
                          : task['priority'] == 'Medium'
                              ? Colors.orange.withValues(alpha: 0.1)
                              : Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      task['priority'],
                      style: TextStyle(
                        fontSize: 10,
                        color: task['priority'] == 'High'
                            ? Colors.red
                            : task['priority'] == 'Medium'
                                ? Colors.orange
                                : Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Due: ${_formatTaskDueDateTime(task['dueDate'])}',
                      style: const TextStyle(
                        fontSize: 12, 
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (task['user_name'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Created by: ${task['user_name']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
          onTap: () async {
            final oldStatus = task['isCompleted'];
            setState(() {
              task['isCompleted'] = !task['isCompleted'];
            });
            
            // Try to update in database immediately
            if (task['id'] != null && task['id'] is int) {
              try {
                await LeadActivityApi.updateTask(
                  taskId: task['id'],
                  isCompleted: task['isCompleted'],
                );
                print('Task status updated in database successfully');
              } catch (e) {
                print('Failed to update task in database: $e');
                // Revert the change if database update fails
                setState(() {
                  task['isCompleted'] = oldStatus;
                });
              }
            }
            
            // Save to local storage as backup
            await _saveTasksToStorage();
            
            // Update notification monitoring when task status changes
            await _updateNotificationMonitoring();
          },
        ),
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: Colors.grey.shade200,
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (didPop) {
          // Save data when user navigates back
          try {
            await _saveAllDataToStorage();
          } catch (e) {
            debugPrint('Error saving data on navigation: $e');
          }
        }
      },
      child: Scaffold(
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
          title:
              const Text('Lead Details', style: TextStyle(color: Colors.black)),
            actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.black),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onSelected: (value) async {
                if (value == 'edit') {
                  // Navigate to edit mode or show edit dialog
                  _showEditDialog();
                } else if (value == 'personal') {
                  _showPersonalDetails();
                } else if (value == 'mark_completed') {
                  final shouldMarkCompleted = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Mark as Completed'),
                      content: const Text(
                          'Are you sure you want to mark this lead as completed?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Mark as Completed',
                              style: TextStyle(color: Colors.green)),
                        ),
                      ],
                    ),
                  );
                  if (!context.mounted) return;
                  if (shouldMarkCompleted == true) {
                    try {
                      await _leadManager.markAsCompleted(widget.lead.id);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Lead marked as completed successfully')),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Failed to mark lead as completed: $e')),
                      );
                    }
                  }
                } else if (value == 'delete') {
                  final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Delete Lead'),
                      content: const Text(
                          'Are you sure you want to delete this lead?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Delete',
                              style: TextStyle(color: Colors.red)),
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
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedEdit02,
                        color: Colors.black,
                        size: 20.0,
                      ),
                      SizedBox(width: 12),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'personal',
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedUser,
                        color: Colors.black,
                        size: 20.0,
                      ),
                      SizedBox(width: 12),
                      Text('Personal Details'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'mark_completed',
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                        color: Colors.green,
                        size: 20.0,
                      ),
                      SizedBox(width: 12),
                      Text('Mark as Completed',
                          style: TextStyle(color: Colors.green)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedDelete02,
                        color: Colors.red,
                        size: 20.0,
                      ),
                      SizedBox(width: 12),
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
                  // Row 1: Name + action icons
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          widget.lead.contactName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.lead.phone != null)
                        GestureDetector(
                          onTap: () =>
                              launchUrl(Uri.parse('tel:${widget.lead.phone}')),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Icon(Icons.phone,
                                size: 18, color: Color(0xFF6B7280)),
                          ),
                        ),
                      const SizedBox(width: 8),
                      if (widget.lead.phone != null)
                        GestureDetector(
                          onTap: () =>
                              launchUrl(Uri.parse('sms:${widget.lead.phone}')),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Icon(Icons.comment,
                                size: 18, color: Color(0xFF6B7280)),
                          ),
                        ),
                      const SizedBox(width: 8),
                      if (widget.lead.email != null)
                        GestureDetector(
                          onTap: () => launchUrl(
                              Uri.parse('mailto:${widget.lead.email}')),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Icon(Icons.email,
                                size: 18, color: Color(0xFF6B7280)),
                          ),
                        ),
                    ],
                  ),
                  // Row 2: Service
                  if (widget.lead.service != null &&
                      widget.lead.service!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 22,
                          child: Icon(Icons.design_services,
                              size: 16, color: Colors.grey[600]),
                        ),
                        Expanded(
                          child: Text(
                            widget.lead.service!,
                            style: TextStyle(
                              fontSize: 14, 
                              color: Colors.grey[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Row 3: Notes
                  if (widget.lead.notes != null &&
                      widget.lead.notes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 22,
                          child: Icon(Icons.chat_bubble_outline,
                              size: 16, color: Colors.grey[400]),
                        ),
                        Expanded(
                          child: Text(
                            widget.lead.notes!,
                            style: TextStyle(
                              fontSize: 13, 
                              color: Colors.grey[500],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Tags
                  if (widget.lead.tags != null &&
                      widget.lead.tags!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: widget.lead.tags!.split(',').map((tag) {
                        final trimmedTag = tag.trim();
                        if (trimmedTag.isEmpty) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
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
                  ],
                  // Follow-up
                  if (widget.lead.followUpDate != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 22,
                          child: Icon(Icons.schedule,
                              size: 16, color: Colors.grey[600]),
                        ),
                        Expanded(
                          child: Text(
                            'Follow-up: ${widget.lead.followUpDate!.day}/${widget.lead.followUpDate!.month}/${widget.lead.followUpDate!.year} ${widget.lead.followUpTime ?? "10:00 AM"}',
                            style: TextStyle(
                              fontSize: 12, 
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                border:
                    Border(bottom: BorderSide(color: Colors.grey, width: 0.2)),
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
                            itemBuilder: (context, index) =>
                                _buildActivityItem(_activities[index]),
                          ),
                    // Notes Tab
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _notes.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.note_outlined, size: 64, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text('No notes available', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                itemCount: _notes.length,
                                itemBuilder: (context, index) {
                                  return _buildNoteItem(_notes[index]);
                                },
                              ),
                    // Tasks Tab
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _tasks.isEmpty
                            ? const Center(child: Text('No tasks available'))
                            : ListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount: _tasks.length,
                                itemBuilder: (context, index) =>
                                    _buildTaskItem(_tasks[index]),
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (widget.lead.phone != null) {
                      launchUrl(Uri.parse('sms:${widget.lead.phone}'));
                    }
                  },
                  icon: const Icon(Icons.message, size: 18),
                  label: const Text('Send Message'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF0B5CFF)),
                    foregroundColor: const Color(0xFF0B5CFF),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (widget.lead.phone != null) {
                      launchUrl(Uri.parse('tel:${widget.lead.phone}'));
                    }
                  },
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text('Make a Call'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: const Color(0xFF0B5CFF),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B5CFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () {
                    // Show menu based on current tab
                    switch (_tabController.index) {
                      case 0:
                        _showAddActivityDialog();
                        break;
                      case 1:
                        _showAddNoteDialog();
                        break;
                      case 2:
                        _showAddTaskDialog();
                        break;
                    }
                  },
                  icon: const Icon(Icons.add, color: Colors.white, size: 24),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget? _buildFloatingActionButton() {
    switch (_tabController.index) {
      case 0: // Activity tab
        return FloatingActionButton(
          onPressed: _showAddActivityDialog,
          backgroundColor: const Color(0xFF0B5CFF),
          child: const Icon(Icons.add, color: Colors.white),
        );
      case 1: // Notes tab
        return FloatingActionButton(
          onPressed: _showAddNoteDialog,
          backgroundColor: const Color(0xFF0B5CFF),
          child: const Icon(Icons.note_add, color: Colors.white),
        );
      case 2: // Tasks tab
        return FloatingActionButton(
          onPressed: _showAddTaskDialog,
          backgroundColor: const Color(0xFF0B5CFF),
          child: const Icon(Icons.task_alt, color: Colors.white),
        );
      default:
        return null;
    }
  }
}

class NewWidget extends StatelessWidget {
  const NewWidget({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
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
}
