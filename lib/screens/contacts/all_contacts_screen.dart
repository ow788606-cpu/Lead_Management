import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../managers/contact_manager.dart';
import '../../widgets/app_drawer.dart';
import 'view_contact_screen.dart';
import 'add_contact_screen.dart';

class AllContactsScreen extends StatefulWidget {
  const AllContactsScreen({super.key});

  @override
  State<AllContactsScreen> createState() => _AllContactsScreenState();
}

class _AllContactsScreenState extends State<AllContactsScreen> {
  final _contactManager = ContactManager();
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _contactManager.loadContacts(forceRefresh: true);
    } catch (e) {
      _error = e.toString();
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final contacts = _contactManager.allContacts;
    final filteredContacts = contacts.where((contact) {
      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return contact.name.toLowerCase().contains(q) ||
          contact.phone.toLowerCase().contains(q) ||
          (contact.phone2?.toLowerCase().contains(q) ?? false) ||
          (contact.email?.toLowerCase().contains(q) ?? false) ||
          (contact.city?.toLowerCase().contains(q) ?? false) ||
          (contact.state?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add New Contact',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddContactScreen()),
          ).then((result) {
            if (result == true) _loadContacts();
          });
        },
        child: const Icon(Icons.add),
      ),
      drawer: AppDrawer(
        selectedIndex: 3,
        onItemSelected: (_) => Navigator.pop(context),
      ),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('All Contacts'),
        actions: [
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedNotification03,
              color: Colors.black,
              size: 24.0,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedSearch01,
                      color: Colors.grey,
                      size: 20.0,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: const InputDecoration(
                        hintText: 'Search',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedFilterHorizontal,
                        color: Colors.grey,
                        size: 20.0,
                      ),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF4F6FA),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                              fontFamily: 'Inter',
                            ),
                          ),
                        )
                      : filteredContacts.isEmpty
                          ? const Center(
                              child: Text('No contacts found.',
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                      fontFamily: 'Inter')))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredContacts.length,
                              itemBuilder: (context, index) {
                                final contact = filteredContacts[index];
                                return InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ViewContactScreen(contact: contact),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
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
                                        Text(contact.name,
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Inter')),
                                        const SizedBox(height: 12),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8),
                                          child: Row(
                                            children: [
                                              const HugeIcon(
                                                icon: HugeIcons.strokeRoundedCall,
                                                color: Colors.grey,
                                                size: 16.0,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(contact.phone,
                                                    style: const TextStyle(
                                                        fontSize: 14,
                                                        fontFamily: 'Inter',
                                                        color: Colors.black87)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (contact.phone2 != null) ...[
                                          const SizedBox(height: 8),
                                          Padding(
                                            padding: const EdgeInsets.only(left: 8),
                                            child: Row(
                                              children: [
                                                const HugeIcon(
                                                  icon: HugeIcons.strokeRoundedCall,
                                                  color: Colors.grey,
                                                  size: 16.0,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(contact.phone2!,
                                                      style: const TextStyle(
                                                          fontSize: 14,
                                                          fontFamily: 'Inter',
                                                          color: Colors.black87)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        if (contact.email != null) ...[
                                          const SizedBox(height: 8),
                                          Padding(
                                            padding: const EdgeInsets.only(left: 8),
                                            child: Row(
                                              children: [
                                                const HugeIcon(
                                                  icon: HugeIcons.strokeRoundedMail01,
                                                  color: Colors.grey,
                                                  size: 16.0,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(contact.email!,
                                                      style: const TextStyle(
                                                          fontSize: 14,
                                                          fontFamily: 'Inter',
                                                          color: Colors.black87)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        if (contact.city != null ||
                                            contact.state != null) ...[
                                          const SizedBox(height: 8),
                                          Padding(
                                            padding: const EdgeInsets.only(left: 8),
                                            child: Row(
                                              children: [
                                                const HugeIcon(
                                                  icon: HugeIcons.strokeRoundedLocation01,
                                                  color: Colors.grey,
                                                  size: 16.0,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                      '${contact.city ?? ''}${contact.city != null && contact.state != null ? ', ' : ''}${contact.state ?? ''}',
                                                      style: const TextStyle(
                                                          fontSize: 14,
                                                          fontFamily: 'Inter',
                                                          color: Colors.black87)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}
