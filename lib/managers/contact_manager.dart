import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact.dart';

class ContactManager {
  static final ContactManager _instance = ContactManager._internal();
  factory ContactManager() => _instance;
  ContactManager._internal();

  final List<Contact> _contacts = [];
  static const String _storageKey = 'contacts';

  List<Contact> get allContacts => _contacts;

  Future<void> loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? contactsJson = prefs.getString(_storageKey);
    if (contactsJson != null) {
      final List<dynamic> decoded = jsonDecode(contactsJson);
      _contacts.clear();
      _contacts.addAll(decoded.map((json) => Contact.fromJson(json)).toList());
    }
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_contacts.map((c) => c.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> addContact(Contact contact) async {
    _contacts.add(contact);
    await _saveContacts();
  }

  Future<void> updateContact(String id, Contact updatedContact) async {
    final index = _contacts.indexWhere((contact) => contact.id == id);
    if (index != -1) {
      _contacts[index] = updatedContact;
      await _saveContacts();
    }
  }

  Future<void> deleteContact(String id) async {
    _contacts.removeWhere((contact) => contact.id == id);
    await _saveContacts();
  }
}
