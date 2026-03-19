import 'dart:io';

class ApiConfig {
  static String get baseUrl {
    if (Platform.isAndroid) {
      // Physical Android device should use this PC's LAN IP.
      return 'http://192.168.29.70/lead/api';
    }
    return 'http://localhost/lead/api';
  }
}
