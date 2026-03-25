import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../screens/main_screen.dart';
import '../screens/auth/login_screen.dart';
// import '../screens/auth/billing_screen.dart';
import '../screens/auth/manage_profile_screen.dart';
import '../screens/auth/change_password_screen.dart';

import '../screens/contacts/all_contacts_screen.dart';

// import '../screens/contacts/bulk_upload_screen.dart';

import '../screens/tasks/all_tasks_screen.dart';
// import '../screens/reports/lead_reports_screen.dart';

class AppDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const AppDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  static const Color _activeBgColor = Color(0xFF131416);

  @override
  Widget build(BuildContext context) {
    void openMainTab(int index) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (context) => MainScreen(initialIndex: index)),
        (route) => false,
      );
    }

    return Drawer(
      width: 250,
      backgroundColor: Colors.white,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: Colors.white),
              child: Center(
                child: Image.asset(
                  'assets/images/logo-dark.png',
                  height: 25,
                  fit: BoxFit.contain,
                  alignment: Alignment.topLeft,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text('MAIN',
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ),
            _DrawerItem(
                HugeIcons.strokeRoundedDashboardSquare01,
                'Dashboard',
                0,
                selectedIndex,
                () => openMainTab(0),
                const Color(0xFF131416),
                _activeBgColor),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Text('LET\'S CLOOP',
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ),
            _ExpandableDrawerItem(HugeIcons.strokeRoundedCall, 'Leads', 1,
                selectedIndex, () => onItemSelected(1), _activeBgColor, [
              _SubItem('All Leads', () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) => const MainScreen(
                          initialIndex: 1, initialLeadTabIndex: 0)),
                  (route) => false,
                );
              }),
            ]),
            _DrawerItem(
                HugeIcons.strokeRoundedCalendar03,
                'Appointments',
                2,
                selectedIndex,
                () => openMainTab(2),
                const Color(0xFF131416),
                _activeBgColor),
            _ExpandableDrawerItem(
                HugeIcons.strokeRoundedUserMultiple,
                'Contacts',
                3,
                selectedIndex,
                () => onItemSelected(3),
                _activeBgColor, [
              _SubItem('All Contacts', () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AllContactsScreen()));
              }),
              // _SubItem('Bulk Upload', () {
              //   Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //           builder: (context) => const BulkUploadScreen()));
              // }),
            ]),
            _ExpandableDrawerItem(HugeIcons.strokeRoundedTask01, 'Tasks', 4,
                selectedIndex, () => onItemSelected(4), _activeBgColor, [
              _SubItem('All Tasks', () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const AllTasksScreen(initialTabIndex: 0)));
              }),
            ]),
            _DrawerItem(
                HugeIcons.strokeRoundedCustomerService,
                'Services',
                5,
                selectedIndex,
                () => openMainTab(5),
                const Color(0xFF131416),
                _activeBgColor),
            _DrawerItem(HugeIcons.strokeRoundedTag01, 'Tags', 6, selectedIndex,
                () => openMainTab(6), const Color(0xFF131416), _activeBgColor),
            // const Padding(
            //   padding: EdgeInsets.fromLTRB(16, 10, 16, 6),
            //   child: Text('REPORTS',
            //       style: TextStyle(
            //           color: Colors.grey,
            //           fontSize: 10,
            //           fontWeight: FontWeight.w600)),
            // ),
            // _ExpandableDrawerItem(HugeIcons.strokeRoundedAnalytics01, 'Reports',
            //     -1, selectedIndex, () {}, _activeBgColor, [
            //   _SubItem('Lead Reports', () {
            //     Navigator.push(
            //         context,
            //         MaterialPageRoute(
            //             builder: (context) => const LeadReportsScreen()));
            //   }),
            // ]),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Text('MY ACCOUNT',
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ),
            _ExpandableDrawerItem(HugeIcons.strokeRoundedUser, 'Profile', -2,
                selectedIndex, () {}, _activeBgColor, [
              // _SubItem('Billing', () {
              //   Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //           builder: (context) => const BillingScreen()));
              // }),
              _SubItem('Manage Profile', () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ManageProfileScreen()));
              }),
              _SubItem('Change Password', () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ChangePasswordScreen()));
              }),
            ]),
            ListTile(
              leading: const HugeIcon(
                icon: HugeIcons.strokeRoundedLogout01,
                size: 18,
                color: Color(0xFF131416),
              ),
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
  final Color activeBgColor;

  const _DrawerItem(this.icon, this.title, this.index, this.selectedIndex,
      this.onTap, this.iconColor, this.activeBgColor);

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selectedIndex;
    return ListTile(
      leading: HugeIcon(
        icon: icon,
        color: isSelected ? Colors.white : iconColor,
        size: 18,
      ),
      title: Text(title,
          style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87, fontSize: 13)),
      tileColor: isSelected ? activeBgColor : Colors.transparent,
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
  final Color activeBgColor;
  final List<Widget> children;

  const _ExpandableDrawerItem(this.icon, this.title, this.index,
      this.selectedIndex, this.onTap, this.activeBgColor, this.children);

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
          leading: HugeIcon(
            icon: widget.icon,
            color: isSelected ? Colors.white : const Color(0xFF131416),
            size: 18,
          ),
          title: Text(widget.title,
              style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 13)),
          trailing: Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey),
          tileColor: isSelected ? widget.activeBgColor : Colors.transparent,
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
      title: Text(title,
          style: const TextStyle(fontSize: 12, color: Colors.black87)),
      onTap: onTap,
      dense: true,
      visualDensity: const VisualDensity(vertical: -2),
    );
  }
}
