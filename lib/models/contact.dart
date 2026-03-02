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

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
    id: json['id'],
    name: json['name'],
    email: json['email'],
    phone: json['phone'],
    phone2: json['phone2'],
    address: json['address'],
    country: json['country'],
    state: json['state'],
    city: json['city'],
    zip: json['zip'],
    leadSource: json['leadSource'],
    remark: json['remark'],
    tags: List<String>.from(json['tags'] ?? []),
    createdAt: DateTime.parse(json['createdAt']),
  );
}
