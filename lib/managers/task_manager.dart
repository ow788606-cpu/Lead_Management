import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../screens/tasks/task_api.dart';

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
    await TaskApi.addTask(task);
    await loadTasks(forceRefresh: true);
    notifyListeners();
  }

  Future<void> completeTask(String id) async {
    await TaskApi.completeTask(id);
    await loadTasks(forceRefresh: true);
    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    await TaskApi.deleteTask(id);
    await loadTasks(forceRefresh: true);
    notifyListeners();
  }

  Future<void> loadTasks({bool forceRefresh = false}) async {
    if (_isLoaded && !forceRefresh) return;
    final fetched = await TaskApi.fetchTasks();
    _tasks
      ..clear()
      ..addAll(fetched);
    _isLoaded = true;
    notifyListeners();
  }
}
