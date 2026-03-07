// ignore_for_file: unnecessary_const

import 'package:flutter/material.dart';
import '../../managers/contact_manager.dart';
import '../../managers/auth_manager.dart';
import '../../models/contact.dart';
import '../../services/service_manager.dart';
import '../../managers/lead_manager.dart';
import '../../widgets/app_drawer.dart';

class AddNewLeadScreen extends StatefulWidget {
  const AddNewLeadScreen({super.key});

  @override
  State<AddNewLeadScreen> createState() => _AddNewLeadScreenState();
}

class _AddNewLeadScreenState extends State<AddNewLeadScreen> {
  final _notesController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactNumber1Controller = TextEditingController();
  final _contactNumber2Controller = TextEditingController();
  final _addressController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  final _serviceController = TextEditingController();
  final _tagsController = TextEditingController();
  String? _selectedContact;
  String? _selectedService;
  String? _selectedCountry;
  DateTime? _followUpDate;
  TimeOfDay? _followUpTime;
  bool _showContactForm = false;
  bool _isSaving = false;
  bool _isLoadingDependencies = true;
  String? _dependencyError;
  final _serviceManager = ServiceManager();
  final _leadManager = LeadManager();
  final _contactManager = ContactManager();

  @override
  void initState() {
    super.initState();
    _loadDependencies();
  }

  Future<void> _loadDependencies() async {
    setState(() {
      _isLoadingDependencies = true;
      _dependencyError = null;
    });

    try {
      await Future.wait([
        _serviceManager.refreshServices(),
        _contactManager.loadContacts(forceRefresh: true),
      ]);
    } catch (e) {
      _dependencyError = e.toString().replaceFirst('Exception: ', '');
    }

    if (!mounted) return;
    setState(() => _isLoadingDependencies = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: AppDrawer(
        selectedIndex: 1,
        onItemSelected: (_) => Navigator.pop(context),
      ),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Cloop'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _isLoadingDependencies
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            : _dependencyError != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('New Lead',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter')),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _dependencyError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadDependencies,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('New Lead',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter')),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
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
                            const SizedBox(height: 4),
                            const Text(
                                'Create a new lead and attach to an existing or new contact.',
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                    fontFamily: 'Inter')),
                            const SizedBox(height: 24),
                            RichText(
                              text: const TextSpan(
                                text: 'Contact ',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Inter'),
                                children: [
                                  TextSpan(
                                      text: '*',
                                      style: TextStyle(color: Colors.red))
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedContact,
                              style: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: Colors.black,
                                  fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Select Contact or Add New',
                                hintStyle: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                    fontFamily: 'Inter'),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                              selectedItemBuilder: (context) => [
                                const Text('Add New Contact',
                                    style: TextStyle(fontFamily: 'Inter')),
                                ..._contactManager.allContacts.map(
                                  (contact) => Text(
                                    contact.name,
                                    style: const TextStyle(fontFamily: 'Inter'),
                                  ),
                                ),
                              ],
                              items: [
                                const DropdownMenuItem(
                                    value: 'add_new',
                                    child: Text('Add New Contact',
                                        style: TextStyle(fontFamily: 'Inter'))),
                                ..._contactManager.allContacts.map(
                                  (contact) => DropdownMenuItem(
                                    value: contact.id,
                                    child: Text(contact.name,
                                        style: const TextStyle(
                                            fontFamily: 'Inter')),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedContact = value;
                                  _showContactForm = value == 'add_new';
                                });
                              },
                            ),
                            if (_showContactForm) ...[
                              const SizedBox(height: 20),
                              const Text('Name',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Inter')),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _nameController,
                                style: const TextStyle(
                                    fontFamily: 'Inter', fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Full Name',
                                  prefixIcon: const Icon(Icons.person_outline,
                                      size: 20),
                                  hintStyle: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                      fontFamily: 'Inter'),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!)),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text('Email',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Inter')),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _emailController,
                                style: const TextStyle(
                                    fontFamily: 'Inter', fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Email',
                                  prefixIcon: const Icon(Icons.email_outlined,
                                      size: 20),
                                  hintStyle: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                      fontFamily: 'Inter'),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!)),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text('Contact Number',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Inter')),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _contactNumber1Controller,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(
                                    fontFamily: 'Inter', fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Primary Contact Number',
                                  prefixIcon: const Icon(Icons.phone_outlined,
                                      size: 20),
                                  hintStyle: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                      fontFamily: 'Inter'),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!)),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text('Contact Number 2',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Inter')),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _contactNumber2Controller,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(
                                    fontFamily: 'Inter', fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Alternate Contact Number',
                                  prefixIcon: const Icon(Icons.phone_outlined,
                                      size: 20),
                                  hintStyle: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                      fontFamily: 'Inter'),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!)),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text('Address',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Inter')),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _addressController,
                                maxLines: 3,
                                style: const TextStyle(
                                    fontFamily: 'Inter', fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Address',
                                  prefixIcon: const Padding(
                                      padding: EdgeInsets.only(bottom: 40),
                                      child: Icon(Icons.location_on_outlined,
                                          size: 20)),
                                  hintStyle: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                      fontFamily: 'Inter'),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!)),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!)),
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text('Country',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Inter')),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  hintText: 'Select Country',
                                  hintStyle: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                      fontFamily: 'Inter'),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!)),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'Australia',
                                      child: Text('Australia',
                                          style:
                                              TextStyle(fontFamily: 'Inter'))),
                                  DropdownMenuItem(
                                      value: 'Canada',
                                      child: Text('Canada',
                                          style:
                                              TextStyle(fontFamily: 'Inter'))),
                                  DropdownMenuItem(
                                      value: 'United Kingdom',
                                      child: Text('United Kingdom',
                                          style:
                                              TextStyle(fontFamily: 'Inter'))),
                                  DropdownMenuItem(
                                      value: 'United States',
                                      child: Text('United States',
                                          style:
                                              TextStyle(fontFamily: 'Inter'))),
                                  DropdownMenuItem(
                                      value: 'Other',
                                      child: Text('Other',
                                          style:
                                              TextStyle(fontFamily: 'Inter'))),
                                ],
                                onChanged: (value) =>
                                    setState(() => _selectedCountry = value),
                              ),
                              const SizedBox(height: 20),
                              const Text('State',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Inter')),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _stateController,
                                style: const TextStyle(
                                    fontFamily: 'Inter', fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'State',
                                  prefixIcon:
                                      const Icon(Icons.map_outlined, size: 20),
                                  hintStyle: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                      fontFamily: 'Inter'),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!)),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text('City',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Inter')),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _cityController,
                                style: const TextStyle(
                                    fontFamily: 'Inter', fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'City',
                                  prefixIcon: const Icon(
                                      Icons.location_city_outlined,
                                      size: 20),
                                  hintStyle: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                      fontFamily: 'Inter'),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!)),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text('Zip',
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Inter')),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _zipController,
                                style: const TextStyle(
                                    fontFamily: 'Inter', fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Zip Code',
                                  prefixIcon:
                                      const Icon(Icons.pin_outlined, size: 20),
                                  hintStyle: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                      fontFamily: 'Inter'),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!)),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide:
                                          BorderSide(color: Colors.grey[300]!)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            const Text('Service Interested in',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Inter')),
                            const SizedBox(height: 8),
                            Autocomplete<String>(
                              optionsBuilder: (textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return _serviceManager.services;
                                }
                                return _serviceManager.services.where(
                                    (service) => service.toLowerCase().contains(
                                        textEditingValue.text.toLowerCase()));
                              },
                              onSelected: (value) =>
                                  setState(() => _selectedService = value),
                              fieldViewBuilder: (context, controller, focusNode,
                                  onEditingComplete) {
                                _serviceController.text = controller.text;
                                return TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  style: const TextStyle(
                                      fontFamily: 'Inter', fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'Type or select service',
                                    hintStyle: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                        fontFamily: 'Inter'),
                                    suffixIcon:
                                        const Icon(Icons.arrow_drop_down),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: Colors.grey[300]!)),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: Colors.grey[300]!)),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                  ),
                                  onChanged: (value) =>
                                      setState(() => _selectedService = value),
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            const Text('Tags',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Inter')),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _tagsController,
                              style: const TextStyle(
                                  fontFamily: 'Inter', fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Add tags...',
                                hintStyle: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                    fontFamily: 'Inter'),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text('Notes',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Inter')),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _notesController,
                              maxLines: 4,
                              style: const TextStyle(
                                  fontFamily: 'Inter', fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Description or Notes',
                                hintStyle: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                    fontFamily: 'Inter'),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Colors.grey[300]!)),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text('Follow-up Date',
                                style: TextStyle(
                                    color: const Color(0xFF0B5CFF),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Inter')),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2100));
                                if (date != null) {
                                  setState(() => _followUpDate = date);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        size: 18, color: Colors.grey[600]),
                                    const SizedBox(width: 12),
                                    Text(
                                        _followUpDate != null
                                            ? '${_followUpDate!.day}/${_followUpDate!.month}/${_followUpDate!.year}'
                                            : '',
                                        style: const TextStyle(
                                            fontSize: 14, fontFamily: 'Inter')),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text('Follow-up Time',
                                style: TextStyle(
                                    color: const Color(0xFF0B5CFF),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Inter')),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now());
                                if (time != null) {
                                  setState(() => _followUpTime = time);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  children: [
                                    Icon(Icons.access_time,
                                        size: 18, color: Colors.grey[600]),
                                    const SizedBox(width: 12),
                                    Text(
                                        _followUpTime != null
                                            ? _followUpTime!.format(context)
                                            : '--:--',
                                        style: const TextStyle(
                                            fontSize: 14, fontFamily: 'Inter')),
                                    const Spacer(),
                                    Icon(Icons.watch_later_outlined,
                                        size: 18, color: Colors.grey[600]),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _createLead,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0B5CFF),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8))),
                                child: const Text('Create Lead',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        fontFamily: 'Inter')),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  DateTime? _combineFollowUpDateTime() {
    if (_followUpDate == null) return null;
    final time = _followUpTime ?? const TimeOfDay(hour: 0, minute: 0);
    return DateTime(
      _followUpDate!.year,
      _followUpDate!.month,
      _followUpDate!.day,
      time.hour,
      time.minute,
    );
  }

  Future<void> _createLead() async {
    if (_isSaving) return;

    if (_selectedContact == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a contact')),
      );
      return;
    }

    if (_showContactForm &&
        (_nameController.text.trim().isEmpty ||
            _contactNumber1Controller.text.trim().isEmpty ||
            _addressController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Name, contact number and address are required')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final normalizedService = _selectedService?.trim();
      final userId = await AuthManager().getUserId() ?? 0;
      if (normalizedService != null &&
          normalizedService.isNotEmpty &&
          !_serviceManager.services.contains(normalizedService)) {
        await _serviceManager.addService(
          normalizedService,
          userId: userId > 0 ? userId : 1,
        );
      }

      String contactId = _selectedContact!;
      if (_showContactForm) {
        final contact = Contact(
          id: '',
          name: _nameController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          phone: _contactNumber1Controller.text.trim(),
          phone2: _contactNumber2Controller.text.trim().isEmpty
              ? null
              : _contactNumber2Controller.text.trim(),
          address: _addressController.text.trim(),
          country: _selectedCountry,
          state: _stateController.text.trim().isEmpty
              ? null
              : _stateController.text.trim(),
          city: _cityController.text.trim().isEmpty
              ? null
              : _cityController.text.trim(),
          zip: _zipController.text.trim().isEmpty
              ? null
              : _zipController.text.trim(),
          remark: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          createdAt: DateTime.now(),
        );
        contactId = await _contactManager.addContact(contact);
      }

      await _leadManager.createLead(
        contactId: contactId,
        serviceName: normalizedService,
        tags: _tagsController.text,
        description: _notesController.text,
        nextFollowUpAt: _combineFollowUpDateTime(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lead created successfully!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _contactNumber1Controller.dispose();
    _contactNumber2Controller.dispose();
    _addressController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _serviceController.dispose();
    _tagsController.dispose();
    super.dispose();
  }
}
