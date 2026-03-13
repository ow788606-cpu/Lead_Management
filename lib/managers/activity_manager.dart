import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/activity.dart';
import '../services/api_config.dart';
import 'auth_manager.dart';

class ActivityManager {
  static final ActivityManager _instance = ActivityManager._internal();
  factory ActivityManager() => _instance;
  ActivityManager._internal();

  Future<List<Activity>> getActivitiesByLeadId(String leadId) async {
    final userId = await AuthManager().getUserId() ?? 0;
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/activities.php?lead_id=$leadId&user_id=$userId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((item) => Activity.fromJson(item))
            .toList();
      }
    }
    return [];
  }

  Future<bool> addActivity(Activity activity) async {
    final userId = await AuthManager().getUserId() ?? 0;
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/activities.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        ...activity.toJson(),
        'user_id': userId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true;
    }
    return false;
  }
}