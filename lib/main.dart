import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/leads/all_leads_screen.dart';
import 'screens/appointments/appointments_screen.dart';
import 'screens/contacts/contacts_screen.dart';
import 'services/services_screen.dart';
import 'screens/tags/tags_screen.dart';
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
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const AllLeadsScreen(),
    const AppointmentsScreen(),
    const ContactsScreen(),
    const Center(child: Text('Tasks')),
    const ServicesScreen(),
    const TagsScreen(),
  ];

  @override
  void initState() {
    super.initState();
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
        actions: const [],
      ),
      drawer: AppDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _select,
      ),
      body: _screens[_selectedIndex],
    );
  }

  void _select(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context);
  }
}

