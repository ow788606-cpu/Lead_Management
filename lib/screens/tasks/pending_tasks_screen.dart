import 'package:flutter/material.dart';
import '../../managers/task_manager.dart';
import 'view_tasks_screen.dart';

class PendingTasksScreen extends StatefulWidget {
  const PendingTasksScreen({super.key});

  @override
  State<PendingTasksScreen> createState() => _PendingTasksScreenState();
}

class _PendingTasksScreenState extends State<PendingTasksScreen> {
  late final TaskManager taskManager;

  @override
  void initState() {
    super.initState();
    taskManager = TaskManager();
    taskManager.addListener(_onTasksChanged);
  }

  @override
  void dispose() {
    taskManager.removeListener(_onTasksChanged);
    super.dispose();
  }

  void _onTasksChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tasks = taskManager.pendingTasks;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Pending Tasks',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
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
                // const Text('Pending Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                const SizedBox(height: 4),
                const Text(
                    'Tasks that are still in progress or awaiting completion.',
                    style: TextStyle(
                        color: Colors.grey, fontSize: 13, fontFamily: 'Inter')),
                const SizedBox(height: 24),
                Expanded(
                  child: tasks.isEmpty
                      ? const Center(
                          child: Text('No pending tasks',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  fontFamily: 'Inter')))
                      : ListView.builder(
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            return Container(
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
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(task.title,
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Inter')),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.visibility_outlined, color: Colors.blue, size: 20),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ViewTasksScreen(task: task),
                                            ),
                                          );
                                        },
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color:
                                              _getPriorityColor(task.priority)
                                                  .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(task.priority,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: _getPriorityColor(
                                                    task.priority),
                                                fontFamily: 'Inter')),
                                      ),
                                    ],
                                  ),
                                  if (task.description.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(task.description,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontFamily: 'Inter',
                                            color: Colors.grey)),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                      'Due: ${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year} ${task.dueTime}',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Inter',
                                          color: Colors.blue)),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
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
