import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';
import '../services/api_config.dart';
import 'auth_manager.dart';

class TaskManager extends ChangeNotifier {
  static final TaskManager _instance = TaskManager._internal();
  factory TaskManager() => _instance;
  TaskManager._internal();
  bool _isLoaded = false;

  final List<Task> _tasks = [];

  List<Task> get pendingTasks =>
      _tasks.where((task) => !task.isCompleted).toList();
  List<Task> get completedTasks =>
      _tasks.where((task) => task.isCompleted).toList();

  Future<void> addTask(Task task) async {
    final userId = await AuthManager().getUserId() ?? 0;
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/tasks.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        ...task.toJson(),
        'user_id': userId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        await loadTasks(forceRefresh: true);
        notifyListeners();
      }
    }
  }

  Future<void> completeTask(String id) async {
    final userId = await AuthManager().getUserId() ?? 0;
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/tasks.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': id,
        'user_id': userId,
        'is_completed': true,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        await loadTasks(forceRefresh: true);
        notifyListeners();
      }
    }
  }

  Future<void> updateTask(Task task) async {
    final userId = await AuthManager().getUserId() ?? 0;
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/tasks.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        ...task.toJson(),
        'user_id': userId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        await loadTasks(forceRefresh: true);
        notifyListeners();
      }
    }
  }

  Future<void> deleteTask(String id) async {
    final userId = await AuthManager().getUserId() ?? 0;
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/tasks.php?id=$id&user_id=$userId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        await loadTasks(forceRefresh: true);
        notifyListeners();
      }
    }
  }

  Future<void> loadTasks({bool forceRefresh = false}) async {
    if (_isLoaded && !forceRefresh) return;
    try {
      final userId = await AuthManager().getUserId() ?? 0;
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/tasks.php?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final tasks = (data['data'] as List)
              .map((item) => Task.fromJson(item as Map<String, dynamic>))
              .toList();
          _tasks
            ..clear()
            ..addAll(tasks);
          _isLoaded = true;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    }
  }

  Future<List<Task>> getTasksByLeadId(String leadId) async {
    try {
      final userId = await AuthManager().getUserId() ?? 0;
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/tasks.php?lead_id=$leadId&user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((item) => Task.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error loading tasks by lead ID: $e');
    }
    return [];
  }
}