class Lead {
  final String id;
  final String contactName;
  final String? email;
  final String? phone;
  final String? service;
  final String? tags;
  final String? notes;
  final DateTime? followUpDate;
  final String? followUpTime;
  final DateTime createdAt;
  bool isCompleted;

  Lead({
    required this.id,
    required this.contactName,
    this.email,
    this.phone,
    this.service,
    this.tags,
    this.notes,
    this.followUpDate,
    this.followUpTime,
    required this.createdAt,
    this.isCompleted = false,
  });

  bool get isOverdue {
    if (followUpDate == null || isCompleted) return false;
    return followUpDate!.isBefore(DateTime.now());
  }

  bool get isFresh {
    final daysSinceCreated = DateTime.now().difference(createdAt).inDays;
    return daysSinceCreated <= 7 && !isCompleted;
  }
}
