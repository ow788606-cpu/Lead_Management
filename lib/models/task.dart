class Task {
  final String id;
  final String title;
  final String description;
  final String priority;
  final DateTime dueDate;
  final String dueTime;
  bool isCompleted;
  DateTime? completedDate;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    required this.dueTime,
    this.isCompleted = false,
    this.completedDate,
  });
}
