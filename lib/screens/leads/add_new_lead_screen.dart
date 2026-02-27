import 'package:flutter/material.dart';
import '../../services/service_manager.dart';
import '../../managers/lead_manager.dart';
import '../../models/lead.dart';

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
  String? _selectedContact;
  String? _selectedService;
  DateTime? _followUpDate;
  TimeOfDay? _followUpTime;
  bool _showContactForm = false;
  final _serviceManager = ServiceManager();
  final _leadManager = LeadManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('New Lead', style: TextStyle(color: Colors.black, fontFamily: 'Inter', fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
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
              const Text('Create a new lead and attach to an existing or new contact.', style: TextStyle(color: Colors.grey, fontSize: 13, fontFamily: 'Inter')),
              const SizedBox(height: 24),
              RichText(
                text: const TextSpan(
                  text: 'Contact ',
                  style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                  children: [TextSpan(text: '*', style: TextStyle(color: Colors.red))],
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedContact,
                style: const TextStyle(fontFamily: 'Inter', color: Colors.black, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Select Contact or Add New',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Inter'),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: const [
                  DropdownMenuItem(value: 'add_new', child: Text('Add New Contact', style: TextStyle(fontFamily: 'Inter'))),
                  DropdownMenuItem(value: 'select', child: Text('Select or Add New', style: TextStyle(fontFamily: 'Inter'))),
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
                const Text('Name', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Inter'),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Email', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Inter'),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Contact Number', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                const SizedBox(height: 8),
                TextField(
                  controller: _contactNumber1Controller,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Primary Contact Number',
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Inter'),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Contact Number 2', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                const SizedBox(height: 8),
                TextField(
                  controller: _contactNumber2Controller,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Alternate Contact Number',
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Inter'),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Address', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                const SizedBox(height: 8),
                TextField(
                  controller: _addressController,
                  maxLines: 3,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Address',
                    prefixIcon: const Padding(padding: EdgeInsets.only(bottom: 40), child: Icon(Icons.location_on_outlined, size: 20)),
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Inter'),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Country', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    hintText: 'Select Country',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Inter'),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Australia', child: Text('Australia', style: TextStyle(fontFamily: 'Inter'))),
                    DropdownMenuItem(value: 'Canada', child: Text('Canada', style: TextStyle(fontFamily: 'Inter'))),
                    DropdownMenuItem(value: 'United Kingdom', child: Text('United Kingdom', style: TextStyle(fontFamily: 'Inter'))),
                    DropdownMenuItem(value: 'United States', child: Text('United States', style: TextStyle(fontFamily: 'Inter'))),
                    DropdownMenuItem(value: 'Other', child: Text('Other', style: TextStyle(fontFamily: 'Inter'))),
                  ],
                  onChanged: (value) {},
                ),
                const SizedBox(height: 20),
                const Text('State', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                const SizedBox(height: 8),
                TextField(
                  controller: _stateController,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'State',
                    prefixIcon: const Icon(Icons.map_outlined, size: 20),
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Inter'),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('City', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                const SizedBox(height: 8),
                TextField(
                  controller: _cityController,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'City',
                    prefixIcon: const Icon(Icons.location_city_outlined, size: 20),
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Inter'),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Zip', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                const SizedBox(height: 8),
                TextField(
                  controller: _zipController,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Zip Code',
                    prefixIcon: const Icon(Icons.pin_outlined, size: 20),
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Inter'),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const Text('Service Interested in', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedService,
                style: const TextStyle(fontFamily: 'Inter', color: Colors.black, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Select Service',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Inter'),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: _serviceManager.services
                    .map((service) => DropdownMenuItem(
                          value: service,
                          child: Text(service, style: const TextStyle(fontFamily: 'Inter')),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedService = value),
              ),
              const SizedBox(height: 20),
              const Text('Tags', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
              const SizedBox(height: 8),
              TextField(
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Add tags...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Inter'),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Notes', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 4,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Description or Notes',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Inter'),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Follow-up Date', style: TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
                  if (date != null) setState(() => _followUpDate = date);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Text(_followUpDate != null ? '${_followUpDate!.day}/${_followUpDate!.month}/${_followUpDate!.year}' : '', style: const TextStyle(fontSize: 14, fontFamily: 'Inter')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Follow-up Time', style: TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (time != null) setState(() => _followUpTime = time);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Text(_followUpTime != null ? _followUpTime!.format(context) : '--:--', style: const TextStyle(fontSize: 14, fontFamily: 'Inter')),
                      const Spacer(),
                      Icon(Icons.watch_later_outlined, size: 18, color: Colors.grey[600]),
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('Create Lead', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Inter')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createLead() {
    if (_selectedContact == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a contact')),
      );
      return;
    }

    final lead = Lead(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      contactName: _showContactForm ? _nameController.text : _selectedContact!,
      email: _showContactForm ? _emailController.text : null,
      phone: _showContactForm ? _contactNumber1Controller.text : null,
      service: _selectedService,
      notes: _notesController.text,
      followUpDate: _followUpDate,
      followUpTime: _followUpTime?.format(context),
      createdAt: DateTime.now(),
    );

    _leadManager.addLead(lead);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lead created successfully!')),
    );
    Navigator.pop(context);
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
    super.dispose();
  }
}
