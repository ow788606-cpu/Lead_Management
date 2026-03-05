import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../managers/auth_manager.dart';
import '../../models/task.dart';
import '../../services/api_config.dart';

class TaskApi {
  static Uri _tasksUri({int? userId}) => Uri.parse(
      '${ApiConfig.baseUrl}/tasks.php${userId != null ? '?user_id=$userId' : ''}');

  static Future<List<Task>> fetchTasks() async {
    final userId = await AuthManager().getUserId() ?? 0;
    final response = await http.get(_tasksUri(userId: userId));
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load tasks (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid tasks response format');
    }
    if (decoded['success'] != true) {
      throw Exception(
          (decoded['message'] ?? 'Tasks API returned error').toString());
    }

    final data = (decoded['data'] as List<dynamic>? ?? [])
        .map((item) => item as Map<String, dynamic>)
        .map(_mapTaskFromApi)
        .toList();
    return data;
  }

  static Future<void> addTask(Task task, {int userId = 1}) async {
    final effectiveUserId = await AuthManager().getUserId() ?? userId;
    final dueAt = DateTime(
      task.dueDate.year,
      task.dueDate.month,
      task.dueDate.day,
      _parseHour(task.dueTime),
      _parseMinute(task.dueTime),
    );

    final response = await http.post(
      _tasksUri(),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': effectiveUserId,
        'title': task.title,
        'description': task.description,
        'priority': _mapPriorityToDb(task.priority),
        'due_at': dueAt.toIso8601String(),
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create task');
    }
  }

  static Future<void> completeTask(String id) async {
    final userId = await AuthManager().getUserId() ?? 0;
    final response = await http.patch(
      _tasksUri(),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': int.tryParse(id) ?? 0,
        'user_id': userId,
        'action': 'complete',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to complete task');
    }
  }

  static Future<void> deleteTask(String id) async {
    final taskId = int.tryParse(id) ?? 0;
    final userId = await AuthManager().getUserId() ?? 0;
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/tasks.php?id=$taskId&user_id=$userId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete task');
    }
  }

  static Task _mapTaskFromApi(Map<String, dynamic> json) {
    final dueAtRaw = (json['due_at'] ?? '').toString();
    final completedAtRaw = (json['completed_at'] ?? '').toString();
    final dueAt = DateTime.tryParse(dueAtRaw);
    final completedAt =
        completedAtRaw.isEmpty ? null : DateTime.tryParse(completedAtRaw);
    final status = (json['status'] ?? '').toString().toLowerCase();
    final isCompleted = completedAt != null || status == 'completed';

    return Task(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      priority: _mapPriorityFromDb((json['priority'] ?? '').toString()),
      dueDate: dueAt ?? DateTime.now(),
      dueTime: dueAt == null ? '--:--' : _formatTime12h(dueAt),
      isCompleted: isCompleted,
      completedDate: completedAt,
    );
  }

  static String _mapPriorityFromDb(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return 'Low';
      case 'normal':
        return 'Medium';
      case 'high':
        return 'High';
      case 'critical':
        return 'Urgent';
      default:
        return 'Medium';
    }
  }

  static String _mapPriorityToDb(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return 'low';
      case 'medium':
        return 'normal';
      case 'high':
        return 'high';
      case 'urgent':
        return 'critical';
      default:
        return 'normal';
    }
  }

  static int _parseHour(String dueTime) {
    final normalized = dueTime.trim().toUpperCase();
    final match =
        RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$').firstMatch(normalized);
    if (match == null) return 0;
    var hour = int.tryParse(match.group(1) ?? '0') ?? 0;
    final period = match.group(3);
    if (period == 'PM' && hour < 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return hour.clamp(0, 23);
  }

  static int _parseMinute(String dueTime) {
    final normalized = dueTime.trim().toUpperCase();
    final match =
        RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$').firstMatch(normalized);
    if (match == null) return 0;
    return (int.tryParse(match.group(2) ?? '0') ?? 0).clamp(0, 59);
  }

  static String _formatTime12h(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final suffix = h >= 12 ? 'PM' : 'AM';
    final hour12 = (h % 12 == 0) ? 12 : (h % 12);
    return '$hour12:$m $suffix';
  }
}
