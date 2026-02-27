import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../main.dart';

class AppRoutes {
  static const String login = '/login';
  static const String main = '/main';
  static const String dashboard = '/dashboard';
  static const String leads = '/leads';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    main: (context) => const MainScreen(),
  };
}
