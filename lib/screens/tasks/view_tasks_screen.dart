import 'package:flutter/material.dart';
import '../../models/task.dart';

class ViewTasksScreen extends StatelessWidget {
  final Task task;

  const ViewTasksScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Task Details',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(task.title,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter')),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(task.priority).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(task.priority,
                      style: TextStyle(
                          fontSize: 12,
                          color: _getPriorityColor(task.priority),
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter')),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Description', task.description.isEmpty ? 'No description' : task.description),
            const SizedBox(height: 16),
            _buildDetailRow('Due Date', '${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}'),
            const SizedBox(height: 16),
            _buildDetailRow('Due Time', task.dueTime),
            const SizedBox(height: 16),
            _buildDetailRow('Priority', task.priority),
            const SizedBox(height: 16),
            _buildDetailRow('Status', task.isCompleted ? 'Completed' : 'Pending'),
            if (task.isCompleted && task.completedDate != null) ...[
              const SizedBox(height: 16),
              _buildDetailRow('Completed On', '${task.completedDate!.day}/${task.completedDate!.month}/${task.completedDate!.year}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter')),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 16, fontFamily: 'Inter', color: Colors.black87)),
      ],
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Urgent':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.blue;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

