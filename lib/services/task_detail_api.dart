import 'dart:convert';
import 'package:http/http.dart' as http;
import '../managers/auth_manager.dart';
import 'api_config.dart';

class TaskDetailApi {
  static Future<Map<String, dynamic>?> fetchTaskDetail(
    String taskId, {
    String taskSource = 'tasks',
  }) async {
    try {
      final headers = await AuthManager().authHeaders(includeContentType: false);
      final source = taskSource == 'lead_tasks' ? 'lead_tasks' : 'tasks';
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/task_details.php?task_id=$taskId&task_source=$source',
        ),
        headers: headers,
      );
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['success'] != true) return null;
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> saveTaskDetail({
    required String taskId,
    required Map<String, dynamic> payload,
    String taskSource = 'tasks',
  }) async {
    try {
      final headers = await AuthManager().authHeaders();
      final source = taskSource == 'lead_tasks' ? 'lead_tasks' : 'tasks';
      final body = {
        'task_id': int.tryParse(taskId) ?? 0,
        'task_source': source,
        ...payload,
      };
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/task_details.php'),
        headers: headers,
        body: jsonEncode(body),
      );
      if (response.statusCode != 200) {
        return 'Server error (${response.statusCode})';
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return 'Invalid server response';
      }
      if (decoded['success'] == true) return null;
      return (decoded['message'] ?? 'Failed to save').toString();
    } catch (_) {
      return 'Network error while saving';
    }
  }

  static Future<Map<String, dynamic>?> uploadAttachment({
    required String taskId,
    String taskSource = 'tasks',
    required String filePath,
    required String fileName,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/task_detail_upload.php'),
      );
      final headers =
          await AuthManager().authHeaders(includeContentType: false);
      request.headers.addAll(headers);
      request.fields['task_id'] = taskId;
      request.fields['task_source'] =
          taskSource == 'lead_tasks' ? 'lead_tasks' : 'tasks';
      request.files.add(
        await http.MultipartFile.fromPath(
          'attachment',
          filePath,
          filename: fileName,
        ),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['success'] != true) return null;
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
