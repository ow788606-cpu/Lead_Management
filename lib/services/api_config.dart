import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) {
      return override;
    }

    if (kReleaseMode) {
      return 'https://app.cloopbook.com/api';
    }

    if (Platform.isAndroid) {
      // Default to LAN IP for physical device during debug builds.
      return 'http://192.168.29.159/lead/api';
    }

    return 'http://localhost/lead/api';
  }
}
