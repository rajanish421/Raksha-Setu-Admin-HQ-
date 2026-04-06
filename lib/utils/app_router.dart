import 'package:flutter/material.dart';
import 'package:raksha_setu_admin/features/auth/screens/force_password_reset_screen.dart';

import '../features/auth/screens/admin_login_screen.dart';
import '../features/dashboard/dashboard_shell.dart';
import '../features/dashboard/screens/dashboard_home_screen.dart';
import 'route_names.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.login:
        return _buildRoute(const AdminLoginScreen(), settings);


      case RouteNames.dashboard:
        return _buildRoute(const DashboardShell(), settings);

      case RouteNames.force_reset:
        return _buildRoute(const ForcePasswordResetScreen(), settings);


      default:
        return _buildRoute(const AdminLoginScreen(), settings);
    }
  }

  static PageRoute _buildRoute(Widget child, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => child,
      settings: settings,
    );
  }
}
