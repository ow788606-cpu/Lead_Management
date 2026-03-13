class Note {
  final String id;
  final String leadId;
  final String content;
  final DateTime createdAt;

  Note({
    required this.id,
    required this.leadId,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lead_id': leadId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'].toString(),
      leadId: json['lead_id'].toString(),
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}