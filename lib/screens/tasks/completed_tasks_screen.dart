import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../managers/task_manager.dart';
import '../../widgets/app_drawer.dart';
import 'edit_task_screen.dart';
import 'new_task_screen.dart';

class CompletedTasksScreen extends StatefulWidget {
  const CompletedTasksScreen({super.key});

  @override
  State<CompletedTasksScreen> createState() => _CompletedTasksScreenState();
}

class _CompletedTasksScreenState extends State<CompletedTasksScreen> {
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

  @override
  Widget build(BuildContext context) {
    final tasks = taskManager.completedTasks;
    final filteredTasks = tasks.where((task) {
      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return task.title.toLowerCase().contains(q) ||
          task.description.toLowerCase().contains(q) ||
          task.priority.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      drawer: AppDrawer(
        selectedIndex: 4,
        onItemSelected: (_) => Navigator.pop(context),
      ),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Complete Task'),
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search completed tasks...',
                prefixIcon: const Icon(Icons.search),
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
                      child: Text('No completed tasks',
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
                                  // const Icon(Icons.check_circle_outline,
                                  //     size: 18, color: Colors.green),
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
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('Completed',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green,
                                            fontFamily: 'Inter')),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EditTaskScreen(task: task),
                                        ),
                                      );
                                    },
                                    child: const HugeIcon(
                                      icon: HugeIcons.strokeRoundedEdit02,
                                      color: Colors.blue,
                                      size: 18.0,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => _deleteTask(task.id),
                                    child: const HugeIcon(
                                      icon: HugeIcons.strokeRoundedDelete02,
                                      color: Colors.red,
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
                                      const Icon(Icons.notes_outlined,
                                          size: 16, color: Colors.grey),
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
                                    const Icon(Icons.event_available_outlined,
                                        size: 16, color: Color(0xFF131416)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                          'Completed: ${task.completedDate!.day}/${task.completedDate!.month}/${task.completedDate!.year}',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'Inter',
                                              color: Color(0xFF131416))),
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
}
