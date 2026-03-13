class Task {
  final String id;
  final String? leadId;
  final String title;
  final String description;
  final String priority;
  final DateTime dueDate;
  final String dueTime;
  bool isCompleted;
  DateTime? completedDate;

  Task({
    required this.id,
    this.leadId,
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
      'lead_id': leadId,
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
      id: (json['id'] ?? '').toString(),
      leadId: json['lead_id']?.toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      priority: (json['priority'] ?? 'Medium').toString(),
      dueDate: json['dueDate'] != null 
          ? DateTime.parse(json['dueDate'].toString())
          : json['due_at'] != null
              ? DateTime.parse(json['due_at'].toString())
              : DateTime.now(),
      dueTime: (json['dueTime'] ?? json['due_time'] ?? '12:00 PM').toString(),
      isCompleted: json['isCompleted'] == true || 
                   json['is_completed'] == true ||
                   json['status'] == 'completed',
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'].toString())
          : json['completed_at'] != null
              ? DateTime.parse(json['completed_at'].toString())
              : null,
    );
  }
}
