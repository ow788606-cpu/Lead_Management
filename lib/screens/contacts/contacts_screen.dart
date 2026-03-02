import 'package:flutter/material.dart';
import 'all_contacts_screen.dart';
import 'new_contact_screen.dart';
import 'bulk_upload_screen.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('Contacts',
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          bottom: const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: 'All Contacts'),
              Tab(text: 'New Contact'),
              Tab(text: 'Bulk Upload'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AllContactsScreen(),
            NewContactScreen(),
            BulkUploadScreen(),
          ],
        ),
      ),
    );
  }
}
