import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/leads/all_leads_screen.dart';
import 'screens/leads/detail_lead_screen.dart';
import 'screens/appointments/appointments_screen.dart';
import 'screens/contacts/contacts_screen.dart';
import 'screens/contacts/add_contact_screen.dart';
import 'services/services_screen.dart';
import 'services/add_services.dart';
import 'services/service_manager.dart';
import 'screens/tags/tags_screen.dart';
import 'screens/tags/add_tags.dart';
import 'widgets/app_drawer.dart';
import 'managers/auth_manager.dart';
import 'managers/contact_manager.dart';
import 'managers/lead_manager.dart';
import 'managers/task_manager.dart';
import 'services/notification_service.dart';
import 'services/lead_activity_api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize NotificationService singleton at app startup
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('NotificationService initialization failed: $e');
  }
  
  runApp(const CloopApp());
}

class CloopApp extends StatelessWidget {
  const CloopApp({super.key});

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF0B5CFF);
    return MaterialApp(
      title: 'Cloop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandBlue,
          primary: brandBlue,
        ),
        primaryColor: brandBlue,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        splashColor: brandBlue.withValues(alpha: 0.14),
        highlightColor: brandBlue.withValues(alpha: 0.08),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shadowColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          toolbarHeight: 32,
          iconTheme: IconThemeData(color: Colors.black, size: 18),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: brandBlue,
          selectionColor: brandBlue.withValues(alpha: 0.24),
          selectionHandleColor: brandBlue,
        ),
        iconTheme: const IconThemeData(color: brandBlue),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: brandBlue,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: brandBlue,
            foregroundColor: Colors.white,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: brandBlue,
            side: const BorderSide(color: brandBlue),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: brandBlue,
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: brandBlue, width: 1.4),
          ),
        ),
        listTileTheme: ListTileThemeData(
          selectedColor: brandBlue,
          iconColor: Colors.black87,
          selectedTileColor: brandBlue.withValues(alpha: 0.12),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: brandBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: brandBlue,
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return brandBlue;
            return Colors.white;
          }),
        ),
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return brandBlue;
            return Colors.grey;
          }),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return brandBlue;
            return Colors.grey[400];
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return brandBlue.withValues(alpha: 0.45);
            }
            return Colors.grey[300];
          }),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final authManager = AuthManager();
    final contactManager = ContactManager();
    final leadManager = LeadManager();
    final taskManager = TaskManager();

    await Future.wait([
      contactManager.loadContacts(),
      leadManager.loadLeads(),
      taskManager.loadTasks(),
    ]);
    final isLoggedIn = await authManager.isLoggedIn();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            isLoggedIn ? const MainScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;
  final _serviceManager = ServiceManager();
  // NotificationService is initialized globally, access singleton instance
  final _notificationService = NotificationService();
  int _tagsScreenVersion = 0;

  Widget? _buildFloatingActionButton() {
    switch (_selectedIndex) {
      case 3: // Contacts screen
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
      case 5: // Services screen
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
      case 6: // Tags screen
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
        return const AllLeadsScreen(initialTabIndex: 0);
      case 2:
        return const AppointmentsScreen();
      case 3:
        return const ContactsScreen();
      case 4:
        return const Center(child: Text('Tasks'));
      case 5:
        return const ServicesScreen();
      case 6:
        return TagsScreen(key: ValueKey(_tagsScreenVersion));
      default:
        return const DashboardScreen();
    }
  }

  List<Widget> _buildAppBarActions() {
    if (_selectedIndex == 2 || _selectedIndex == 5 || _selectedIndex == 6) {
      return [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'View notification status',
          onPressed: () => _showNotificationStatus(),
        ),
      ];
    }
    return const [];
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
      case 2:
        return 'Appointments Schedule';
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
    _selectedIndex = widget.initialIndex;
    _startNotificationMonitoring();
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
    
    // Get all tasks from task manager (combine pending and completed)
    final allTasks = [...taskManager.pendingTasks, ...taskManager.completedTasks].map((task) => {
      'id': task.id,
      'title': task.title,
      'description': task.description,
      'dueDate': task.dueDate,
      'dueTime': task.dueTime,
      'isCompleted': task.isCompleted,
      'priority': task.priority,
    }).toList();
    
    debugPrint('📋 Loaded ${allTasks.length} tasks');
    
    // Get all activities from all leads
    final allActivities = <Map<String, dynamic>>[];
    for (final lead in leadManager.allLeads) {
      try {
        debugPrint('🔍 Loading activities for lead: ${lead.contactName} (ID: ${lead.id})');
        final activities = await LeadActivityApi.getActivities(lead.id);
        debugPrint('📞 Found ${activities.length} activities for ${lead.contactName}');
        
        for (int i = 0; i < activities.length; i++) {
          final activity = activities[i];
          debugPrint('   Activity $i: ${activity['activity_type']} - scheduled_at: ${activity['scheduled_at']}');
          
          // Only include activities with scheduled_at dates
          if (activity['scheduled_at'] != null && activity['scheduled_at'].toString().isNotEmpty) {
            final scheduledActivity = {
              'id': activity['id'],
              'title': activity['activity_type'] ?? 'Activity',
              'description': activity['description'] ?? '',
              'scheduledDate': DateTime.parse(activity['scheduled_at']),
              'leadId': lead.id,
            };
            allActivities.add(scheduledActivity);
            debugPrint('   ✅ Added scheduled activity: ${scheduledActivity['title']} at ${scheduledActivity['scheduledDate']}');
          } else {
            debugPrint('   ❌ Skipped activity (no scheduled_at): ${activity['activity_type']}');
          }
        }
      } catch (e) {
        debugPrint('❌ Error loading activities for lead ${lead.contactName}: $e');
      }
    }
    
    debugPrint('📞 Total scheduled activities loaded: ${allActivities.length}');
    
    _notificationService.startMonitoring(
      leadManager.allLeads, 
      allTasks: allTasks,
      allActivities: allActivities,
    );
    
    // Check if there's a pending notification to navigate to
    _checkPendingNotification();
  }
  
  void _checkPendingNotification() {
    final pendingPayload = _notificationService.pendingPayload;
    if (pendingPayload != null) {
      _notificationService.clearPendingPayload();
      // Navigate based on notification type
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (pendingPayload.startsWith('lead:')) {
          final leadId = pendingPayload.substring(5);
          _navigateToLead(leadId);
        } else if (pendingPayload.startsWith('task:')) {
          final parts = pendingPayload.split(':');
          if (parts.length >= 3) {
            final taskId = parts[1];
            final leadId = parts[2];
            _navigateToTaskInLead(taskId, leadId);
          }
        } else if (pendingPayload.startsWith('activity:')) {
          final parts = pendingPayload.split(':');
          if (parts.length >= 3) {
            final activityId = parts[1];
            final leadId = parts[2];
            _navigateToActivityInLead(activityId, leadId);
          }
        }
      });
    }
  }
  
  void _navigateToLead(String leadId) {
    // Find the lead by ID
    final leadManager = LeadManager();
    try {
      final lead = leadManager.allLeads.firstWhere(
        (lead) => lead.id == leadId,
      );
      
      // Navigate directly to the lead detail screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailLeadScreen(
            lead: lead,
            startInEditMode: false,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Lead not found: $leadId');
      // Fallback to all leads screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AllLeadsScreen(initialTabIndex: 0),
        ),
      );
    }
  }
  
  void _navigateToTaskInLead(String taskId, String leadId) {
    // Find the lead by ID and navigate to its detail screen with tasks tab
    final leadManager = LeadManager();
    try {
      final lead = leadManager.allLeads.firstWhere(
        (lead) => lead.id == leadId,
      );
      
      // Navigate to lead detail screen - tasks will be visible in the Tasks tab
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailLeadScreen(
            lead: lead,
            startInEditMode: false,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Lead not found for task: $leadId');
      // Fallback to all leads screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AllLeadsScreen(initialTabIndex: 0),
        ),
      );
    }
  }
  
  void _navigateToActivityInLead(String activityId, String leadId) {
    // Find the lead by ID and navigate to its detail screen with activity tab
    final leadManager = LeadManager();
    try {
      final lead = leadManager.allLeads.firstWhere(
        (lead) => lead.id == leadId,
      );
      
      // Navigate to lead detail screen - activities will be visible in the Activity tab
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailLeadScreen(
            lead: lead,
            startInEditMode: false,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Lead not found for activity: $leadId');
      // Fallback to all leads screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AllLeadsScreen(initialTabIndex: 0),
        ),
      );
    }
  }

  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(_getAppBarTitle(),
            style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        actions: _buildAppBarActions(),
      ),
      drawer: AppDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _select,
      ),
      floatingActionButton: _buildFloatingActionButton(),
      body: _buildSelectedScreen(),
    );
  }

  void _select(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context);
  }
}
