import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../models/contact.dart';
import '../../services/api_config.dart';

class ContactApi {
  static Uri _contactsUri() => Uri.parse('${ApiConfig.baseUrl}/contacts.php');
  static Uri _bulkUploadUri() =>
      Uri.parse('${ApiConfig.baseUrl}/contacts_bulk_upload.php');

  static Future<List<Contact>> fetchContacts() async {
    final response = await http.get(_contactsUri());
    if (response.statusCode != 200) {
      throw Exception('Failed to load contacts');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid contacts response format');
    }
    if (decoded['success'] != true) {
      throw Exception(
          (decoded['message'] ?? 'Contacts API returned error').toString());
    }

    final rows = (decoded['data'] as List<dynamic>? ?? [])
        .map((item) => Contact.fromJson(item as Map<String, dynamic>))
        .toList();
    return rows;
  }

  static Future<void> addContact(Contact contact, {int userId = 1}) async {
    final response = await http.post(
      _contactsUri(),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'name': contact.name,
        'email': contact.email,
        'contact_number': contact.phone,
        'contact_number2': contact.phone2,
        'address': contact.address,
        'country': contact.country,
        'state': contact.state,
        'city': contact.city,
        'zip': contact.zip,
        'lead_source': contact.leadSource,
        'remark': contact.remark,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add contact');
    }
  }

  static Future<void> updateContact(Contact contact) async {
    final response = await http.put(
      _contactsUri(),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': int.tryParse(contact.id) ?? 0,
        'name': contact.name,
        'email': contact.email,
        'contact_number': contact.phone,
        'contact_number2': contact.phone2,
        'address': contact.address,
        'country': contact.country,
        'state': contact.state,
        'city': contact.city,
        'zip': contact.zip,
        'lead_source': contact.leadSource,
        'remark': contact.remark,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update contact');
    }
  }

  static Future<void> deleteContact(String id) async {
    final contactId = int.tryParse(id) ?? 0;
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/contacts.php?id=$contactId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete contact');
    }
  }

  static Future<Map<String, dynamic>> bulkUploadCsv({
    required Uint8List bytes,
    required String fileName,
    int userId = 1,
  }) async {
    final request = http.MultipartRequest('POST', _bulkUploadUri());
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      ),
    );
    request.fields['user_id'] = userId.toString();

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200) {
      throw Exception('Failed to upload CSV');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid bulk upload response');
    }
    if (decoded['success'] != true) {
      throw Exception((decoded['message'] ?? 'Bulk upload failed').toString());
    }
    return (decoded['data'] as Map<String, dynamic>? ?? {});
  }
}
