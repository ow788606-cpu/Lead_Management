import 'dart:io';

class ApiConfig {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'https://app.cloopbook.com/api';
    }
    return 'http://localhost/lead/api';
  }
}
