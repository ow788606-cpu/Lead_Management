// ignore_for_file: deprecated_member_use, duplicate_ignore

import 'package:flutter/material.dart';
import '../../models/lead.dart';

class ViewLeadsScreen extends StatefulWidget {
  final Lead lead;

  const ViewLeadsScreen({super.key, required this.lead});

  @override
  State<ViewLeadsScreen> createState() => _ViewLeadsScreenState();
}

class _ViewLeadsScreenState extends State<ViewLeadsScreen> {
  int _selectedTab = 0;
  bool _isEditingService = false;
  bool _isEditingTags = false;
  late TextEditingController _serviceController;
  late TextEditingController _tagsController;
  final List<Map<String, dynamic>> _activities = [];
  final List<String> _notes = [];
  final List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _serviceController = TextEditingController(text: widget.lead.service ?? '');
    _tagsController = TextEditingController(text: widget.lead.tags ?? '');
  }

  @override
  void dispose() {
    _serviceController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _showAddTaskDialog() {
    final taskTitleController = TextEditingController();
    final taskNotesController = TextEditingController();
    String priority = 'Normal';
    final dueDateController = TextEditingController();
    final dueTimeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: StatefulBuilder(
            builder: (context, setDialogState) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Add New Task',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter')),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Task Title *',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: taskTitleController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Notes',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: taskNotesController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Priority',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter')),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: priority,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Low', child: Text('Low')),
                      DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                      DropdownMenuItem(value: 'High', child: Text('High')),
                      DropdownMenuItem(
                          value: 'Critical', child: Text('Critical')),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => priority = value!),
                  ),
                  const SizedBox(height: 16),
                  const Text('Due Time',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter')),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: dueDateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            hintText: '--:--',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                                context: context,
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100));
                            if (date != null) {
                              setDialogState(() => dueDateController.text =
                                  '${date.day}/${date.month}/${date.year}');
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: dueTimeController,
                          readOnly: true,
                          decoration: InputDecoration(
                            hintText: '--:--',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            suffixIcon: const Icon(Icons.access_time),
                          ),
                          onTap: () async {
                            final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now());
                            if (time != null) {
                              setDialogState(() => dueTimeController.text =
                                  time.format(context));
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (taskTitleController.text.isNotEmpty) {
                        setState(() {
                          _tasks.add({
                            'title': taskTitleController.text,
                            'notes': taskNotesController.text,
                            'priority': priority,
                            'dueDate': dueDateController.text,
                            'dueTime': dueTimeController.text,
                            'timestamp': DateTime.now(),
                          });
                        });
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Create Task',
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Inter',
                            fontSize: 14)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddNoteDialog() {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Notes',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter')),
              const SizedBox(height: 24),
              TextField(
                controller: noteController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Add your notes here...',
                  hintStyle: const TextStyle(fontStyle: FontStyle.italic),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    if (noteController.text.isNotEmpty) {
                      setState(() {
                        _notes.add(noteController.text);
                      });
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Add Note',
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Inter',
                          fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddActivityDialog() {
    String? selectedActivity;
    String? selectedCalledSubOption;
    String? lostReason;
    final remarkController = TextEditingController();
    final dateController = TextEditingController();
    final timeController = TextEditingController();
    final dealAmountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setDialogState) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Task Details',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter')),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Lead Activity *',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter')),
                  const SizedBox(height: 8),
                  // ignore: duplicate_ignore
                  // ignore: deprecated_member_use
                  RadioListTile<String>(
                    title: const Text('Called',
                        style: TextStyle(fontFamily: 'Inter')),
                    value: 'Called',
                    // ignore: duplicate_ignore
                    // ignore: deprecated_member_use
                    groupValue: selectedActivity,
                    // ignore: duplicate_ignore
                    // ignore: deprecated_member_use
                    onChanged: (value) =>
                        setDialogState(() => selectedActivity = value),
                  ),
                  if (selectedActivity == 'Called') ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 32),
                      child: Column(
                        children: [
                          // ignore: duplicate_ignore
                          // ignore: deprecated_member_use
                          RadioListTile<String>(
                            title: const Text('Appointment Scheduled',
                                style: TextStyle(fontFamily: 'Inter')),
                            value: 'Appointment Scheduled',
                            // ignore: deprecated_member_use
                            groupValue: selectedCalledSubOption,
                            // ignore: deprecated_member_use
                            onChanged: (value) => setDialogState(
                                () => selectedCalledSubOption = value),
                          ),
                          if (selectedCalledSubOption ==
                              'Appointment Scheduled') ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 16, right: 16, bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Appointment Date',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                          fontFamily: 'Inter')),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: dateController,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 12),
                                      suffixIcon:
                                          const Icon(Icons.calendar_today),
                                    ),
                                    onTap: () async {
                                      final date = await showDatePicker(
                                          context: context,
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime(2100));
                                      if (date != null) {
                                        setDialogState(() => dateController
                                                .text =
                                            '${date.day}/${date.month}/${date.year}');
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('Appointment Time',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                          fontFamily: 'Inter')),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: timeController,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      hintText: '--:--',
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 12),
                                      suffixIcon: const Icon(Icons.access_time),
                                    ),
                                    onTap: () async {
                                      final time = await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay.now());
                                      if (time != null) {
                                        setDialogState(() => timeController
                                            .text = time.format(context));
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                          // ignore: deprecated_member_use
                          RadioListTile<String>(
                            title: const Text('Call Later',
                                style: TextStyle(fontFamily: 'Inter')),
                            value: 'Call Later',
                            // ignore: deprecated_member_use
                            groupValue: selectedCalledSubOption,
                            // ignore: deprecated_member_use
                            onChanged: (value) => setDialogState(
                                () => selectedCalledSubOption = value),
                          ),
                          if (selectedCalledSubOption == 'Call Later') ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 16, right: 16, bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Call Later Date',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                          fontFamily: 'Inter')),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: dateController,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 12),
                                      suffixIcon:
                                          const Icon(Icons.calendar_today),
                                    ),
                                    onTap: () async {
                                      final date = await showDatePicker(
                                          context: context,
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime(2100));
                                      if (date != null) {
                                        setDialogState(() => dateController
                                                .text =
                                            '${date.day}/${date.month}/${date.year}');
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('Call Later Time',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                          fontFamily: 'Inter')),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: timeController,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      hintText: '--:--',
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 12),
                                      suffixIcon: const Icon(Icons.access_time),
                                    ),
                                    onTap: () async {
                                      final time = await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay.now());
                                      if (time != null) {
                                        setDialogState(() => timeController
                                            .text = time.format(context));
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                          // ignore: deprecated_member_use
                          RadioListTile<String>(
                            title: const Text('Ringing - No Response',
                                style: TextStyle(fontFamily: 'Inter')),
                            value: 'Ringing - No Response',
                            // ignore: deprecated_member_use
                            groupValue: selectedCalledSubOption,
                            // ignore: deprecated_member_use
                            onChanged: (value) => setDialogState(
                                () => selectedCalledSubOption = value),
                          ),
                          if (selectedCalledSubOption == 'Ringing - No Response') ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 16, right: 16, bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Ringing Date',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                          fontFamily: 'Inter')),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: dateController,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 12),
                                      suffixIcon:
                                          const Icon(Icons.calendar_today),
                                    ),
                                    onTap: () async {
                                      final date = await showDatePicker(
                                          context: context,
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime(2100));
                                      if (date != null) {
                                        setDialogState(() => dateController
                                                .text =
                                            '${date.day}/${date.month}/${date.year}');
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('Ringing Time',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                          fontFamily: 'Inter')),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: timeController,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      hintText: '--:--',
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 12),
                                      suffixIcon: const Icon(Icons.access_time),
                                    ),
                                    onTap: () async {
                                      final time = await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay.now());
                                      if (time != null) {
                                        setDialogState(() => timeController
                                            .text = time.format(context));
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                          // ignore: deprecated_member_use
                          RadioListTile<String>(
                            title: const Text('Busy',
                                style: TextStyle(fontFamily: 'Inter')),
                            value: 'Busy',
                            // ignore: deprecated_member_use
                            groupValue: selectedCalledSubOption,
                            // ignore: deprecated_member_use
                            onChanged: (value) => setDialogState(
                                () => selectedCalledSubOption = value),
                          ),
                          if (selectedCalledSubOption == 'Busy') ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 16, right: 16, bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Busy Date',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                          fontFamily: 'Inter')),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: dateController,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 12),
                                      suffixIcon:
                                          const Icon(Icons.calendar_today),
                                    ),
                                    onTap: () async {
                                      final date = await showDatePicker(
                                          context: context,
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime(2100));
                                      if (date != null) {
                                        setDialogState(() => dateController
                                                .text =
                                            '${date.day}/${date.month}/${date.year}');
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('Busy Time',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                          fontFamily: 'Inter')),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: timeController,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      hintText: '--:--',
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 12),
                                      suffixIcon: const Icon(Icons.access_time),
                                    ),
                                    onTap: () async {
                                      final time = await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay.now());
                                      if (time != null) {
                                        setDialogState(() => timeController
                                            .text = time.format(context));
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                          // ignore: deprecated_member_use
                          RadioListTile<String>(
                            title: const Text('Switched Off / Unavailable',
                                style: TextStyle(fontFamily: 'Inter')),
                            value: 'Switched Off / Unavailable',
                            // ignore: deprecated_member_use
                            groupValue: selectedCalledSubOption,
                            // ignore: deprecated_member_use
                            onChanged: (value) => setDialogState(
                                () => selectedCalledSubOption = value),
                          ),
                          if (selectedCalledSubOption == 'Switched Off / Unavailable') ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 16, right: 16, bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Switched Off Date',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                          fontFamily: 'Inter')),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: dateController,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 12),
                                      suffixIcon:
                                          const Icon(Icons.calendar_today),
                                    ),
                                    onTap: () async {
                                      final date = await showDatePicker(
                                          context: context,
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime(2100));
                                      if (date != null) {
                                        setDialogState(() => dateController
                                                .text =
                                            '${date.day}/${date.month}/${date.year}');
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('Switched Off Time',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                          fontFamily: 'Inter')),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: timeController,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      hintText: '--:--',
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 12),
                                      suffixIcon: const Icon(Icons.access_time),
                                    ),
                                    onTap: () async {
                                      final time = await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay.now());
                                      if (time != null) {
                                        setDialogState(() => timeController
                                            .text = time.format(context));
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                          // ignore: deprecated_member_use
                          RadioListTile<String>(
                            title: const Text('Invalid Number',
                                style: TextStyle(fontFamily: 'Inter')),
                            value: 'Invalid Number',
                            // ignore: deprecated_member_use
                            groupValue: selectedCalledSubOption,
                            // ignore: deprecated_member_use
                            onChanged: (value) => setDialogState(
                                () => selectedCalledSubOption = value),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // ignore: deprecated_member_use
                  RadioListTile<String>(
                    title: const Text('SMS Sent',
                        style: TextStyle(fontFamily: 'Inter')),
                    value: 'SMS Sent',
                    // ignore: deprecated_member_use
                    groupValue: selectedActivity,
                    onChanged: (value) =>
                        setDialogState(() => selectedActivity = value),
                  ),
                  if (selectedActivity == 'SMS Sent') ...[
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SMS Date',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontFamily: 'Inter')),
                          const SizedBox(height: 8),
                          TextField(
                            controller: dateController,
                            readOnly: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              suffixIcon: const Icon(Icons.calendar_today),
                            ),
                            onTap: () async {
                              final date = await showDatePicker(
                                  context: context,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2100));
                              if (date != null) {
                                setDialogState(() => dateController.text =
                                    '${date.day}/${date.month}/${date.year}');
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text('SMS Time',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontFamily: 'Inter')),
                          const SizedBox(height: 8),
                          TextField(
                            controller: timeController,
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: '--:--',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              suffixIcon: const Icon(Icons.access_time),
                            ),
                            onTap: () async {
                              final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now());
                              if (time != null) {
                                setDialogState(() =>
                                    timeController.text = time.format(context));
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  // ignore: deprecated_member_use
                  RadioListTile<String>(
                    title: const Text('Email Sent',
                        style: TextStyle(fontFamily: 'Inter')),
                    value: 'Email Sent',
                    groupValue: selectedActivity,
                    onChanged: (value) =>
                        setDialogState(() => selectedActivity = value),
                  ),
                  if (selectedActivity == 'Email Sent') ...[
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Email Date',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontFamily: 'Inter')),
                          const SizedBox(height: 8),
                          TextField(
                            controller: dateController,
                            readOnly: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              suffixIcon: const Icon(Icons.calendar_today),
                            ),
                            onTap: () async {
                              final date = await showDatePicker(
                                  context: context,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2100));
                              if (date != null) {
                                setDialogState(() => dateController.text =
                                    '${date.day}/${date.month}/${date.year}');
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text('Email Time',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontFamily: 'Inter')),
                          const SizedBox(height: 8),
                          TextField(
                            controller: timeController,
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: '--:--',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              suffixIcon: const Icon(Icons.access_time),
                            ),
                            onTap: () async {
                              final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now());
                              if (time != null) {
                                setDialogState(() =>
                                    timeController.text = time.format(context));
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  // ignore: deprecated_member_use
                  RadioListTile<String>(
                    title: const Text('Lead Lost',
                        style: TextStyle(fontFamily: 'Inter')),
                    value: 'Lead Lost',
                    groupValue: selectedActivity,
                    onChanged: (value) =>
                        setDialogState(() => selectedActivity = value),
                  ),
                  if (selectedActivity == 'Lead Lost') ...[
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Lost Reason',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontFamily: 'Inter')),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            decoration: InputDecoration(
                              hintText: 'Select reason',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'No Budget', child: Text('No Budget')),
                              DropdownMenuItem(
                                  value: 'Not Interested',
                                  child: Text('Not Interested')),
                              DropdownMenuItem(
                                  value: 'Postponed / Will decide later',
                                  child: Text('Postponed / Will decide later')),
                              DropdownMenuItem(
                                  value: 'No Response',
                                  child: Text('No Response')),
                              DropdownMenuItem(
                                  value: 'Bought service from someone else',
                                  child:
                                      Text('Bought service from someone else')),
                            ],
                            onChanged: (value) =>
                                setDialogState(() => lostReason = value),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // ignore: deprecated_member_use
                  RadioListTile<String>(
                    title: const Text('Lead Converted',
                        style: TextStyle(fontFamily: 'Inter')),
                    value: 'Lead Converted',
                    groupValue: selectedActivity,
                    onChanged: (value) =>
                        setDialogState(() => selectedActivity = value),
                  ),
                  if (selectedActivity == 'Lead Converted') ...[
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Deal Amount',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontFamily: 'Inter')),
                          const SizedBox(height: 8),
                          TextField(
                            controller: dealAmountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Enter Amount',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text('Remark *',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: remarkController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Enter remark...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (selectedActivity != null &&
                            remarkController.text.isNotEmpty) {
                          setState(() {
                            _activities.add({
                              'activity': selectedActivity == 'Called'
                                  ? selectedCalledSubOption
                                  : selectedActivity,
                              'remark': remarkController.text,
                              'date': dateController.text,
                              'time': timeController.text,
                              'lostReason': lostReason,
                              'dealAmount': dealAmountController.text,
                              'timestamp': DateTime.now(),
                            });
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Activity added successfully!')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Update',
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Inter',
                              fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
        title: const Text('Lead Details',
            style: TextStyle(
                color: Colors.black,
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to List',
                style: TextStyle(
                    color: Colors.blue, fontFamily: 'Inter', fontSize: 14)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
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
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.blue,
                    child: Text(
                      widget.lead.contactName[0].toUpperCase(),
                      style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.lead.contactName,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter'),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.lead.phone ?? '',
                    style: const TextStyle(
                        fontSize: 14, color: Colors.grey, fontFamily: 'Inter'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
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
                  const Text('Personal Details',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter')),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                      Icons.location_on_outlined, widget.lead.address ?? 'N/A'),
                  const SizedBox(height: 10),
                  _buildDetailRow(
                      Icons.email_outlined, widget.lead.email ?? 'N/A'),
                  const SizedBox(height: 10),
                  _buildDetailRow(
                      Icons.phone_outlined, widget.lead.phone ?? 'N/A'),
                  const SizedBox(height: 10),
                  _buildDetailRow(Icons.calendar_today_outlined,
                      'Joined on ${widget.lead.createdAt.day} ${_getMonthName(widget.lead.createdAt.month)}, ${widget.lead.createdAt.year}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Interested Services',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter')),
                      TextButton.icon(
                        onPressed: () => setState(
                            () => _isEditingService = !_isEditingService),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: Text(_isEditingService ? 'Save' : 'Edit'),
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.blue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _isEditingService
                      ? TextField(
                          controller: _serviceController,
                          decoration: InputDecoration(
                            hintText: 'Enter service',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        )
                      : widget.lead.service != null
                          ? Wrap(
                              spacing: 8,
                              children: [
                                Chip(
                                  label: Text(widget.lead.service!,
                                      style: const TextStyle(
                                          fontSize: 12, fontFamily: 'Inter')),
                                  backgroundColor: Colors.blue[50],
                                  labelStyle:
                                      const TextStyle(color: Colors.blue),
                                ),
                              ],
                            )
                          : const Text('No services',
                              style: TextStyle(
                                  color: Colors.grey, fontFamily: 'Inter')),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tags',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter')),
                      TextButton.icon(
                        onPressed: () =>
                            setState(() => _isEditingTags = !_isEditingTags),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: Text(_isEditingTags ? 'Save' : 'Edit'),
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.blue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _isEditingTags
                      ? TextField(
                          controller: _tagsController,
                          decoration: InputDecoration(
                            hintText: 'Enter tags',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        )
                      : widget.lead.tags != null
                          ? Wrap(
                              spacing: 8,
                              children: [
                                Chip(
                                  label: Text(widget.lead.tags!,
                                      style: const TextStyle(
                                          fontSize: 12, fontFamily: 'Inter')),
                                  backgroundColor: Colors.grey[200],
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                  onDeleted: () {},
                                ),
                              ],
                            )
                          : const Text('Select Tags',
                              style: TextStyle(
                                  color: Colors.grey, fontFamily: 'Inter')),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
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
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTab == 0
                                  ? Colors.blue
                                  : Colors.transparent,
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.home_outlined,
                                    size: 18,
                                    color: _selectedTab == 0
                                        ? Colors.white
                                        : Colors.grey),
                                const SizedBox(width: 8),
                                Text('Activity',
                                    style: TextStyle(
                                        color: _selectedTab == 0
                                            ? Colors.white
                                            : Colors.grey,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTab == 1
                                  ? Colors.blue
                                  : Colors.transparent,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.note_outlined,
                                    size: 18,
                                    color: _selectedTab == 1
                                        ? Colors.white
                                        : Colors.grey),
                                const SizedBox(width: 8),
                                Text('Notes',
                                    style: TextStyle(
                                        color: _selectedTab == 1
                                            ? Colors.white
                                            : Colors.grey,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTab == 2
                                  ? Colors.blue
                                  : Colors.transparent,
                              borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(12)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.task_outlined,
                                    size: 18,
                                    color: _selectedTab == 2
                                        ? Colors.white
                                        : Colors.grey),
                                const SizedBox(width: 8),
                                Text('Tasks',
                                    style: TextStyle(
                                        color: _selectedTab == 2
                                            ? Colors.white
                                            : Colors.grey,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: _selectedTab == 0
                        ? Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Lead Activity',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Inter')),
                                  ElevatedButton(
                                    onPressed: _showAddActivityDialog,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue),
                                    child: const Text('Add Activity',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'Inter')),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _activities.isEmpty
                                  ? const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 24),
                                      child: Text('No activity yet',
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontFamily: 'Inter')),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: _activities.length,
                                      itemBuilder: (context, index) {
                                        final activity = _activities[index];
                                        return Card(
                                          margin:
                                              const EdgeInsets.only(bottom: 12),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue[50],
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
                                                      ),
                                                      child: Text(
                                                        activity['activity'] ??
                                                            '',
                                                        style: const TextStyle(
                                                            color: Colors.blue,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontFamily:
                                                                'Inter'),
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    Text(
                                                      '${activity['timestamp'].day}/${activity['timestamp'].month}/${activity['timestamp'].year}',
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.grey,
                                                          fontFamily: 'Inter'),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  activity['remark'] ?? '',
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      fontFamily: 'Inter'),
                                                ),
                                                if (activity['date']
                                                        ?.isNotEmpty ??
                                                    false) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Date: ${activity['date']} ${activity['time']?.isNotEmpty ?? false ? 'Time: ${activity['time']}' : ''}',
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                        fontFamily: 'Inter'),
                                                  ),
                                                ],
                                                if (activity['lostReason']
                                                        ?.isNotEmpty ??
                                                    false) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Reason: ${activity['lostReason']}',
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                        fontFamily: 'Inter'),
                                                  ),
                                                ],
                                                if (activity['dealAmount']
                                                        ?.isNotEmpty ??
                                                    false) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Amount: ₹${activity['dealAmount']}',
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.green,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontFamily: 'Inter'),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ],
                          )
                        : _selectedTab == 1
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Notes',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Inter')),
                                      ElevatedButton(
                                        onPressed: _showAddNoteDialog,
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue),
                                        child: const Text('Add Note',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Inter')),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _notes.isEmpty
                                      ? const Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 24),
                                          child: Text('No notes yet',
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontFamily: 'Inter')),
                                        )
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: _notes.length,
                                          itemBuilder: (context, index) {
                                            return Card(
                                              margin: const EdgeInsets.only(
                                                  bottom: 12),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                child: Text(
                                                  _notes[index],
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      fontFamily: 'Inter'),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Tasks',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Inter')),
                                      ElevatedButton(
                                        onPressed: _showAddTaskDialog,
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue),
                                        child: const Text('Add Task',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Inter')),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _tasks.isEmpty
                                      ? const Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 24),
                                          child: Text('No tasks yet',
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontFamily: 'Inter')),
                                        )
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: _tasks.length,
                                          itemBuilder: (context, index) {
                                            final task = _tasks[index];
                                            return Card(
                                              margin: const EdgeInsets.only(
                                                  bottom: 12),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            task['title'] ?? '',
                                                            style: const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontFamily:
                                                                    'Inter'),
                                                          ),
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 4),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: task['priority'] ==
                                                                    'Critical'
                                                                ? Colors.red[50]
                                                                : task['priority'] ==
                                                                        'High'
                                                                    ? Colors.orange[
                                                                        50]
                                                                    : task['priority'] ==
                                                                            'Low'
                                                                        ? Colors.green[
                                                                            50]
                                                                        : Colors.blue[
                                                                            50],
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(4),
                                                          ),
                                                          child: Text(
                                                            task['priority'] ??
                                                                '',
                                                            style: TextStyle(
                                                                color: task['priority'] ==
                                                                        'Critical'
                                                                    ? Colors.red
                                                                    : task['priority'] ==
                                                                            'High'
                                                                        ? Colors
                                                                            .orange
                                                                        : task['priority'] ==
                                                                                'Low'
                                                                            ? Colors
                                                                                .green
                                                                            : Colors
                                                                                .blue,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontFamily:
                                                                    'Inter'),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    if (task['notes']
                                                            ?.isNotEmpty ??
                                                        false) ...[
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        task['notes'] ?? '',
                                                        style: const TextStyle(
                                                            fontSize: 13,
                                                            color: Colors.grey,
                                                            fontFamily: 'Inter'),
                                                      ),
                                                    ],
                                                    if (task['dueDate']
                                                            ?.isNotEmpty ??
                                                        false) ...[
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                              Icons.access_time,
                                                              size: 14,
                                                              color:
                                                                  Colors.grey),
                                                          const SizedBox(
                                                              width: 4),
                                                          Text(
                                                            '${task['dueDate']} ${task['dueTime'] ?? ''}',
                                                            style: const TextStyle(
                                                                fontSize: 12,
                                                                color:
                                                                    Colors.grey,
                                                                fontFamily:
                                                                    'Inter'),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ],
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

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 14, fontFamily: 'Inter', color: Colors.black87))),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}
