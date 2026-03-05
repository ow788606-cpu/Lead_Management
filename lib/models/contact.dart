class Contact {
  final String id;
  final String name;
  final String? email;
  final String phone;
  final String? phone2;
  final String address;
  final String? country;
  final String? state;
  final String? city;
  final String? zip;
  final String? leadSource;
  final String? remark;
  final List<String> tags;
  final DateTime createdAt;

  Contact({
    required this.id,
    required this.name,
    this.email,
    required this.phone,
    this.phone2,
    required this.address,
    this.country,
    this.state,
    this.city,
    this.zip,
    this.leadSource,
    this.remark,
    this.tags = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'phone2': phone2,
        'address': address,
        'country': country,
        'state': state,
        'city': city,
        'zip': zip,
        'leadSource': leadSource,
        'remark': remark,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Contact.fromJson(Map<String, dynamic> json) {
    final parsedTags = _parseTags(json['tags']);
    return Contact(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: _nullableString(json['email']),
      phone: (json['phone'] ?? json['contact_number'] ?? '').toString(),
      phone2: _nullableString(json['phone2'] ?? json['contact_number2']),
      address: (json['address'] ?? '').toString(),
      country: _nullableString(json['country']),
      state: _nullableString(json['state']),
      city: _nullableString(json['city']),
      zip: _nullableString(json['zip']),
      leadSource: _nullableString(json['leadSource'] ?? json['lead_source']),
      remark: _nullableString(json['remark']),
      tags: parsedTags,
      createdAt: DateTime.tryParse(
            (json['createdAt'] ?? json['created_at'] ?? '').toString(),
          ) ??
          DateTime.now(),
    );
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;
    final v = value.toString().trim();
    return v.isEmpty ? null : v;
  }

  static List<String> _parseTags(dynamic value) {
    if (value == null) return const [];
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final raw = value.toString().trim();
    if (raw.isEmpty || raw.toLowerCase() == 'null') return const [];
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
