import 'package:flutter/foundation.dart';
import '../models/task.dart';

class TaskManager extends ChangeNotifier {
  static final TaskManager _instance = TaskManager._internal();
  factory TaskManager() => _instance;
  TaskManager._internal();

  final List<Task> _tasks = [];

  List<Task> get pendingTasks => _tasks.where((task) => !task.isCompleted).toList();
  List<Task> get completedTasks => _tasks.where((task) => task.isCompleted).toList();

  void addTask(Task task) {
    _tasks.add(task);
    notifyListeners();
  }

  void completeTask(String id) {
    final task = _tasks.firstWhere((t) => t.id == id);
    task.isCompleted = true;
    task.completedDate = DateTime.now();
    notifyListeners();
  }

  void deleteTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }
}
