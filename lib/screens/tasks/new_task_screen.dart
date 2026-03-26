import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../models/task.dart';
import '../../managers/task_manager.dart';
import '../../widgets/app_drawer.dart';

class NewTaskScreen extends StatefulWidget {
  const NewTaskScreen({super.key});

  @override
  State<NewTaskScreen> createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends State<NewTaskScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedPriority;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  PlatformFile? _selectedAttachment;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      drawer: AppDrawer(
        selectedIndex: 4,
        onItemSelected: (_) => Navigator.pop(context),
      ),
      appBar: AppBar(
        toolbarHeight: 56,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('New Task'),
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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: const TextSpan(
                        text: 'Task Title ',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 13,
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
                      controller: _titleController,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Enter task title',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: HugeIcon(
                          icon: HugeIcons.strokeRoundedTask01,
                          color: Colors.grey[400]!,
                          size: 20.0,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(color: Colors.grey[300]!)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(color: Colors.grey[300]!)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Task Description',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter')),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Enter task description',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(bottom: 60),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedFileEdit,
                            color: Colors.grey[400]!,
                            size: 20.0,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(color: Colors.grey[300]!)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(color: Colors.grey[300]!)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      text: const TextSpan(
                        text: 'Priority ',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter'),
                        children: [
                          TextSpan(
                              text: '*', style: TextStyle(color: Colors.red))
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPriority,
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.black,
                          fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Select Priority',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: HugeIcon(
                          icon: HugeIcons.strokeRoundedFlag01,
                          color: Colors.grey[400]!,
                          size: 20.0,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(color: Colors.grey[300]!)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(color: Colors.grey[300]!)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      items: ['Low', 'Medium', 'High', 'Urgent']
                          .map((priority) => DropdownMenuItem(
                              value: priority, child: Text(priority)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedPriority = value),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      text: const TextSpan(
                        text: 'Due Date ',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter'),
                        children: [
                          TextSpan(
                              text: '*', style: TextStyle(color: Colors.red))
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) setState(() => _selectedDate = date);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDate != null
                                  ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                  : 'Select due date',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                  color: _selectedDate != null
                                      ? Colors.black
                                      : Colors.grey[400]),
                            ),
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedCalendar03,
                              color: Colors.grey[400]!,
                              size: 16.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      text: const TextSpan(
                        text: 'Due Time ',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter'),
                        children: [
                          TextSpan(
                              text: '*', style: TextStyle(color: Colors.red))
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) setState(() => _selectedTime = time);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedTime != null
                                  ? _selectedTime!.format(context)
                                  : 'Select due time',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: _selectedTime != null
                                      ? Colors.black
                                      : Colors.grey[400],
                                  fontFamily: 'Inter'),
                            ),
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedClock01,
                              color: Colors.grey[400]!,
                              size: 16.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Attachment',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter')),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        try {
                          final result = await FilePicker.platform.pickFiles(
                            allowMultiple: false,
                            withData: false,
                          );
                          if (result == null || result.files.isEmpty) return;
                          final file = result.files.first;
                          if (file.path == null || file.path!.isEmpty) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Unable to read selected file.'),
                              ),
                            );
                            return;
                          }
                          setState(() => _selectedAttachment = file);
                        } catch (_) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to pick attachment.'),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _selectedAttachment?.name ?? 'Add attachment',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: _selectedAttachment != null
                                        ? Colors.black
                                        : Colors.grey[400],
                                    fontFamily: 'Inter'),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_selectedAttachment != null)
                              IconButton(
                                icon: HugeIcon(
                                  icon: HugeIcons.strokeRoundedCancel01,
                                  color: Colors.grey[500]!,
                                  size: 16.0,
                                ),
                                onPressed: () =>
                                    setState(() => _selectedAttachment = null),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              )
                            else
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedAttachment01,
                                color: Colors.grey[400]!,
                                size: 16.0,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        if (_titleController.text.isEmpty ||
                            _selectedPriority == null ||
                            _selectedDate == null ||
                            _selectedTime == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Please fill all required fields')),
                          );
                          return;
                        }

                        // Combine date and time to check if task is overdue
                        final dueDateTime = DateTime(
                          _selectedDate!.year,
                          _selectedDate!.month,
                          _selectedDate!.day,
                          _selectedTime!.hour,
                          _selectedTime!.minute,
                        );

                        final now = DateTime.now();
                        final isOverdue = dueDateTime.isBefore(now);

                        final task = Task(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: _titleController.text,
                          description: _descriptionController.text,
                          priority: _selectedPriority!,
                          dueDate: _selectedDate!,
                          dueTime: _selectedTime!.format(context),
                          isCompleted: isOverdue,
                          completedDate: isOverdue ? now : null,
                        );

                        await TaskManager().addTask(
                          task,
                          attachmentPath: _selectedAttachment?.path,
                          attachmentName: _selectedAttachment?.name,
                          attachmentBytes: _selectedAttachment?.bytes,
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);

                        // Show appropriate message based on task status
                        final message = isOverdue
                            ? 'Task created and marked as completed (was overdue)'
                            : 'Task created successfully';

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(message),
                            backgroundColor:
                                isOverdue ? Colors.orange : Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF131416),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                      child: const Text('Create Task',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              fontFamily: 'Inter')),
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
}
