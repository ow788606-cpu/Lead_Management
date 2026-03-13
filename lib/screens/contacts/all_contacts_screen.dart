import 'package:flutter/material.dart';
import '../../managers/contact_manager.dart';
import '../../widgets/app_drawer.dart';
import 'view_contact_screen.dart';

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
      backgroundColor: const Color(0xFFF5F5F5),
      drawer: AppDrawer(
        selectedIndex: 3,
        onItemSelected: (_) => Navigator.pop(context),
      ),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('All Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search contacts by name, phone, email, location...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
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
                                      border:
                                          Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                              const Icon(Icons.phone_outlined,
                                                  size: 16, color: Colors.grey),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                    contact.phone,
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
                                                const Icon(
                                                    Icons.phone_forwarded_outlined,
                                                    size: 16,
                                                    color: Colors.grey),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                      contact.phone2!,
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
                                                const Icon(
                                                    Icons.email_outlined,
                                                    size: 16,
                                                    color: Colors.grey),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                      contact.email!,
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
                                                const Icon(
                                                    Icons.location_on_outlined,
                                                    size: 16,
                                                    color: Colors.grey),
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
          ],
        ),
      ),
    );
  }
}
