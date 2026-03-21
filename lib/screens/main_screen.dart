import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../screens/dashboard_screen.dart';
import '../screens/leads/all_leads_screen.dart';
import '../screens/leads/add_new_lead_screen.dart';
import '../screens/leads/detail_lead_screen.dart';
import '../screens/appointments/appointments_screen.dart';
import '../screens/contacts/contacts_screen.dart';
import '../screens/contacts/add_contact_screen.dart';
import '../screens/tasks/pending_tasks_screen.dart';
import '../screens/auth/manage_profile_screen.dart';

import '../services/services_screen.dart';
import '../services/service_manager.dart';
import '../services/notification_service.dart';
import '../services/lead_activity_api.dart';
import '../screens/tags/tags_screen.dart';
import '../screens/tags/tag_api.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../widgets/app_drawer.dart';
import '../managers/lead_manager.dart';
import '../managers/task_manager.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  final int initialLeadTabIndex;

  const MainScreen({super.key, this.initialIndex = 0, this.initialLeadTabIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  late int _selectedIndex;
  final _serviceManager = ServiceManager();
  final _notificationService = NotificationService();
  int _tagsScreenVersion = 0;

  Widget? _buildFloatingActionButton() {
    switch (_selectedIndex) {
      case 1:
        return Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF0B5CFF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddNewLeadScreen(),
                ),
              ).then((result) {
                if (result == true && mounted) setState(() {});
              });
            },
            icon: const Icon(Icons.add, color: Colors.white, size: 24),
            padding: EdgeInsets.zero,
          ),
        );
      case 3:
        return FloatingActionButton(
          tooltip: 'Add New Contact',
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddContactScreen()),
            );
            if (result == true && mounted) setState(() {});
          },
          child: const Icon(Icons.add),
        );
      case 5:
        return FloatingActionButton(
          tooltip: 'Add Service',
          onPressed: () async {
            final result = await showDialog<String>(
              context: context,
              builder: (context) => const _AddServiceDialog(),
            );
            if (result != null && result.trim().isNotEmpty) {
              await _serviceManager.addService(result.trim());
              if (mounted) setState(() {});
            }
          },
          child: const Icon(Icons.add),
        );
      case 6:
        return FloatingActionButton(
          tooltip: 'Add Tag',
          onPressed: () async {
            final result = await showDialog<bool>(
              context: context,
              builder: (context) => const _AddTagDialog(),
            );
            if (result == true && mounted) {
              setState(() => _tagsScreenVersion++);
            }
          },
          child: const Icon(Icons.add),
        );
      default:
        return null;
    }
  }

  Widget _buildSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardScreen();
      case 1:
        return AllLeadsScreen(initialTabIndex: widget.initialLeadTabIndex);
      case 2:
        return const AppointmentsScreen();
      case 3:
        return const ContactsScreen();
      case 4:
        return const PendingTasksScreen();
      case 5:
        return const ServicesScreen();
      case 6:
        return TagsScreen(key: ValueKey(_tagsScreenVersion));
      default:
        return const DashboardScreen();
    }
  }

void _showNotificationStatus() {
    final leadManager = LeadManager();
    final upcomingLeads = leadManager.followUpLeads
        .where((lead) => !lead.isCompleted && lead.followUpDate != null)
        .take(5)
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications_active, color: Color(0xFF0B5CFF)),
            SizedBox(width: 8),
            Text('Notification Status'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '✅ Notification system is active',
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Text(
              'Upcoming Follow-ups (${upcomingLeads.length}):',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (upcomingLeads.isEmpty)
              const Text('No upcoming follow-ups', style: TextStyle(color: Colors.grey))
            else
              ...upcomingLeads.map((lead) {
                final followUpDate = lead.followUpDate!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${lead.contactName} - ${followUpDate.day}/${followUpDate.month}',
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await _notificationService.showTestNotification();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Test notification sent!'),
                  duration: Duration(seconds: 2),
                ),
              );

            },
            child: const Text('Test'),
          ),
          if (upcomingLeads.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => _selectedIndex = 1);
              },
              child: const Text('View Leads'),
            ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 1:
        return 'All Leads';
      case 2:
        return 'Appointments Schedule';
      case 4:
        return 'Pending Tasks';
      case 5:
        return 'All Services';
      case 6:
        return 'All Tags';
      default:
        return '';
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedIndex = widget.initialIndex;
    _startNotificationMonitoring();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App going to background — schedule exact alarms so they fire while app is closed
      _scheduleNotificationsForClosedApp();
    }
  }

  Future<void> _startNotificationMonitoring() async {
    final leadManager = LeadManager();
    final taskManager = TaskManager();
    await Future.wait([
      leadManager.loadLeads(),
      taskManager.loadTasks(),
    ]);

    debugPrint('🔄 Starting notification monitoring...');
    debugPrint('📊 Loaded ${leadManager.allLeads.length} leads');

    // Build global tasks
    final allTasks = <Map<String, dynamic>>[
      ...taskManager.pendingTasks.map((t) => {
        'id': t.id, 'title': t.title, 'description': t.description,
        'dueDate': t.dueDate, 'dueTime': t.dueTime,
        'isCompleted': t.isCompleted, 'priority': t.priority,
      }),
      ...taskManager.completedTasks.map((t) => {
        'id': t.id, 'title': t.title, 'description': t.description,
        'dueDate': t.dueDate, 'dueTime': t.dueTime,
        'isCompleted': t.isCompleted, 'priority': t.priority,
      }),
    ];

    // Load per-lead tasks and activities in parallel
    final allActivities = <Map<String, dynamic>>[];
    await Future.wait(
      leadManager.allLeads.map((lead) async {
        try {
          final leadTasks = await LeadActivityApi.getTasks(lead.id);
          for (final task in leadTasks) {
            allTasks.add({
              'id': task['id'],
              'title': task['title'] ?? '',
              'description': task['description'] ?? '',
              'dueDate': DateTime.parse(task['due_date'] ??
                  DateTime.now().add(const Duration(days: 1)).toIso8601String()),
              'dueTime': task['due_time'] ?? '12:00 PM',
              'isCompleted': (task['is_completed'] ?? 0) == 1,
              'priority': task['priority'] ?? 'Medium',
              'leadId': lead.id,
            });
          }
        } catch (e) {
          debugPrint('❌ Error loading tasks for lead ${lead.contactName}: $e');
        }
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
                debugPrint('❌ Error parsing scheduled_at: $e');
              }
            }
          }
        } catch (e) {
          debugPrint('❌ Error loading activities for lead ${lead.contactName}: $e');
        }
      }),
    );

    debugPrint('📋 Tasks: ${allTasks.length}, Activities: ${allActivities.length}');

    // Start monitoring only after ALL data is fully loaded
    _notificationService.startMonitoring(
      leadManager.allLeads,
      allTasks: allTasks,
      allActivities: allActivities,
    );

    _checkPendingNotification();
  }

  void _checkPendingNotification() {
    final pendingPayload = _notificationService.pendingPayload;
    if (pendingPayload != null) {
      _notificationService.clearPendingPayload();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (pendingPayload.startsWith('lead:')) {
          final leadId = pendingPayload.substring(5);
          _navigateToLead(leadId);
        } else if (pendingPayload.startsWith('task:')) {
          final parts = pendingPayload.split(':');
          if (parts.length >= 3) {
            _navigateToTaskInLead(parts[1], parts[2]);
          }
        } else if (pendingPayload.startsWith('activity:')) {
          final parts = pendingPayload.split(':');
          if (parts.length >= 3) {
            _navigateToActivityInLead(parts[1], parts[2]);
          }
        }
      });
    }
  }

  void _navigateToLead(String leadId) {
    final leadManager = LeadManager();
    try {
      final lead = leadManager.allLeads.firstWhere((lead) => lead.id == leadId);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailLeadScreen(lead: lead, startInEditMode: false, initialTabIndex: 0),
        ),
      );
    } catch (e) {
      debugPrint('Lead not found: $leadId');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AllLeadsScreen(initialTabIndex: 0)),
      );
    }
  }

  void _navigateToTaskInLead(String taskId, String leadId) {
    final leadManager = LeadManager();
    try {
      final lead = leadManager.allLeads.firstWhere((lead) => lead.id == leadId);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailLeadScreen(lead: lead, startInEditMode: false, initialTabIndex: 2),
        ),
      );
    } catch (e) {
      debugPrint('Lead not found for task: $leadId');
      setState(() => _selectedIndex = 4);
    }
  }

  void _navigateToActivityInLead(String activityId, String leadId) {
    final leadManager = LeadManager();
    try {
      final lead = leadManager.allLeads.firstWhere((lead) => lead.id == leadId);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailLeadScreen(lead: lead, startInEditMode: false, initialTabIndex: 0),
        ),
      );
    } catch (e) {
      debugPrint('Lead not found for activity: $leadId');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AllLeadsScreen(initialTabIndex: 0)),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scheduleNotificationsForClosedApp();
    _notificationService.dispose();
    super.dispose();
  }

  Future<void> _scheduleNotificationsForClosedApp() async {
    try {
      final leadManager = LeadManager();
      final taskManager = TaskManager();

      final allTasks = [...taskManager.pendingTasks, ...taskManager.completedTasks].map((task) => {
        'id': task.id,
        'title': task.title,
        'description': task.description,
        'dueDate': task.dueDate,
        'dueTime': task.dueTime,
        'isCompleted': task.isCompleted,
        'priority': task.priority,
      }).toList();

      final allActivities = <Map<String, dynamic>>[];
      for (final lead in leadManager.allLeads) {
        try {
          final activities = await LeadActivityApi.getActivities(lead.id);
          for (final activity in activities) {
            if (activity['scheduled_at'] != null && activity['scheduled_at'].toString().isNotEmpty) {
              allActivities.add({
                'id': activity['id'],
                'title': activity['activity_type'] ?? 'Activity',
                'description': activity['description'] ?? '',
                'scheduledDate': DateTime.parse(activity['scheduled_at']),
                'leadId': lead.id,
              });
            }
          }
        } catch (e) {
          debugPrint('Error loading activities for scheduling: $e');
        }
      }

      await _notificationService.scheduleNotificationsForClosedApp(
        leadManager.allLeads,
        allTasks: allTasks,
        allActivities: allActivities,
      );
    } catch (e) {
      debugPrint('Error scheduling notifications for closed app: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          setState(() => _selectedIndex = index);
          Navigator.pop(context);
        },
      ),
      appBar: AppBar(
        toolbarHeight: 56,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: _selectedIndex == 0
            ? Image.asset(
                'assets/images/logo-dark.png',
                height: 32,
                fit: BoxFit.contain,
              )
            : Text(_getAppBarTitle(),
                style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
        actions: [
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedNotification03,
              color: Colors.black,
              size: 24.0,
            ),
            tooltip: 'View notification status',
            onPressed: () => _showNotificationStatus(),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
      body: _buildSelectedScreen(),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          currentIndex: _getBottomNavIndex(),
          onTap: _onBottomNavTap,
          selectedItemColor: const Color(0xFF0B5CFF),
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 10,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: HugeIcon(icon: HugeIcons.strokeRoundedCalendar03, color: Colors.grey, size: 24.0),
              activeIcon: HugeIcon(icon: HugeIcons.strokeRoundedCalendar03, color: Color(0xFF0B5CFF), size: 24.0),
              label: 'Appts',
            ),
            BottomNavigationBarItem(
              icon: HugeIcon(icon: HugeIcons.strokeRoundedCall, color: Colors.grey, size: 24.0),
              activeIcon: HugeIcon(icon: HugeIcons.strokeRoundedCall, color: Color(0xFF0B5CFF), size: 24.0),
              label: 'Leads',
            ),
            BottomNavigationBarItem(
              icon: HugeIcon(icon: HugeIcons.strokeRoundedHome01, color: Colors.grey, size: 24.0),
              activeIcon: HugeIcon(icon: HugeIcons.strokeRoundedHome01, color: Color(0xFF0B5CFF), size: 24.0),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: HugeIcon(icon: HugeIcons.strokeRoundedTaskEdit01, color: Colors.grey, size: 24.0),
              activeIcon: HugeIcon(icon: HugeIcons.strokeRoundedTaskEdit01, color: Color(0xFF0B5CFF), size: 24.0),
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: HugeIcon(icon: HugeIcons.strokeRoundedSettings01, color: Colors.grey, size: 24.0),
              activeIcon: HugeIcon(icon: HugeIcons.strokeRoundedSettings01, color: Color(0xFF0B5CFF), size: 24.0),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  int _getBottomNavIndex() {
    switch (_selectedIndex) {
      case 2: return 0;
      case 1: return 1;
      case 0: return 2;
      case 4: return 3;
      default: return 2;
    }
  }

  void _onBottomNavTap(int index) {
    int screenIndex;
    switch (index) {
      case 0: screenIndex = 2; break;
      case 1: screenIndex = 1; break;
      case 2: screenIndex = 0; break;
      case 3: screenIndex = 4; break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ManageProfileScreen()),
        );
        return;
      default: screenIndex = 0;
    }
    setState(() => _selectedIndex = screenIndex);
  }
}

class _AddServiceDialog extends StatefulWidget {
  const _AddServiceDialog();

  @override
  State<_AddServiceDialog> createState() => _AddServiceDialogState();
}

class _AddServiceDialogState extends State<_AddServiceDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Service Name',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter')),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: Colors.grey[300]!)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: Colors.grey[300]!)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text('Close',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontFamily: 'Inter')),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final name = _controller.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please enter a service name')),
                      );
                      return;
                    }
                    Navigator.pop(context, name);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text('Add Service',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          fontFamily: 'Inter')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddTagDialog extends StatefulWidget {
  const _AddTagDialog();

  @override
  State<_AddTagDialog> createState() => _AddTagDialogState();
}

class _AddTagDialogState extends State<_AddTagDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  Color _selectedColor = const Color(0xFF0B5CFF);
  bool _isSaving = false;

  String get _selectedHexColor =>
      '#${_selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  void _pickColor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color', style: TextStyle(fontSize: 14)),
        contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        content: SizedBox(
          width: 220,
          height: 300,
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() {
                _selectedColor = color;
              });
            },
            pickerAreaHeightPercent: 0.7,
            displayThumbColor: false,
            enableAlpha: false,
            labelTypes: const [],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tag Name',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter')),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter tag name',
                hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: Colors.grey[300]!)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: Colors.grey[300]!)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Description',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter')),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter description',
                hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: Colors.grey[300]!)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: Colors.grey[300]!)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Color',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter')),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickColor,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(_selectedHexColor,
                      style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Inter',
                          color: Colors.grey[700])),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  child: Text('Close',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                          fontFamily: 'Inter')),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);
                          final name = _nameController.text.trim();
                          final description =
                              _descriptionController.text.trim();
                          if (name.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Tag name is required'),
                              ),
                            );
                            return;
                          }

                          setState(() => _isSaving = true);
                          try {
                            await TagApi.addTag(
                              name: name,
                              description: description,
                              colorHex: _selectedHexColor,
                            );
                            if (!mounted) return;
                            navigator.pop(true);
                          } catch (_) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Failed to save tag'),
                              ),
                            );
                          } finally {
                            if (mounted) setState(() => _isSaving = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Add Tag',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              fontFamily: 'Inter')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
