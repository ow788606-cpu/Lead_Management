import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../managers/task_manager.dart';
import 'edit_task_screen.dart';
import 'new_task_screen.dart';

class PendingTasksScreen extends StatefulWidget {
  const PendingTasksScreen({super.key});

  @override
  State<PendingTasksScreen> createState() => _PendingTasksScreenState();
}

class _PendingTasksScreenState extends State<PendingTasksScreen> {
  late final TaskManager taskManager;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    taskManager = TaskManager();
    taskManager.addListener(_onTasksChanged);
    taskManager.loadTasks(forceRefresh: true);
  }

  @override
  void dispose() {
    taskManager.removeListener(_onTasksChanged);
    super.dispose();
  }

  void _onTasksChanged() {
    setState(() {});
  }

  void _deleteTask(String taskId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await taskManager.deleteTask(taskId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _markAsComplete(String taskId) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Marking task as completed...'),
            ],
          ),
          duration: Duration(seconds: 1),
        ),
      );

      await taskManager.completeTask(taskId);

      if (mounted) {
        // Clear any existing snackbars
        ScaffoldMessenger.of(context).clearSnackBars();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task marked as completed!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Clear any existing snackbars
        ScaffoldMessenger.of(context).clearSnackBars();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete task: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = taskManager.pendingTasks;
    final filteredTasks = tasks.where((task) {
      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return task.title.toLowerCase().contains(q) ||
          task.description.toLowerCase().contains(q) ||
          task.priority.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search pending tasks...',
                prefixIcon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedSearch01,
                  color: Colors.grey,
                  size: 20.0,
                ),
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
              child: filteredTasks.isEmpty
                  ? const Center(
                      child: Text('No pending tasks',
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontFamily: 'Inter')))
                  : ListView.builder(
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = filteredTasks[index];
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
                                  // const Icon(Icons.task_alt_outlined,
                                  //     size: 18, color: Color(0xFF0B5CFF)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(task.title,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Inter')),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getPriorityColor(task.priority)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(task.priority,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: _getPriorityColor(
                                                task.priority),
                                            fontFamily: 'Inter')),
                                  ),
                                  const SizedBox(width: 8),
                                  PopupMenuButton<String>(
                                    color: Colors.white,
                                    onSelected: (value) {
                                      switch (value) {
                                        case 'edit':
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EditTaskScreen(task: task),
                                            ),
                                          );
                                          break;
                                        case 'delete':
                                          _deleteTask(task.id);
                                          break;
                                        case 'complete':
                                          _markAsComplete(task.id);
                                          break;
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            HugeIcon(
                                              icon: HugeIcons.strokeRoundedPencilEdit02,
                                              color: Colors.blue,
                                              size: 18,
                                            ),
                                            SizedBox(width: 10),
                                            Text('Edit', style: TextStyle(fontFamily: 'Inter', fontSize: 14)),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'complete',
                                        child: Row(
                                          children: [
                                            HugeIcon(
                                              icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                                              color: Colors.green,
                                              size: 18,
                                            ),
                                            SizedBox(width: 10),
                                            Text('Mark as Complete', style: TextStyle(fontFamily: 'Inter', fontSize: 14)),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            HugeIcon(
                                              icon: HugeIcons.strokeRoundedDelete02,
                                              color: Colors.red,
                                              size: 18,
                                            ),
                                            SizedBox(width: 10),
                                            Text('Delete', style: TextStyle(fontFamily: 'Inter', fontSize: 14)),
                                          ],
                                        ),
                                      ),
                                    ],
                                    child: const HugeIcon(
                                      icon: HugeIcons.strokeRoundedMoreVertical,
                                      color: Colors.grey,
                                      size: 18.0,
                                    ),
                                  ),
                                ],
                              ),
                              if (task.description.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const HugeIcon(
                                        icon: HugeIcons.strokeRoundedFileEdit,
                                        color: Colors.grey,
                                        size: 16.0,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(task.description,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontFamily: 'Inter',
                                                color: Colors.grey)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Row(
                                  children: [
                                    const HugeIcon(
                                      icon: HugeIcons.strokeRoundedClock01,
                                      color: Color(0xFF0B5CFF),
                                      size: 16.0,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                          'Due: ${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year} ${task.dueTime}',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'Inter',
                                              color: Color(0xFF0B5CFF))),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewTaskScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Urgent':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return const Color(0xFF0B5CFF);
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
