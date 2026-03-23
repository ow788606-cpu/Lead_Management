import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'screens/main_screen.dart';
import 'screens/auth/login_screen.dart';
import 'managers/auth_manager.dart';
import 'managers/contact_manager.dart';
import 'managers/lead_manager.dart';
import 'managers/task_manager.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('UTC'));

  try {
    await NotificationService().initialize();
    await NotificationService().initializeOfflineNotifications();
  } catch (e) {
    debugPrint('NotificationService initialization failed: $e');
  }

  runApp(const CloopApp());
}

class CloopApp extends StatelessWidget {
  const CloopApp({super.key});

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF131416);
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

    try {
      await Future.wait([
        contactManager.loadContacts(),
        leadManager.loadLeads(),
        taskManager.loadTasks(),
      ]);
    } catch (e) {
      debugPrint('Data loading failed: $e');
    }

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
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
