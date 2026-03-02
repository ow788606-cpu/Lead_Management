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

  void updateContact(String id, Contact updatedContact) {
    final index = _contacts.indexWhere((contact) => contact.id == id);
    if (index != -1) {
      _contacts[index] = updatedContact;
    }
  }

  void deleteContact(String id) {
    _contacts.removeWhere((contact) => contact.id == id);
  }
}
