import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/leads/all_leads_screen.dart';
import 'screens/appointments/appointments_screen.dart';
import 'screens/contacts/contacts_screen.dart';
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

void main() => runApp(const CloopApp());

class CloopApp extends StatelessWidget {
  const CloopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cloop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shadowColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
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

  Widget _buildSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const AllLeadsScreen();
      case 2:
        return const AppointmentsScreen();
      case 3:
        return const ContactsScreen();
      case 4:
        return const Center(child: Text('Tasks'));
      case 5:
        return const ServicesScreen();
      case 6:
        return const TagsScreen();
      default:
        return const DashboardScreen();
    }
  }

  List<Widget> _buildAppBarActions() {
    if (_selectedIndex == 5) {
      return [
        TextButton(
          onPressed: () async {
            final result = await Navigator.push<String>(
              context,
              MaterialPageRoute(
                builder: (context) => const AddServicesScreen(),
              ),
            );
            if (result != null && result.trim().isNotEmpty) {
              _serviceManager.addService(result.trim());
              if (mounted) setState(() {});
            }
          },
          child: const Text(
            'Add Service',
            style: TextStyle(color: Color(0xFF0B5CFF)),
          ),
        ),
      ];
    }
    if (_selectedIndex == 6) {
      return [
        TextButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddTagsScreen(),
              ),
            );
            if (mounted) setState(() {});
          },
          child: const Text(
            'Add Tag',
            style: TextStyle(color: Color(0xFF0B5CFF)),
          ),
        ),
      ];
    }
    return const [];
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
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
        title: const Text('Cloop',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
        actions: _buildAppBarActions(),
      ),
      drawer: AppDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _select,
      ),
      body: _buildSelectedScreen(),
    );
  }

  void _select(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context);
  }
}

