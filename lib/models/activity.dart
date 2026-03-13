class Activity {
  final String id;
  final String leadId;
  final String type;
  final String title;
  final String? description;
  final DateTime createdAt;

  Activity({
    required this.id,
    required this.leadId,
    required this.type,
    required this.title,
    this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lead_id': leadId,
      'type': type,
      'title': title,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'].toString(),
      leadId: json['lead_id'].toString(),
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}