import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../managers/auth_manager.dart';
import '../../services/api_config.dart';

class TagItem {
  final int id;
  final String name;
  final String description;
  final String colorHex;

  const TagItem({
    required this.id,
    required this.name,
    required this.description,
    required this.colorHex,
  });

  factory TagItem.fromJson(Map<String, dynamic> json) {
    final rawColor = (json['color_hex'] ?? json['tag_class'] ?? '').toString().trim();
    return TagItem(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      colorHex: rawColor.isEmpty ? '#0B5CFF' : rawColor,
    );
  }
}

class TagApi {
  static Uri _tagsUri({int? userId}) => Uri.parse(
      '${ApiConfig.baseUrl}/tags.php${userId != null ? '?user_id=$userId' : ''}');

  static Future<List<TagItem>> fetchTags() async {
    final userId = await AuthManager().getUserId() ?? 0;
    final response = await http.get(_tagsUri(userId: userId));
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load tags (HTTP ${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid tags response format');
    }
    final jsonBody = decoded;
    if (jsonBody['success'] == false) {
      throw Exception((jsonBody['message'] ?? 'Tags API returned error').toString());
    }
    final data = (jsonBody['data'] as List<dynamic>? ?? [])
        .map((item) => TagItem.fromJson(item as Map<String, dynamic>))
        .toList();
    return data;
  }

  static Future<void> addTag({
    required String name,
    required String description,
    required String colorHex,
    int userId = 1,
  }) async {
    final effectiveUserId = await AuthManager().getUserId() ?? userId;
    final response = await http.post(
      _tagsUri(),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': effectiveUserId,
        'name': name,
        'description': description,
        'color_hex': colorHex,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add tag');
    }
  }

  static Future<void> deleteTag(int id) async {
    final userId = await AuthManager().getUserId() ?? 0;
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/tags.php?id=$id&user_id=$userId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete tag');
    }
  }
}
