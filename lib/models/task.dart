import 'dart:convert';

class Task {
  final String id;
  final String? leadId;
  final String? createdBy;
  final String? assignedTo;
  final String title;
  final String description;
  final String priority;
  final DateTime dueDate;
  final String dueTime;
  bool isCompleted;
  DateTime? completedDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? meta;

  Task({
    required this.id,
    this.leadId,
    this.createdBy,
    this.assignedTo,
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    required this.dueTime,
    this.isCompleted = false,
    this.completedDate,
    this.createdAt,
    this.updatedAt,
    this.meta,
  });

  Map<String, dynamic> toJson() {
    // Combine dueDate and dueTime to create complete datetime
    DateTime completeDueDateTime = dueDate;
    
    // Parse the dueTime string to get hour and minute
    try {
      final timeMatch = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false)
          .firstMatch(dueTime);
      if (timeMatch != null) {
        int hour = int.parse(timeMatch.group(1)!);
        int minute = int.parse(timeMatch.group(2)!);
        final isPM = timeMatch.group(3)!.toUpperCase() == 'PM';
        if (isPM && hour != 12) hour += 12;
        if (!isPM && hour == 12) hour = 0;
        
        completeDueDateTime = DateTime(
          dueDate.year,
          dueDate.month,
          dueDate.day,
          hour,
          minute,
        );
      }
    } catch (e) {
      // If parsing fails, use the date with default time (12:00 PM)
      completeDueDateTime = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
        12,
        0,
      );
    }
    
    return {
      'id': id,
      'lead_id': leadId,
      'title': title,
      'description': description,
      'priority': priority,
      'due_at': completeDueDateTime.toIso8601String(),
      'dueTime': dueTime,
      'isCompleted': isCompleted,
      'completedDate': completedDate?.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    DateTime dueDateTime;
    String dueTimeString = '12:00 PM';
    
    // Parse the due_at field which contains the complete datetime
    if (json['due_at'] != null) {
      dueDateTime = DateTime.parse(json['due_at'].toString());
      // Extract time and format as 12-hour string
      int hour = dueDateTime.hour;
      int minute = dueDateTime.minute;
      String period = 'AM';
      
      if (hour == 0) {
        hour = 12;
      } else if (hour > 12) {
        hour = hour - 12;
        period = 'PM';
      } else if (hour == 12) {
        period = 'PM';
      }
      
      dueTimeString = '${hour.toString()}:${minute.toString().padLeft(2, '0')} $period';
    } else if (json['dueDate'] != null) {
      dueDateTime = DateTime.parse(json['dueDate'].toString());
    } else {
      dueDateTime = DateTime.now();
    }
    
    // Use provided dueTime if available, otherwise use extracted time
    if (json['dueTime'] != null && json['dueTime'].toString().isNotEmpty) {
      dueTimeString = json['dueTime'].toString();
    }
    
    Map<String, dynamic>? metaMap;
    final metaRaw = json['meta'];
    if (metaRaw is Map<String, dynamic>) {
      metaMap = metaRaw;
    } else if (metaRaw is String && metaRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(metaRaw);
        if (decoded is Map<String, dynamic>) {
          metaMap = decoded;
        }
      } catch (_) {}
    }

    return Task(
      id: (json['id'] ?? '').toString(),
      leadId: json['lead_id']?.toString(),
      createdBy: json['created_by']?.toString(),
      assignedTo: json['assigned_to']?.toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      priority: (json['priority'] ?? 'Medium').toString(),
      dueDate: DateTime(dueDateTime.year, dueDateTime.month, dueDateTime.day), // Date only
      dueTime: dueTimeString,
      isCompleted: json['isCompleted'] == true || 
                   json['is_completed'] == true ||
                   json['status'] == 'completed',
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'].toString())
          : json['completed_at'] != null
              ? DateTime.parse(json['completed_at'].toString())
              : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      meta: metaMap,
    );
  }
}
