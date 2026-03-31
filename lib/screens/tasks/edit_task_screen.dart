import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../managers/task_manager.dart';
import '../../utils/responsive_helper.dart';

class EditTaskScreen extends StatefulWidget {
  final Task task;

  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late String _priority;
  late DateTime _dueDate;
  late TimeOfDay _dueTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController =
        TextEditingController(text: widget.task.description);
    _priority = _normalizePriority(widget.task.priority);
    _dueDate = widget.task.dueDate;
    _dueTime = _parseTime(widget.task.dueTime);
  }

  String _normalizePriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      case 'urgent':
        return 'Urgent';
      default:
        return 'Medium';
    }
  }

  TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(' ');
    final timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    if (parts.length > 1 && parts[1].toUpperCase() == 'PM' && hour != 12) {
      hour += 12;
    } else if (parts.length > 1 &&
        parts[1].toUpperCase() == 'AM' &&
        hour == 12) {
      hour = 0;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour == 0 ? 12 : hour}:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Task'),
        actions: [
          TextButton(
            onPressed: _saveTask,
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding:
              EdgeInsets.all(ResponsiveHelper.getHorizontalSpacing(context)),
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.trim().isEmpty == true ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: ['Low', 'Medium', 'High', 'Urgent']
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (value) => setState(() => _priority = value!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _dueDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) setState(() => _dueDate = date);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Due Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                            '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _dueTime,
                        );
                        if (time != null) setState(() => _dueTime = time);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Due Time',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(_formatTime(_dueTime)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedTask = Task(
      id: widget.task.id,
      leadId: widget.task.leadId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      priority: _priority,
      dueDate: _dueDate,
      dueTime: _formatTime(_dueTime),
      isCompleted: widget.task.isCompleted,
      completedDate: widget.task.completedDate,
    );

    await TaskManager().updateTask(updatedTask);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
