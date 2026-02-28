import 'package:flutter/material.dart';
import '../../models/lead.dart';
import '../../managers/lead_manager.dart';
import '../../services/service_manager.dart';

class DetailLeadScreen extends StatefulWidget {
  final Lead lead;

  const DetailLeadScreen({super.key, required this.lead});

  @override
  State<DetailLeadScreen> createState() => _DetailLeadScreenState();
}

class _DetailLeadScreenState extends State<DetailLeadScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;
  late TextEditingController _tagsController;
  late TextEditingController _addressController;
  late TextEditingController _stateController;
  late TextEditingController _cityController;
  late TextEditingController _zipController;
  String? _selectedService;
  String? _selectedCountry;
  DateTime? _followUpDate;
  TimeOfDay? _followUpTime;
  final _serviceManager = ServiceManager();
  final _leadManager = LeadManager();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.lead.contactName);
    _emailController = TextEditingController(text: widget.lead.email ?? '');
    _phoneController = TextEditingController(text: widget.lead.phone ?? '');
    _notesController = TextEditingController(text: widget.lead.notes ?? '');
    _tagsController = TextEditingController(text: widget.lead.tags ?? '');
    _addressController = TextEditingController(text: widget.lead.address ?? '');
    _stateController = TextEditingController(text: widget.lead.state ?? '');
    _cityController = TextEditingController(text: widget.lead.city ?? '');
    _zipController = TextEditingController(text: widget.lead.zip ?? '');
    _selectedService = widget.lead.service;
    _selectedCountry = widget.lead.country;
    _followUpDate = widget.lead.followUpDate;
    if (widget.lead.followUpTime != null) {
      final parts = widget.lead.followUpTime!.split(':');
      if (parts.length == 2) {
        _followUpTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1].split(' ')[0]));
      }
    }
  }

  void _saveChanges() {
    final updatedLead = Lead(
      id: widget.lead.id,
      contactName: _nameController.text,
      email: _emailController.text.isEmpty ? null : _emailController.text,
      phone: _phoneController.text.isEmpty ? null : _phoneController.text,
      service: _selectedService,
      tags: _tagsController.text.isEmpty ? null : _tagsController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      address: _addressController.text.isEmpty ? null : _addressController.text,
      country: _selectedCountry,
      state: _stateController.text.isEmpty ? null : _stateController.text,
      city: _cityController.text.isEmpty ? null : _cityController.text,
      zip: _zipController.text.isEmpty ? null : _zipController.text,
      followUpDate: _followUpDate,
      followUpTime: _followUpTime?.format(context),
      createdAt: widget.lead.createdAt,
      isCompleted: widget.lead.isCompleted,
    );

    _leadManager.updateLead(widget.lead.id, updatedLead);
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lead updated successfully!')),
    );
  }

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
        title: Text(_isEditing ? 'Edit Lead' : 'Lead Details',
            style: const TextStyle(
                color: Colors.black,
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon:
                Icon(_isEditing ? Icons.save : Icons.edit, color: Colors.blue),
            onPressed: () {
              if (_isEditing) {
                _saveChanges();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
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
              _buildField('Name', _nameController, Icons.person_outline),
              const SizedBox(height: 20),
              _buildField('Email', _emailController, Icons.email_outlined),
              const SizedBox(height: 20),
              _buildField('Phone', _phoneController, Icons.phone_outlined),
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
                enabled: _isEditing,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                decoration: InputDecoration(
                  prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(Icons.location_on_outlined, size: 20)),
                  filled: true,
                  fillColor: _isEditing ? Colors.white : Colors.grey[100],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!)),
                  disabledBorder: OutlineInputBorder(
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
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter')),
              const SizedBox(height: 8),
              _isEditing
                  ? DropdownButtonFormField<String>(
                      initialValue: _selectedCountry,
                      decoration: InputDecoration(
                        hintText: 'Select Country',
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
                            value: 'Australia',
                            child: Text('Australia',
                                style: TextStyle(fontFamily: 'Inter'))),
                        DropdownMenuItem(
                            value: 'Canada',
                            child: Text('Canada',
                                style: TextStyle(fontFamily: 'Inter'))),
                        DropdownMenuItem(
                            value: 'United Kingdom',
                            child: Text('United Kingdom',
                                style: TextStyle(fontFamily: 'Inter'))),
                        DropdownMenuItem(
                            value: 'United States',
                            child: Text('United States',
                                style: TextStyle(fontFamily: 'Inter'))),
                        DropdownMenuItem(
                            value: 'Other',
                            child: Text('Other',
                                style: TextStyle(fontFamily: 'Inter'))),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedCountry = value),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(_selectedCountry ?? 'N/A',
                          style: const TextStyle(
                              fontFamily: 'Inter', fontSize: 14)),
                    ),
              const SizedBox(height: 20),
              _buildField('State', _stateController, Icons.map_outlined),
              const SizedBox(height: 20),
              _buildField(
                  'City', _cityController, Icons.location_city_outlined),
              const SizedBox(height: 20),
              _buildField('Zip', _zipController, Icons.pin_outlined),
              const SizedBox(height: 20),
              const Text('Service',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter')),
              const SizedBox(height: 8),
              _isEditing
                  ? Autocomplete<String>(
                      initialValue:
                          TextEditingValue(text: _selectedService ?? ''),
                      optionsBuilder: (textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return _serviceManager.services;
                        }
                        return _serviceManager.services.where((service) =>
                            service
                                .toLowerCase()
                                .contains(textEditingValue.text.toLowerCase()));
                      },
                      onSelected: (value) =>
                          setState(() => _selectedService = value),
                      fieldViewBuilder:
                          (context, controller, focusNode, onEditingComplete) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          style: const TextStyle(
                              fontFamily: 'Inter', fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Type or select service',
                            suffixIcon: const Icon(Icons.arrow_drop_down),
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
                          onChanged: (value) =>
                              setState(() => _selectedService = value),
                        );
                      },
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(_selectedService ?? 'N/A',
                          style: const TextStyle(
                              fontFamily: 'Inter', fontSize: 14)),
                    ),
              const SizedBox(height: 20),
              _buildField('Tags', _tagsController, Icons.label_outline),
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
                enabled: _isEditing,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Description or Notes',
                  filled: true,
                  fillColor: _isEditing ? Colors.white : Colors.grey[100],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!)),
                  disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!)),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Follow-up Date',
                  style: TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter')),
              const SizedBox(height: 8),
              InkWell(
                onTap: _isEditing
                    ? () async {
                        final date = await showDatePicker(
                            context: context,
                            initialDate: _followUpDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100));
                        if (date != null) setState(() => _followUpDate = date);
                      }
                    : null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _isEditing ? Colors.white : Colors.grey[100],
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Text(
                          _followUpDate != null
                              ? '${_followUpDate!.day}/${_followUpDate!.month}/${_followUpDate!.year}'
                              : 'N/A',
                          style: const TextStyle(
                              fontSize: 14, fontFamily: 'Inter')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Follow-up Time',
                  style: TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter')),
              const SizedBox(height: 8),
              InkWell(
                onTap: _isEditing
                    ? () async {
                        final time = await showTimePicker(
                            context: context,
                            initialTime: _followUpTime ?? TimeOfDay.now());
                        if (time != null) setState(() => _followUpTime = time);
                      }
                    : null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _isEditing ? Colors.white : Colors.grey[100],
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Text(
                          _followUpTime != null
                              ? _followUpTime!.format(context)
                              : 'N/A',
                          style: const TextStyle(
                              fontSize: 14, fontFamily: 'Inter')),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
      String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter')),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: _isEditing,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: _isEditing ? Colors.white : Colors.grey[100],
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!)),
            disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    _addressController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    super.dispose();
  }
}
