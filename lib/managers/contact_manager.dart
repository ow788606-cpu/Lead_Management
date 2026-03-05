import 'dart:typed_data';

import '../models/contact.dart';
import '../screens/contacts/contact_api.dart';

class ContactManager {
  static final ContactManager _instance = ContactManager._internal();
  factory ContactManager() => _instance;
  ContactManager._internal();

  final List<Contact> _contacts = [];

  List<Contact> get allContacts => _contacts;

  Future<void> loadContacts({bool forceRefresh = false}) async {
    if (!forceRefresh && _contacts.isNotEmpty) return;
    final fetched = await ContactApi.fetchContacts();
    _contacts
      ..clear()
      ..addAll(fetched);
  }

  Future<void> addContact(Contact contact) async {
    await ContactApi.addContact(contact);
    await loadContacts(forceRefresh: true);
  }

  Future<void> updateContact(String id, Contact updatedContact) async {
    await ContactApi.updateContact(updatedContact);
    await loadContacts(forceRefresh: true);
  }

  Future<void> deleteContact(String id) async {
    await ContactApi.deleteContact(id);
    await loadContacts(forceRefresh: true);
  }

  Future<Map<String, dynamic>> bulkUploadCsv({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final result = await ContactApi.bulkUploadCsv(
      bytes: bytes,
      fileName: fileName,
    );
    await loadContacts(forceRefresh: true);
    return result;
  }
}
