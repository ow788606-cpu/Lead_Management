import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hugeicons/hugeicons.dart';
import '../managers/lead_manager.dart';
import '../managers/task_manager.dart';
import '../managers/auth_manager.dart';
import '../models/lead.dart';
import 'leads/detail_lead_screen.dart';
import '../screens/tags/tag_api.dart';
import 'tasks/all_tasks_screen.dart';
import 'main_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _leadManager = LeadManager();
  final _taskManager = TaskManager();
  String _username = '';
  bool _isLoadingLeads = true;
  int _todaysTasks = 0;
  int _overdueTasks = 0;
  int _activeTasks = 0;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _loadLeads();
    _loadTasks();
  }

  void _loadUsername() async {
    final name = await AuthManager().getUsername();
    if (mounted && name != null) {
      setState(() {
        _username = name;
      });
    }
  }

  Future<void> _loadLeads() async {
    try {
      await _leadManager.loadLeads(forceRefresh: true);
    } catch (_) {
      // Keep dashboard usable if API fails.
    }
    if (!mounted) return;
    setState(() => _isLoadingLeads = false);
  }

  Future<void> _loadTasks() async {
    try {
      await _taskManager.loadTasks(forceRefresh: true);
      if (!mounted) return;
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      _todaysTasks = _taskManager.pendingTasks.where((task) {
        final taskDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
        return taskDate.isAtSameMomentAs(today);
      }).length;
      
      _overdueTasks = _taskManager.pendingTasks.where((task) {
        final taskDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
        return taskDate.isBefore(today);
      }).length;
      
      _activeTasks = _taskManager.pendingTasks.where((task) {
        final taskDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
        return taskDate.isAtSameMomentAs(today) || taskDate.isAfter(today);
      }).length;
      
      setState(() {});
    } catch (e) {
      // Keep dashboard usable if task loading fails
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLeads) {
      return const Center(child: CircularProgressIndicator());
    }

    final allLeads = _leadManager.allLeads;
    final freshLeads = allLeads.where((lead) => lead.isFresh).length;
    final scheduledAppointments = allLeads
        .where((lead) =>
            lead.followUpDate != null && !lead.isOverdue && !lead.isCompleted)
        .length;
    final followUpLeads =
        allLeads.where((lead) => lead.followUpDate != null).length;
    final overdueLeads = allLeads.where((lead) => lead.isOverdue).length;
    final lostLeads = allLeads
        .where((lead) => lead.tags?.toLowerCase().contains('lost') ?? false)
        .length;
    final convertedLeads = allLeads
        .where(
            (lead) => lead.tags?.toLowerCase().contains('converted') ?? false)
        .length;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_getGreeting(),
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Welcome${_username.isNotEmpty ? ', $_username' : ''}!',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _StatCard(
                      freshLeads.toString(),
                      'Fresh Leads',
                      Icons.phone_in_talk_outlined,
                      const Color(0xFF131416), onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 1, initialLeadTabIndex: 1)),
                );
              })),
              const SizedBox(width: 16),
              Expanded(
                  child: _StatCard(
                      scheduledAppointments.toString(),
                      'Scheduled Appointments',
                      Icons.calendar_today_outlined,
                      const Color(0xFF131416), onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 2)),
                );
              })),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _StatCard(
                      followUpLeads.toString(),
                      'Followup Leads',
                      Icons.access_time_outlined,
                      const Color(0xFF131416), onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 1, initialLeadTabIndex: 2)),
                );
              })),
              const SizedBox(width: 16),
              Expanded(
                  child: _StatCard(
                      overdueLeads.toString(),
                      'Overdue Leads',
                      Icons.warning_amber_outlined,
                      const Color(0xFF131416), onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 1, initialLeadTabIndex: 3)),
                );
              })),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _StatCard(lostLeads.toString(), 'Lost Leads',
                      Icons.person_off_outlined, const Color(0xFF131416))),
              const SizedBox(width: 16),
              Expanded(
                  child: _StatCard(convertedLeads.toString(), 'Converted Leads',
                      Icons.star_outline, const Color(0xFF131416))),
            ],
          ),
          const SizedBox(height: 24),
          _TaskManagementCard(
              todaysTasks: _todaysTasks,
              overdueTasks: _overdueTasks,
              activeTasks: _activeTasks),
          const SizedBox(height: 16),
          const _WeeklyReportCard(),
          const SizedBox(height: 16),
          _MonthlyReportCard(wonLeads: convertedLeads, lostLeads: lostLeads),
          const SizedBox(height: 16),
          _LeadsOverviewCard(leads: allLeads),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color bgColor;
  final VoidCallback? onTap;

  const _StatCard(this.value, this.label, this.icon, this.bgColor,
      {this.onTap});

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF131416);
    final iconColor =
        bgColor.toARGB32() == brandBlue.toARGB32() ? Colors.white : brandBlue;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(value,
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: bgColor, borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, color: iconColor, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskManagementCard extends StatelessWidget {
  final int todaysTasks;
  final int overdueTasks;
  final int activeTasks;

  const _TaskManagementCard(
      {required this.todaysTasks,
      required this.overdueTasks,
      required this.activeTasks});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Task Management',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                        'From ${DateTime.now().subtract(const Duration(days: 90)).day} ${_getMonthName(DateTime.now().subtract(const Duration(days: 90)).month)} - ${DateTime.now().day} ${_getMonthName(DateTime.now().month)} ${DateTime.now().year}',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AllTasksScreen(initialTabIndex: 0, filter: 'today'),
                      ),
                    );
                  },
                  child: _buildTaskRow(todaysTasks.toString(), 'Today\'s Tasks'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AllTasksScreen(initialTabIndex: 0, filter: 'overdue'),
                      ),
                    );
                  },
                  child: _buildTaskRow(overdueTasks.toString(), 'Overdue Tasks'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AllTasksScreen(initialTabIndex: 0, filter: 'active'),
                      ),
                    );
                  },
                  child: _buildTaskRow(activeTasks.toString(), 'Active Tasks'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskRow(String value, String label) {
    return Container(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
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

class _WeeklyReportCard extends StatelessWidget {
  const _WeeklyReportCard();

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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Task Management',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          const Text('Weekly Report',
              style: TextStyle(color: Colors.red, fontSize: 10)),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(
                    show: true, drawVerticalLine: false, horizontalInterval: 1),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 25,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return Text(value.toInt().toString(),
                            style: const TextStyle(
                                fontSize: 9, color: Colors.grey));
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final now = DateTime.now();
                        final dates = List.generate(4,
                            (i) => now.subtract(Duration(days: (3 - i) * 2)));
                        if (value.toInt() >= 0 &&
                            value.toInt() < dates.length) {
                          final date = dates[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                                '${date.day} ${_getMonthName(date.month)}',
                                style: const TextStyle(
                                    fontSize: 9, color: Colors.red)),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 2,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 1.5),
                      FlSpot(1, 1.8),
                      FlSpot(2, 1.2),
                      FlSpot(3, 1.6),
                    ],
                    isCurved: false,
                    color: const Color(0xFF131416),
                    barWidth: 2,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: const Color(0xFF131416),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyReportCard extends StatelessWidget {
  final int wonLeads;
  final int lostLeads;

  const _MonthlyReportCard({required this.wonLeads, required this.lostLeads});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Monthly Report',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          const Text('Weekly Report',
              style: TextStyle(color: Colors.grey, fontSize: 10)),
          const SizedBox(height: 30),
          const Center(
              child: Text('Total',
                  style: TextStyle(color: Colors.grey, fontSize: 10))),
          const SizedBox(height: 6),
          Center(
              child: Text((wonLeads + lostLeads).toString(),
                  style: const TextStyle(
                      fontSize: 40, fontWeight: FontWeight.bold))),
          const SizedBox(height: 30),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 20,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(
                    width: 12,
                    height: 12,
                    child: DecoratedBox(
                        decoration: BoxDecoration(
                            color: Color(0xFF131416), shape: BoxShape.circle))),
                const SizedBox(width: 6),
                Text('Won ($wonLeads)', style: const TextStyle(fontSize: 11))
              ]),
              Row(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(
                    width: 12,
                    height: 12,
                    child: DecoratedBox(
                        decoration: BoxDecoration(
                            color: Colors.pink, shape: BoxShape.circle))),
                const SizedBox(width: 6),
                Text('Lost ($lostLeads)', style: const TextStyle(fontSize: 11))
              ]),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeadsOverviewCard extends StatefulWidget {
  final List<Lead> leads;

  const _LeadsOverviewCard({required this.leads});

  @override
  State<_LeadsOverviewCard> createState() => _LeadsOverviewCardState();
}

class _LeadsOverviewCardState extends State<_LeadsOverviewCard> {
  String _selectedTab = 'Fresh Leads';
  List<TagItem> _tags = [];
  Map<String, Color> _tagColors = {};

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    try {
      _tags = await TagApi.fetchTags();
      _tagColors = {};
      for (final tag in _tags) {
        _tagColors[tag.id.toString()] = _parseColor(tag.colorHex);
        _tagColors[tag.name] = _parseColor(tag.colorHex);
        _tagColors[tag.name.toLowerCase()] = _parseColor(tag.colorHex);
        _tagColors[tag.name.trim()] = _parseColor(tag.colorHex);
        _tagColors[tag.name.trim().toLowerCase()] = _parseColor(tag.colorHex);
      }
      if (mounted) setState(() {});
    } catch (e) {
      // Handle error silently
    }
  }

  Color _parseColor(String hex) {
    final normalized = hex.replaceFirst('#', '').toUpperCase();
    if (normalized.length != 6) return const Color(0xFF131416);
    return Color(int.parse('FF$normalized', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final filteredLeads = _selectedTab == 'Fresh Leads'
        ? widget.leads.where((lead) => lead.isFresh).toList()
        : _selectedTab == 'Appointment Scheduled'
            ? widget.leads
                .where((lead) =>
                    lead.followUpDate != null &&
                    !lead.isOverdue &&
                    !lead.isCompleted)
                .toList()
            : widget.leads.where((lead) => lead.followUpDate != null).toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Leads Overview',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTab = 'Fresh Leads';
                    });
                  },
                  child:
                      _TabButton('Fresh Leads', _selectedTab == 'Fresh Leads'),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTab = 'Appointment Scheduled';
                    });
                  },
                  child: _TabButton('Appointment Scheduled',
                      _selectedTab == 'Appointment Scheduled'),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTab = 'Follow-up';
                    });
                  },
                  child: _TabButton('Follow-up', _selectedTab == 'Follow-up'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (filteredLeads.isEmpty)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('No leads found.',
                  style: TextStyle(color: Colors.grey, fontSize: 11)),
            ))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredLeads.length > 5 ? 5 : filteredLeads.length,
              itemBuilder: (context, index) => _buildLeadCard(filteredLeads[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildLeadCard(Lead lead) {
    String statusTag = '';
    Color statusColor = Colors.grey;

    if (lead.isCompleted) {
      statusTag = 'Completed';
      statusColor = Colors.green;
    } else if (lead.isOverdue) {
      statusTag = 'Overdue';
      statusColor = Colors.red;
    } else if (lead.isFresh) {
      statusTag = 'Fresh';
      statusColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailLeadScreen(
                lead: lead,
                startInEditMode: false,
                initialTabIndex: 0,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(lead.contactName,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black)),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F5F5),
                      shape: BoxShape.circle,
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedCall,
                      color: Color(0xFF6B7280),
                      size: 16.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F5F5),
                      shape: BoxShape.circle,
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedComment01,
                      color: Color(0xFF6B7280),
                      size: 16.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F5F5),
                      shape: BoxShape.circle,
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedMail01,
                      color: Color(0xFF6B7280),
                      size: 16.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (lead.service != null)
                Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedCustomerService,
                      color: Colors.grey[600]!,
                      size: 16.0,
                    ),
                    const SizedBox(width: 6),
                    Text('${lead.service}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  ],
                ),
              if (lead.notes != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedChatting01,
                      color: Colors.grey[400]!,
                      size: 16.0,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('${lead.notes}',
                          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
              if (lead.tags != null && lead.tags!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: lead.tags!.split(',').map((tag) {
                    final trimmedTag = tag.trim();
                    if (trimmedTag.isEmpty) return const SizedBox.shrink();

                    String mappedTag = trimmedTag;
                    if (trimmedTag == 'bh') {
                      mappedTag = '15';
                    }

                    Color? tagColor;
                    String? tagName;

                    if (_tagColors.containsKey(mappedTag)) {
                      tagColor = _tagColors[mappedTag];
                      final matchingTag = _tags.firstWhere(
                        (t) => t.id.toString() == mappedTag,
                        orElse: () => TagItem(
                            id: 0, name: mappedTag, description: '', colorHex: ''),
                      );
                      tagName = matchingTag.name.isNotEmpty ? matchingTag.name : mappedTag;
                    } else {
                      for (final entry in _tagColors.entries) {
                        if (entry.key.toLowerCase() == mappedTag.toLowerCase()) {
                          tagColor = entry.value;
                          tagName = mappedTag;
                          break;
                        }
                      }
                    }

                    Color textColor;
                    Color backgroundColor;

                    if (tagColor == null) {
                      textColor = const Color(0xFF6B46C1);
                      backgroundColor = const Color(0xFF6B46C1).withValues(alpha: 0.1);
                      tagName = trimmedTag;
                    } else {
                      textColor = tagColor;
                      backgroundColor = tagColor.withValues(alpha: 0.1);
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        tagName ?? trimmedTag,
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (lead.followUpDate != null || statusTag.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 0.5, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (lead.followUpDate != null)
                      Text(
                        'Follow-up : ${lead.followUpDate!.day}/${lead.followUpDate!.month}/${lead.followUpDate!.year} ${lead.followUpTime ?? '10:00 AM'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    if (statusTag.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(statusTag,
                            style: TextStyle(
                                fontSize: 11,
                                color: statusColor,
                                fontWeight: FontWeight.w500)),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;

  const _TabButton(this.label, this.isActive);

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF131416);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? brandBlue : Colors.transparent,
        border: Border.all(color: isActive ? brandBlue : Colors.grey[300]!),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              color: isActive ? Colors.white : Colors.grey[600], fontSize: 11)),
    );
  }
}
