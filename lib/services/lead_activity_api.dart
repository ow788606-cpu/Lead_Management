import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class LeadActivityApi {
  static Future<List<Map<String, dynamic>>> getActivities(String leadId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/lead_activities.php?lead_id=$leadId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final activities = List<Map<String, dynamic>>.from(data['data']);
          return activities;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveActivity({
    required String leadId,
    required String activityType,
    required String description,
    required int userId,
    DateTime? scheduledAt,
  }) async {
    try {
      final requestBody = {
        'lead_id': int.tryParse(leadId) ?? 0,
        'activity_type': activityType,
        'description': description,
        'user_id': userId,
      };
      
      // Add scheduled_at if provided
      if (scheduledAt != null) {
        requestBody['scheduled_at'] = scheduledAt.toIso8601String();
      }
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/lead_activities.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to save activity');
      }
    } catch (e) {
      throw Exception('Error saving activity: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getNotes(String leadId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/lead_notes.php?lead_id=$leadId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final notes = List<Map<String, dynamic>>.from(data['data']);
          return notes;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveNote({
    required String leadId,
    required String content,
    required int userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/lead_notes.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'lead_id': int.tryParse(leadId) ?? 0,
          'content': content,
          'user_id': userId,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to save note');
      }
    } catch (e) {
      throw Exception('Error saving note: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getTasks(String leadId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/lead_tasks.php?lead_id=$leadId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final tasks = List<Map<String, dynamic>>.from(data['data']);
          return tasks;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveTask({
    required String leadId,
    required String title,
    required String description,
    required String priority,
    required DateTime dueDate,
    required int userId,
    String? dueTime,
  }) async {
    try {
      final requestBody = {
        'lead_id': int.tryParse(leadId) ?? 0,
        'title': title,
        'description': description,
        'priority': priority,
        'due_date': dueDate.toIso8601String(),
        'user_id': userId,
      };
      
      // Add due_time if provided
      if (dueTime != null) {
        requestBody['due_time'] = dueTime;
      }
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/lead_tasks.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to save task');
      }
    } catch (e) {
      throw Exception('Error saving task: $e');
    }
  }

  static Future<void> updateTask({
    required int taskId,
    bool? isCompleted,
    String? title,
    String? description,
    String? priority,
    DateTime? dueDate,
  }) async {
    try {
      final Map<String, dynamic> updateData = {'id': taskId};

      if (isCompleted != null) updateData['is_completed'] = isCompleted;
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (priority != null) updateData['priority'] = priority;
      if (dueDate != null) updateData['due_date'] = dueDate.toIso8601String();

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/lead_tasks.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update task');
      }
    } catch (e) {
      throw Exception('Error updating task: $e');
    }
  }
}
