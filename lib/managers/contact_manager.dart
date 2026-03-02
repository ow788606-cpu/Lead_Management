import '../models/contact.dart';

class ContactManager {
  static final ContactManager _instance = ContactManager._internal();
  factory ContactManager() => _instance;
  ContactManager._internal();

  final List<Contact> _contacts = [];

  List<Contact> get allContacts => _contacts;

  void addContact(Contact contact) {
    _contacts.add(contact);
  }

  void deleteContact(String id) {
    _contacts.removeWhere((contact) => contact.id == id);
  }
}
