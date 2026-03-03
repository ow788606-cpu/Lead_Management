import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class TaskManager extends ChangeNotifier {
  static final TaskManager _instance = TaskManager._internal();
  factory TaskManager() => _instance;
  TaskManager._internal();
  static const String _tasksKey = 'tasks_data';
  bool _isLoaded = false;

  final List<Task> _tasks = [];

  List<Task> get pendingTasks => _tasks.where((task) => !task.isCompleted).toList();
  List<Task> get completedTasks => _tasks.where((task) => task.isCompleted).toList();

  void addTask(Task task) {
    _tasks.add(task);
    _saveTasks();
    notifyListeners();
  }

  void completeTask(String id) {
    final task = _tasks.firstWhere((t) => t.id == id);
    task.isCompleted = true;
    task.completedDate = DateTime.now();
    _saveTasks();
    notifyListeners();
  }

  void deleteTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    _saveTasks();
    notifyListeners();
  }

  Future<void> loadTasks() async {
    if (_isLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getString(_tasksKey);
    if (rawData != null && rawData.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(rawData) as List<dynamic>;
      _tasks
        ..clear()
        ..addAll(
          decoded.map((item) => Task.fromJson(item as Map<String, dynamic>)),
        );
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_tasks.map((task) => task.toJson()).toList());
    await prefs.setString(_tasksKey, data);
  }
}
