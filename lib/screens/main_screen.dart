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
import '../services/add_services.dart';
import '../services/service_manager.dart';
import '../services/notification_service.dart';
import '../services/lead_activity_api.dart';
import '../screens/tags/tags_screen.dart';
import '../screens/tags/add_tags.dart';
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
            final result = await Navigator.push<String>(
              context,
              MaterialPageRoute(
                builder: (context) => const AddServicesScreen(),
              ),
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
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddTagsScreen(),
              ),
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

  List<Widget> _buildAppBarActions() {
    return [
      IconButton(
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedNotification03,
          color: Colors.black,
          size: 20.0,
        ),
        tooltip: 'View notification status',
        onPressed: () => _showNotificationStatus(),
      ),
    ];
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
        return 'Cloop';
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
          builder: (context) => DetailLeadScreen(lead: lead, startInEditMode: false),
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
          builder: (context) => DetailLeadScreen(lead: lead, startInEditMode: false),
        ),
      );
    } catch (e) {
      debugPrint('Lead not found for task: $leadId');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AllLeadsScreen(initialTabIndex: 0)),
      );
    }
  }

  void _navigateToActivityInLead(String activityId, String leadId) {
    final leadManager = LeadManager();
    try {
      final lead = leadManager.allLeads.firstWhere((lead) => lead.id == leadId);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailLeadScreen(lead: lead, startInEditMode: false),
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
        centerTitle: true,
        title: Text(_getAppBarTitle(),
            style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        actions: _buildAppBarActions(),
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
