import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _StatCard('00', 'Fresh Leads',
                      Icons.phone_in_talk_outlined, Color(0xFFE3F2FD))),
              SizedBox(width: 16),
              Expanded(
                  child: _StatCard('00', 'Scheduled Appointments',
                      Icons.calendar_today_outlined, Color(0xFFE3F2FD))),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _StatCard('00', 'Followup Leads',
                      Icons.access_time_outlined, Color(0xFFE3F2FD))),
              SizedBox(width: 16),
              Expanded(
                  child: _StatCard('00', 'Overdue Leads',
                      Icons.warning_amber_outlined, Color(0xFFFFEBEE))),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _StatCard('00', 'Lost Leads',
                      Icons.person_off_outlined, Color(0xFFF5F5F5))),
              SizedBox(width: 16),
              Expanded(
                  child: _StatCard('00', 'Converted Leads',
                      Icons.check_circle_outline, Color(0xFFE8F5E9))),
            ],
          ),
          SizedBox(height: 24),
          _TaskManagementCard(),
          SizedBox(height: 16),
          _WeeklyReportCard(),
          SizedBox(height: 16),
          _MonthlyReportCard(),
          SizedBox(height: 16),
          _LeadsOverviewCard(),
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
  const _TaskManagementCard();

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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Task Management',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text('From 16 Feb - 15 May 2024',
                        style: TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ),
              Icon(Icons.tune, color: Colors.grey[400], size: 22),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildTaskRow('0', 'Today\'s Tasks')),
              const SizedBox(width: 16),
              Expanded(child: _buildTaskRow('0', 'Overdue Tasks')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTaskRow('0', 'Active Tasks')),
              const SizedBox(width: 16),
              const Expanded(child: SizedBox()),
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
}

class _WeeklyReportCard extends StatelessWidget {
  const _WeeklyReportCard();

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
                        const dates = ['21 Feb', '23 Feb', '25 Feb', '27 Feb'];
                        if (value.toInt() >= 0 &&
                            value.toInt() < dates.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(dates[value.toInt()],
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
  const _MonthlyReportCard();

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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monthly Report',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          SizedBox(height: 2),
          Text('Weekly Report',
              style: TextStyle(color: Colors.grey, fontSize: 10)),
          SizedBox(height: 30),
          Center(
              child: Text('Total',
                  style: TextStyle(color: Colors.grey, fontSize: 10))),
          SizedBox(height: 6),
          Center(
              child: Text('0',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold))),
          SizedBox(height: 30),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 20,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                    width: 12,
                    height: 12,
                    child: DecoratedBox(
                        decoration: BoxDecoration(
                            color: Colors.blue, shape: BoxShape.circle))),
                SizedBox(width: 6),
                Text('Won', style: TextStyle(fontSize: 11))
              ]),
              Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                    width: 12,
                    height: 12,
                    child: DecoratedBox(
                        decoration: BoxDecoration(
                            color: Colors.pink, shape: BoxShape.circle))),
                SizedBox(width: 6),
                Text('Lost', style: TextStyle(fontSize: 11))
              ]),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeadsOverviewCard extends StatelessWidget {
  const _LeadsOverviewCard();

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
          const Text('Leads Overview',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TabButton('Fresh Leads', true),
              _TabButton('Appointment Scheduled', false),
              _TabButton('Follow-up', false),
            ],
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 48,
              dataRowMaxHeight: 48,
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F9FA)),
              border: TableBorder.all(color: Colors.grey[300]!, width: 1),
              columns: const [
                DataColumn(
                    label: Text('#',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 11))),
                DataColumn(
                    label: Text('Name',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 11))),
                DataColumn(
                    label: Text('Contact Details',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 11))),
                DataColumn(
                    label: Text('Se',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 11))),
                DataColumn(
                    label: Text('Actions',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 11))),
              ],
              rows: const [],
            ),
          ),
          const SizedBox(height: 40),
          const Center(
              child: Text('No leads found.',
                  style: TextStyle(color: Colors.grey, fontSize: 11))),
          const SizedBox(height: 40),
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
