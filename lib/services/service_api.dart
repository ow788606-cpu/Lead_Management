import 'dart:convert';

import 'package:http/http.dart' as http;

import '../managers/auth_manager.dart';
import 'api_config.dart';

class ServiceItem {
  final int id;
  final String name;

  const ServiceItem({
    required this.id,
    required this.name,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: int.tryParse(json['service_id'].toString()) ?? 0,
      name: (json['service_name'] ?? '').toString(),
    );
  }
}

class ServiceApi {
  static Uri _servicesUri({int? userId}) => Uri.parse(
      '${ApiConfig.baseUrl}/services.php${userId != null ? '?user_id=$userId' : ''}');

  static Future<List<ServiceItem>> fetchServices() async {
    final userId = await AuthManager().getUserId() ?? 0;
    final response = await http.get(_servicesUri(userId: userId));
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load services (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid services response format');
    }

    if (decoded['success'] == false) {
      throw Exception(
          (decoded['message'] ?? 'Services API returned error').toString());
    }

    final data = (decoded['data'] as List<dynamic>? ?? [])
        .map((item) => ServiceItem.fromJson(item as Map<String, dynamic>))
        .toList();
    return data;
  }

  static Future<void> addService({
    required String serviceName,
    int userId = 1,
  }) async {
    final effectiveUserId = await AuthManager().getUserId() ?? userId;
    final response = await http.post(
      _servicesUri(),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': effectiveUserId,
        'service_name': serviceName,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add service');
    }
  }

  static Future<void> deleteService(int id) async {
    final userId = await AuthManager().getUserId() ?? 0;
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/services.php?id=$id&user_id=$userId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete service');
    }
  }
}
