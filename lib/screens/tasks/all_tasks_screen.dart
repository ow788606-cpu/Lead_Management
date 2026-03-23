import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../managers/task_manager.dart';
import '../../widgets/app_drawer.dart';
import 'edit_task_screen.dart';
import 'new_task_screen.dart';

class AllTasksScreen extends StatefulWidget {
  final int initialTabIndex;

  const AllTasksScreen({super.key, this.initialTabIndex = 0});

  @override
  State<AllTasksScreen> createState() => _AllTasksScreenState();
}

class _AllTasksScreenState extends State<AllTasksScreen>
    with SingleTickerProviderStateMixin {
  late final TaskManager taskManager;
  final _searchController = TextEditingController();
  late TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
    _tabController.addListener(() {
      setState(() => _selectedTab = _tabController.index);
    });
    _selectedTab = widget.initialTabIndex;
    taskManager = TaskManager();
    taskManager.addListener(_onTasksChanged);
    taskManager.loadTasks(forceRefresh: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
        ScaffoldMessenger.of(context).clearSnackBars();
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

  List<dynamic> _getFilteredTasks() {
    List<dynamic> tasks;
    switch (_selectedTab) {
      case 1:
        tasks = taskManager.pendingTasks;
        break;
      case 2:
        tasks = taskManager.completedTasks;
        break;
      default:
        tasks = [...taskManager.pendingTasks, ...taskManager.completedTasks];
    }

    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return tasks;
    return tasks
        .where((t) =>
            t.title.toLowerCase().contains(query) ||
            t.description.toLowerCase().contains(query) ||
            t.priority.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _getFilteredTasks();

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AppDrawer(
        selectedIndex: 4,
        onItemSelected: (index) {
          Navigator.pop(context);
        },
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
        title: const Text('All Tasks',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
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
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedSearch01,
                            color: Colors.grey,
                            size: 20.0,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              hintText: 'Search',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: IconButton(
                            icon: const HugeIcon(
                              icon: HugeIcons.strokeRoundedFilterHorizontal,
                              color: Colors.grey,
                              size: 20.0,
                            ),
                            onPressed: () {},
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: const Color(0xFF131416),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF131416),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'All Tasks'),
                    Tab(text: 'Pending Tasks'),
                    Tab(text: 'Completed Tasks'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF4F6FA),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: filteredTasks.isEmpty
                  ? const Center(child: Text('No tasks found'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) =>
                          _buildTaskCard(filteredTasks[index]),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF131416),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NewTaskScreen(),
              ),
            );
          },
          icon: const Icon(Icons.add, color: Colors.white, size: 24),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildTaskCard(dynamic task) {
    final isCompleted = task.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(task.title,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(task.priority)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(task.priority,
                      style: TextStyle(
                          fontSize: 12,
                          color: _getPriorityColor(task.priority),
                          fontWeight: FontWeight.w500)),
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
                          Text('Edit',
                              style: TextStyle(
                                  fontFamily: 'Inter', fontSize: 14)),
                        ],
                      ),
                    ),
                    if (!isCompleted)
                      const PopupMenuItem(
                        value: 'complete',
                        child: Row(
                          children: [
                            HugeIcon(
                              icon: HugeIcons
                                  .strokeRoundedCheckmarkCircle02,
                              color: Colors.green,
                              size: 18,
                            ),
                            SizedBox(width: 10),
                            Text('Mark as Complete',
                                style: TextStyle(
                                    fontFamily: 'Inter', fontSize: 14)),
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
                          Text('Delete',
                              style: TextStyle(
                                  fontFamily: 'Inter', fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedMoreVertical,
                      color: Color(0xFF6B7280),
                      size: 18.0,
                    ),
                  ),
                ),
              ],
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedFileEdit,
                    color: Colors.grey[400]!,
                    size: 16.0,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(task.description,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[500]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            const Divider(
                height: 1, thickness: 0.5, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedClock01,
                      color: Color(0xFF6B7280),
                      size: 16.0,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Due: ${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year} ${task.dueTime}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Completed',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.w500)),
                  ),
              ],
            ),
          ],
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
        return const Color(0xFF131416);
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
