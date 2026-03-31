import 'dart:convert';
import 'package:http/http.dart' as http;
import '../managers/auth_manager.dart';
import 'api_config.dart';

class TaskNotificationApi {
  static Future<List<Map<String, dynamic>>> fetchNotifications({
    String? taskId,
    String? taskSource,
  }) async {
    try {
      final headers = await AuthManager().authHeaders(includeContentType: false);
      final source = taskSource == 'lead_tasks' ? 'lead_tasks' : null;
      String query = '';
      if (taskId != null && taskId.isNotEmpty) {
        query = '?task_id=$taskId';
        if (source != null) query = '$query&task_source=$source';
      } else if (source != null) {
        query = '?task_source=$source';
      }
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/task_notifications.php$query'),
        headers: headers,
      );
      if (response.statusCode != 200) return [];
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return [];
      if (decoded['success'] != true) return [];
      final data = decoded['data'];
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<bool> createNotification({
    required String taskId,
    required String title,
    required String message,
    String taskSource = 'tasks',
  }) async {
    try {
      final headers = await AuthManager().authHeaders();
      final source = taskSource == 'lead_tasks' ? 'lead_tasks' : 'tasks';
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/task_notifications.php'),
        headers: headers,
        body: jsonEncode({
          'task_id': int.tryParse(taskId) ?? 0,
          'task_source': source,
          'title': title,
          'message': message,
        }),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        return false;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return false;
      return decoded['success'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> setRead({
    required String id,
    required bool isRead,
  }) async {
    try {
      final headers = await AuthManager().authHeaders();
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/task_notifications.php'),
        headers: headers,
        body: jsonEncode({
          'id': int.tryParse(id) ?? 0,
          'is_read': isRead,
        }),
      );
      if (response.statusCode != 200) return false;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return false;
      return decoded['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
