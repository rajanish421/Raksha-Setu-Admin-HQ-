import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:raksha_setu_admin/features/dashboard/screens/admin_management_screen.dart';
import 'package:raksha_setu_admin/features/dashboard/screens/alerts_screen.dart';
import 'package:raksha_setu_admin/features/dashboard/screens/groups_screen.dart';
import 'package:raksha_setu_admin/features/dashboard/screens/logs_screen.dart';
import 'package:raksha_setu_admin/features/dashboard/screens/notifications_screen.dart';
import 'package:raksha_setu_admin/features/dashboard/screens/pending_users_screen.dart';
import 'package:raksha_setu_admin/features/dashboard/screens/user_management_screen.dart';
import '../../constant/app_colors.dart';
import 'screens/dashboard_home_screen.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();


}

class _DashboardShellState extends State<DashboardShell> {



  int newAlertCount = 0;

  @override
  void initState() {
    super.initState();

    FirebaseFirestore.instance
        .collection("alerts")
        .where("status", isEqualTo: "pending")
        .snapshots()
        .listen((snap) {
      setState(() {
        newAlertCount = snap.docs.length;
      });
    });
  }




  Widget _menuItem(IconData icon, String label, int index) {
    final selected = _selected == index;

    // Special case: Alerts menu -> show red badge
    final isAlertsMenu = label == "Alerts";

    return InkWell(
      onTap: () => setState(() => _selected = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.25) : Colors.transparent,
          border: selected
              ? const Border(
            left: BorderSide(color: AppColors.accent, width: 5),
          )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? AppColors.accent : AppColors.textSecondary,
            ),
            const SizedBox(width: 14),

            // Sidebar Label + optional badge
            Expanded(
              child: Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),

                  if (isAlertsMenu && newAlertCount > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        newAlertCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }




  int _selected = 0;

  // final List<String> _menu = [
  //   "Dashboard",
  //   "User Management",
  //   "Groups",
  //   "Alerts"
  //   "Admin Management",
  //   "Logs",
  // ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // LEFT SIDEBAR
          Container(
            width: 250,
            decoration: const BoxDecoration(
              color: AppColors.surface,
            ),
            child: Column(
              children: [
                const SizedBox(height: 30),
                const Icon(Icons.shield, size: 52, color: AppColors.accent),
                const SizedBox(height: 10),
                const Text(
                  "DEFENCE HQ",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child:  ListView(
                    children: [
                      _menuItem(Icons.dashboard, "Dashboard", 0),
                      _menuItem(Icons.verified_user, "User Management", 1),
                      _menuItem(Icons.group, "Groups", 2),
                      _menuItem(Icons.notification_important, "Alerts", 3),   // Badge added automatically
                      _menuItem(Icons.admin_panel_settings, "Admin Management", 4),
                      _menuItem(Icons.event_note, "Logs", 5),
                      _menuItem(Icons.notifications, "Notifications", 6),

                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: () async {
                    // Handled in screen later
                    Navigator.pushReplacementNamed(context, "/login");
                  },
                  icon: const Icon(Icons.logout, color: AppColors.danger),
                  label: const Text("Logout",
                      style: TextStyle(color: AppColors.danger)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // CONTENT AREA
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildScreen(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreen() {
    switch (_selected) {
      case 0:
        return const DashboardHomeScreen();

      case 1:
        return const UserManagementScreen(); // NEW

      case 2:
        return const GroupsScreen();

      case 3:
        return const AlertsScreen();

      case 4:
        return const AdminManagementScreen();

      case 5:
        return const LogsScreen();

      case 6:
        return const NotificationsScreen();


      default:
        return const Center(
          child: Text(
            "Screen coming next...",
            style: TextStyle(color: AppColors.textPrimary),
          ),
        );
    }
  }


}
