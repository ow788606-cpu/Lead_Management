import 'dart:io';

class ApiConfig {
  static String get baseUrl {
    if (Platform.isAndroid) {
      // Android emulator should access localhost via 10.0.2.2
      return 'http://10.0.2.2/lead/api';
    }
    return 'http://localhost/lead/api';
  }
}
