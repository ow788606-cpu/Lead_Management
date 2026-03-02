import 'package:flutter/material.dart';
import '../../managers/contact_manager.dart';
import 'view_contact_screen.dart';

class AllContactsScreen extends StatefulWidget {
  const AllContactsScreen({super.key});

  @override
  State<AllContactsScreen> createState() => _AllContactsScreenState();
}

class _AllContactsScreenState extends State<AllContactsScreen> {
  final _contactManager = ContactManager();

  @override
  Widget build(BuildContext context) {
    final contacts = _contactManager.allContacts;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('All Contacts',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter')),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.blue),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: contacts.isEmpty
            ? const Center(
                child: Text('No contacts found.',
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontFamily: 'Inter')))
            : ListView.builder(
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(contact.name,
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Inter')),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.visibility_outlined,
                                            color: Colors.blue, size: 20),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ViewContactScreen(contact: contact),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Phone: ${contact.phone}',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Inter',
                                          color: Colors.grey)),
                                  if (contact.phone2 != null)
                                    Text('Phone 2: ${contact.phone2}',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Inter',
                                            color: Colors.grey)),
                                  if (contact.email != null)
                                    Text('Email: ${contact.email}',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Inter',
                                            color: Colors.grey)),
                                  if (contact.city != null ||
                                      contact.state != null)
                                    Text(
                                        'Location: ${contact.city ?? ''}${contact.city != null && contact.state != null ? ', ' : ''}${contact.state ?? ''}',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Inter',
                                            color: Colors.grey)),
                                ],
                              ),
                            );
                          },
                        ),
      ),
    );
  }
}
