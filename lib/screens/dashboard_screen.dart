import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../managers/lead_manager.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _leadManager = LeadManager();

  @override
  Widget build(BuildContext context) {
    final allLeads = _leadManager.allLeads;
    final freshLeads = allLeads.where((lead) => lead.isFresh).length;
    final scheduledAppointments = allLeads.where((lead) => lead.followUpDate != null && !lead.isOverdue && !lead.isCompleted).length;
    final followUpLeads = allLeads.where((lead) => lead.followUpDate != null && !lead.isOverdue && !lead.isCompleted).length;
    final overdueLeads = allLeads.where((lead) => lead.isOverdue).length;
    final completedLeads = allLeads.where((lead) => lead.isCompleted).length;
    final lostLeads = allLeads.where((lead) => lead.tags?.toLowerCase().contains('lost') ?? false).length;
    final convertedLeads = allLeads.where((lead) => lead.tags?.toLowerCase().contains('converted') ?? false).length;
    final todaysTasks = allLeads.where((lead) => lead.followUpDate != null && lead.followUpDate!.year == DateTime.now().year && lead.followUpDate!.month == DateTime.now().month && lead.followUpDate!.day == DateTime.now().day).length;
    final overdueTasks = overdueLeads;
    final activeTasks = allLeads.where((lead) => !lead.isCompleted && lead.followUpDate != null).length;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _StatCard(freshLeads.toString(), 'Fresh Leads',
                      Icons.phone_in_talk_outlined, const Color(0xFFE3F2FD))),
              const SizedBox(width: 16),
              Expanded(
                  child: _StatCard(
                      scheduledAppointments.toString(),
                      'Scheduled Appointments',
                      Icons.calendar_today_outlined,
                      const Color(0xFFE3F2FD))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _StatCard(followUpLeads.toString(), 'Followup Leads',
                      Icons.access_time_outlined, const Color(0xFFE3F2FD))),
              const SizedBox(width: 16),
              Expanded(
                  child: _StatCard(overdueLeads.toString(), 'Overdue Leads',
                      Icons.warning_amber_outlined, const Color(0xFFFFEBEE))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _StatCard(lostLeads.toString(), 'Lost Leads',
                      Icons.person_off_outlined, const Color(0xFFF5F5F5))),
              const SizedBox(width: 16),
              Expanded(
                  child: _StatCard(convertedLeads.toString(), 'Converted Leads',
                      Icons.star_outline, const Color(0xFFE8F5E9))),
            ],
          ),
          const SizedBox(height: 24),
          _TaskManagementCard(
              todaysTasks: todaysTasks,
              overdueTasks: overdueTasks,
              activeTasks: activeTasks),
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

  const _StatCard(this.value, this.label, this.icon, this.bgColor);

  @override
  Widget build(BuildContext context) {
    return Container(
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
                child: Icon(icon, color: Colors.blue[700], size: 20),
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
                    Text('Task Management',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text(
                        'From ${DateTime.now().subtract(Duration(days: 90)).day} ${_getMonthName(DateTime.now().subtract(Duration(days: 90)).month)} - ${DateTime.now().day} ${_getMonthName(DateTime.now().month)} ${DateTime.now().year}',
                        style: TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child:
                      _buildTaskRow(todaysTasks.toString(), 'Today\'s Tasks')),
              const SizedBox(width: 16),
              Expanded(
                  child:
                      _buildTaskRow(overdueTasks.toString(), 'Overdue Tasks')),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildTaskRow(activeTasks.toString(), 'Active Tasks')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskRow(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

class _WeeklyReportCard extends StatelessWidget {
  const _WeeklyReportCard();

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
                        final dates = List.generate(4, (i) => now.subtract(Duration(days: (3 - i) * 2)));
                        if (value.toInt() >= 0 && value.toInt() < dates.length) {
                          final date = dates[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('${date.day} ${_getMonthName(date.month)}',
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
                    color: Colors.blue,
                    barWidth: 2,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: Colors.blue,
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
                            color: Colors.blue, shape: BoxShape.circle))),
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
  final List leads;

  const _LeadsOverviewCard({required this.leads});

  @override
  State<_LeadsOverviewCard> createState() => _LeadsOverviewCardState();
}

class _LeadsOverviewCardState extends State<_LeadsOverviewCard> {
  String _selectedTab = 'Fresh Leads';

  @override
  Widget build(BuildContext context) {
    final filteredLeads = _selectedTab == 'Fresh Leads'
        ? widget.leads.where((lead) => lead.isFresh).toList()
        : _selectedTab == 'Appointment Scheduled'
            ? widget.leads.where((lead) => lead.followUpDate != null && !lead.isOverdue && !lead.isCompleted).toList()
            : widget.leads.where((lead) => lead.followUpDate != null && !lead.isOverdue && !lead.isCompleted).toList();
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
                  child: _TabButton('Fresh Leads', _selectedTab == 'Fresh Leads'),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTab = 'Appointment Scheduled';
                    });
                  },
                  child: _TabButton('Appointment Scheduled', _selectedTab == 'Appointment Scheduled'),
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
              itemBuilder: (context, index) {
                final lead = filteredLeads[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lead.contactName,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            if (lead.phone != null)
                              Text('Phone: ${lead.phone}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            if (lead.email != null)
                              Text('Email: ${lead.email}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            if (lead.service != null)
                              Text('Service: ${lead.service}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      const Icon(Icons.visibility_outlined,
                          size: 20, color: Colors.blue),
                    ],
                  ),
                );
              },
            ),
        ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue[50] : Colors.transparent,
        border: Border.all(color: isActive ? Colors.blue : Colors.grey[300]!),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              color: isActive ? Colors.blue : Colors.grey[600], fontSize: 11)),
    );
  }
}
