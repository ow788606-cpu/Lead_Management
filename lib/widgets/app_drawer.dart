import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/leads/add_new_lead_screen.dart';
import '../screens/leads/all_leads_screen.dart';
import '../screens/leads/fresh_leads_screen.dart';
import '../screens/leads/follow_ups_screen.dart';
import '../screens/leads/overdue_screen.dart';
import '../screens/leads/completed_screen.dart';
import '../screens/contacts/all_contacts_screen.dart';
import '../screens/contacts/new_contact_screen.dart';
import '../screens/contacts/bulk_upload_screen.dart';
import '../screens/tasks/new_task_screen.dart';
import '../screens/tasks/pending_tasks_screen.dart';
import '../screens/tasks/completed_tasks_screen.dart';

class AppDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const AppDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 80,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Colors.white),
              child: Row(
                children: [
                  Image.asset('assets/images/logo-md.webp', height: 32),
                  const SizedBox(width: 12),
                  const Text('Cloop', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('MAIN', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
            _DrawerItem(Icons.dashboard_outlined, 'Dashboard', 0, selectedIndex, () => onItemSelected(0), Colors.blue),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text('LET\'S CLOOP', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
            _ExpandableDrawerItem(Icons.phone_in_talk_outlined, 'Leads', 1, selectedIndex, () => onItemSelected(1), [
              _SubItem('Add New Lead', () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AddNewLeadScreen()));
              }),
              _SubItem('All Leads', () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AllLeadsScreen()));
              }),
              _SubItem('Fresh Leads', () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const FreshLeadsScreen()));
              }),
              _SubItem('Follow-Ups', () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const FollowUpsScreen()));
              }),
              _SubItem('Overdue', () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const OverdueScreen()));
              }),
              _SubItem('Completed', () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CompletedScreen()));
              }),
            ]),
            _DrawerItem(Icons.calendar_today_outlined, 'Appointments', 2, selectedIndex, () => onItemSelected(2), Colors.blue),
            _ExpandableDrawerItem(Icons.people_outline, 'Contacts', 3, selectedIndex, () => onItemSelected(3), [
              _SubItem('All Contacts', () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AllContactsScreen()));
              }),
              _SubItem('New Contact', () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const NewContactScreen()));
              }),
              _SubItem('Bulk Upload', () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const BulkUploadScreen()));
              }),
            ]),
            _ExpandableDrawerItem(Icons.task_alt_outlined, 'Tasks', 4, selectedIndex, () => onItemSelected(4), [
              _SubItem('New Task', () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const NewTaskScreen()));
              }),
              _SubItem('Pending Tasks', () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PendingTasksScreen()));
              }),
              _SubItem('Completed Tasks', () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CompletedTasksScreen()));
              }),
            ]),
            _DrawerItem(Icons.business_center_outlined, 'Services', 5, selectedIndex, () => onItemSelected(5), Colors.blue),
            _DrawerItem(Icons.local_offer_outlined, 'Tags', 6, selectedIndex, () => onItemSelected(6), Colors.blue),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text('REPORTS', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
            _ExpandableDrawerItem(Icons.bar_chart_outlined, 'Reports', -1, selectedIndex, () {}, [
              _SubItem('Lead Reports', () {}),
            ]),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text('MY ACCOUNT', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
            _ExpandableDrawerItem(Icons.person_outline, 'Profile', -2, selectedIndex, () {}, [
              _SubItem('Billing', () {}),
              _SubItem('Manage Profile', () {}),
              _SubItem('Change Password', () {}),
            ]),
            ListTile(
              leading: const Icon(Icons.logout, size: 18, color: Colors.blue),
              title: const Text('Logout', style: TextStyle(fontSize: 13)),
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              dense: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final int index;
  final int selectedIndex;
  final VoidCallback onTap;
  final Color iconColor;

  const _DrawerItem(this.icon, this.title, this.index, this.selectedIndex, this.onTap, this.iconColor);

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selectedIndex;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.white : iconColor, size: 18),
      title: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 13)),
      tileColor: isSelected ? Colors.blue : Colors.transparent,
      onTap: onTap,
      dense: true,
    );
  }
}

class _ExpandableDrawerItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final int index;
  final int selectedIndex;
  final VoidCallback onTap;
  final List<Widget> children;

  const _ExpandableDrawerItem(this.icon, this.title, this.index, this.selectedIndex, this.onTap, this.children);

  @override
  State<_ExpandableDrawerItem> createState() => _ExpandableDrawerItemState();
}

class _ExpandableDrawerItemState extends State<_ExpandableDrawerItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.index == widget.selectedIndex;
    return Column(
      children: [
        ListTile(
          leading: Icon(widget.icon, color: isSelected ? Colors.white : Colors.blue, size: 18),
          title: Text(widget.title, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 13)),
          trailing: Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 16, color: isSelected ? Colors.white : Colors.grey),
          tileColor: isSelected ? Colors.blue : Colors.transparent,
          onTap: () {
            setState(() => _isExpanded = !_isExpanded);
          },
          dense: true,
        ),
        if (_isExpanded) ...widget.children,
      ],
    );
  }
}

class _SubItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _SubItem(this.title, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 56),
      title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.black87)),
      onTap: onTap,
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
    );
  }
}
