import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../widgets/app_drawer.dart';
import '../../services/task_notification_api.dart';

class TaskNotificationsScreen extends StatefulWidget {
  const TaskNotificationsScreen({super.key});

  @override
  State<TaskNotificationsScreen> createState() => _TaskNotificationsScreenState();
}

class _TaskNotificationsScreenState extends State<TaskNotificationsScreen> {
  final List<_TaskNotification> _notifications = [];
  bool _isLoading = true;

  List<_TaskNotification> _filterUnread(List<_TaskNotification> items) {
    return items.where((n) => !n.isRead).toList();
  }

  List<_TaskNotification> _filterRead(List<_TaskNotification> items) {
    return items.where((n) => n.isRead).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final data = await TaskNotificationApi.fetchNotifications();
    final items = data.map(_TaskNotification.fromMap).toList();
    if (!mounted) return;
    setState(() {
      _notifications
        ..clear()
        ..addAll(items);
      _isLoading = false;
    });
  }

  Future<void> _markAsRead(_TaskNotification item) async {
    if (item.isRead) return;
    final ok = await TaskNotificationApi.setRead(
      id: item.id,
      isRead: true,
    );
    if (!ok || !mounted) return;
    setState(() {
      final idx = _notifications.indexWhere((n) => n.id == item.id);
      if (idx >= 0) {
        _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final unread = _filterUnread(_notifications);
    final read = _filterRead(_notifications);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
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
          title: const Text(
            'Tasks Notification',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: const Color(0xFF131416),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF131416),
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorWeight: 2,
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  dividerColor: Colors.transparent,
                  tabs: [
                    _buildBadgeTab('Unread', unread.length),
                    _buildBadgeTab('Read', read.length),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F6FA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: TabBarView(
                  children: [
                    _buildNotificationList(unread),
                    _buildNotificationList(read),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Tab _buildBadgeTab(String label, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF131416),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<_TaskNotification> items) {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (items.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) =>
          _buildNotificationCard(items[index]),
    );
  }

  Widget _buildNotificationCard(_TaskNotification item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _markAsRead(item),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: item.isRead ? const Color(0xFFE5E7EB) : const Color(0xFF131416),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFE5E7EB),
                  shape: BoxShape.circle,
                ),
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedNotification03,
                  color: Color(0xFF131416),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDateTime(item.time),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
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

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 32, color: Color(0xFF9CA3AF)),
          SizedBox(height: 10),
          Text(
            "You're all caught up!",
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final month = _monthName(date.month);
    final day = date.day;
    final year = date.year;
    final time = _formatTime(date);
    return '$month $day, $year - $time';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _monthName(int month) {
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

class _TaskNotification {
  final String id;
  final String taskId;
  final String title;
  final String message;
  final DateTime time;
  final bool isRead;

  _TaskNotification({
    required this.id,
    required this.taskId,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
  });

  factory _TaskNotification.fromMap(Map<String, dynamic> data) {
    final createdAt = data['created_at']?.toString();
    final parsedTime = DateTime.tryParse(createdAt ?? '') ?? DateTime.now();
    final readRaw = data['is_read'];
    final isRead = readRaw == true ||
        readRaw == 1 ||
        readRaw == '1' ||
        readRaw == 'true';

    return _TaskNotification(
      id: (data['id'] ?? '').toString(),
      taskId: (data['task_id'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      message: (data['message'] ?? '').toString(),
      time: parsedTime,
      isRead: isRead,
    );
  }

  _TaskNotification copyWith({bool? isRead}) {
    return _TaskNotification(
      id: id,
      taskId: taskId,
      title: title,
      message: message,
      time: time,
      isRead: isRead ?? this.isRead,
    );
  }
}
