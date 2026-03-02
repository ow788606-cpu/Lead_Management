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
}
