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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'dueDate': dueDate.toIso8601String(),
      'dueTime': dueTime,
      'isCompleted': isCompleted,
      'completedDate': completedDate?.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      priority: json['priority'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      dueTime: json['dueTime'] as String,
      isCompleted: (json['isCompleted'] as bool?) ?? false,
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'] as String)
          : null,
    );
  }
}
