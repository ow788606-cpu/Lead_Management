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
        body: Column(
          children: [
            Container(
              color: Colors.white,
              child: const TabBar(
                labelColor: Color(0xFF131416),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFF131416),
                tabs: [
                  Tab(text: 'All Contacts'),
                  Tab(text: 'New Contact'),
                  Tab(text: 'Bulk Upload'),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  AllContactsScreen(),
                  NewContactScreen(),
                  BulkUploadScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
