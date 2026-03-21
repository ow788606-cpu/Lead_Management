import 'dart:io';

class ApiConfig {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://192.168.29.159/lead/api';
    }
    return 'http://localhost/lead/api';
  }
}
