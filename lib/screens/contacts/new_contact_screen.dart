import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../managers/contact_manager.dart';
import '../../models/contact.dart';
import '../../widgets/app_drawer.dart';
import '../../utils/responsive_helper.dart';

class NewContactScreen extends StatefulWidget {
  const NewContactScreen({super.key});

  @override
  State<NewContactScreen> createState() => _NewContactScreenState();
}

class _NewContactScreenState extends State<NewContactScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactNumber1Controller = TextEditingController();
  final _contactNumber2Controller = TextEditingController();
  final _addressController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  final _leadSourceController = TextEditingController();
  final _remarkController = TextEditingController();
  final _contactManager = ContactManager();

  void _addContact() async {
    if (_nameController.text.isEmpty ||
        _contactNumber1Controller.text.isEmpty ||
        _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields')),
      );
      return;
    }

    final contact = Contact(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      email: _emailController.text.isEmpty ? null : _emailController.text,
      phone: _contactNumber1Controller.text,
      phone2: _contactNumber2Controller.text.isEmpty
          ? null
          : _contactNumber2Controller.text,
      address: _addressController.text,
      state: _stateController.text.isEmpty ? null : _stateController.text,
      city: _cityController.text.isEmpty ? null : _cityController.text,
      zip: _zipController.text.isEmpty ? null : _zipController.text,
      leadSource: _leadSourceController.text.isEmpty
          ? null
          : _leadSourceController.text,
      remark: _remarkController.text.isEmpty ? null : _remarkController.text,
      createdAt: DateTime.now(),
    );

    await _contactManager.addContact(contact);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact added successfully')),
    );

    _nameController.clear();
    _emailController.clear();
    _contactNumber1Controller.clear();
    _contactNumber2Controller.clear();
    _addressController.clear();
    _stateController.clear();
    _cityController.clear();
    _zipController.clear();
    _leadSourceController.clear();
    _remarkController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
        title: const Text('New Contact'),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              EdgeInsets.all(ResponsiveHelper.getHorizontalSpacing(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    EdgeInsets.all(ResponsiveHelper.getPadding(context).left),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: ResponsiveHelper.getBorderRadius(context),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // const Text('New contact', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    // const SizedBox(height: 4),
                    // const Text('Create a new contact profile.',
                    //     style: TextStyle(color: Colors.grey, fontSize: 13)),
                    // const SizedBox(height: 24),
                    RichText(
                      text: const TextSpan(
                        text: 'Name ',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter'),
                        children: [
                          TextSpan(
                              text: '*', style: TextStyle(color: Colors.red))
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Full Name',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.person_outline,
                            size: ResponsiveHelper.getIconSize(context,
                                mobile: 20, tablet: 22, desktop: 24),
                            color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius:
                                ResponsiveHelper.getBorderRadius(context),
                            borderSide: BorderSide(color: Colors.grey[300]!)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius:
                                ResponsiveHelper.getBorderRadius(context),
                            borderSide: BorderSide(color: Colors.grey[300]!)),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal:
                                ResponsiveHelper.getHorizontalSpacing(context),
                            vertical:
                                ResponsiveHelper.getVerticalSpacing(context) *
                                    0.8),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Email',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    SizedBox(
                        height: ResponsiveHelper.getVerticalSpacing(context) *
                            1.25),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.email_outlined,
                            size: ResponsiveHelper.getIconSize(context,
                                mobile: 20, tablet: 22, desktop: 24),
                            color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius:
                                ResponsiveHelper.getBorderRadius(context),
                            borderSide: BorderSide(color: Colors.grey[300]!)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius:
                                ResponsiveHelper.getBorderRadius(context),
                            borderSide: BorderSide(color: Colors.grey[300]!)),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal:
                                ResponsiveHelper.getHorizontalSpacing(context),
                            vertical:
                                ResponsiveHelper.getVerticalSpacing(context) *
                                    0.8),
                      ),
                    ),
                    const SizedBox(height: 20),
                    RichText(
                      text: const TextSpan(
                        text: 'Contact Number ',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter'),
                        children: [
                          TextSpan(
                              text: '*', style: TextStyle(color: Colors.red))
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _contactNumber1Controller,
                      decoration: InputDecoration(
                        hintText: 'Primary Contact Number',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.phone_outlined,
                            size: 20, color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Contact Number 2',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _contactNumber2Controller,
                      decoration: InputDecoration(
                        hintText: 'Alternate Contact Number',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.phone_outlined,
                            size: 20, color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 20),
                    RichText(
                      text: const TextSpan(
                        text: 'Address ',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter'),
                        children: [
                          TextSpan(
                              text: '*', style: TextStyle(color: Colors.red))
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _addressController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Address',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(bottom: 40),
                          child: Icon(Icons.location_on_outlined,
                              size: 20, color: Colors.grey[400]),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!)),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Country',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        hintText: 'Select Country',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'Australia', child: Text('Australia')),
                        DropdownMenuItem(
                            value: 'Canada', child: Text('Canada')),
                        DropdownMenuItem(
                            value: 'United Kingdom',
                            child: Text('United Kingdom')),
                        DropdownMenuItem(
                            value: 'United States',
                            child: Text('United States')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (value) {},
                    ),
                    const SizedBox(height: 20),
                    const Text('State',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _stateController,
                      decoration: InputDecoration(
                        hintText: 'State',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.map_outlined,
                            size: 20, color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('City',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        hintText: 'City',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.location_city_outlined,
                            size: 20, color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Zip',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _zipController,
                      decoration: InputDecoration(
                        hintText: 'Zip Code',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.pin_outlined,
                            size: 20, color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Lead Source',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _leadSourceController,
                      decoration: InputDecoration(
                        hintText: 'Lead Source (eg. Google, Referral)',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.source_outlined,
                            size: 20, color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Remark',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _remarkController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Remark',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(bottom: 50),
                          child: Icon(Icons.note_outlined,
                              size: 20, color: Colors.grey[400]),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!)),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _addContact,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF131416),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Add contact',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _contactNumber1Controller.dispose();
    _contactNumber2Controller.dispose();
    _addressController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _leadSourceController.dispose();
    _remarkController.dispose();
    super.dispose();
  }
}
