import 'package:flutter/material.dart';

import '../../core/constants/user_roles.dart';
import '../../features/admin/presentation/pages/admin_dashboard.dart';
import '../../features/college/presentation/pages/college_dashboard.dart';
import '../../features/deo/presentation/pages/deo_dashboard.dart';
import '../../features/diet/presentation/pages/diet_dashboard.dart';
import '../../features/school/presentation/pages/school_dashboard.dart';

class RoleNavigation {
  const RoleNavigation._();

  static Widget dashboardForRole(String role) {
    switch (role.toLowerCase().trim()) {
      case UserRoles.admin:
        return const AdminDashboard();
      case UserRoles.college:
        return const CollegeDashboard();
      case UserRoles.deo:
        return const DeoDashboard();
      case UserRoles.diet:
        return const DietDashboard();
      case UserRoles.school:
        return const SchoolDashboard();
      default:
        throw ArgumentError('Unsupported user role: $role');
    }
  }

  static Future<void> navigateToDashboard({
    required BuildContext context,
    required String role,
  }) async {
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => dashboardForRole(role)),
      (_) => false,
    );
  }
}
