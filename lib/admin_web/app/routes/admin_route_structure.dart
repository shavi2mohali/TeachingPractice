import 'admin_route_names.dart';

class AdminRouteDefinition {
  final String name;
  final String path;
  final bool requiresAdmin;

  const AdminRouteDefinition({
    required this.name,
    required this.path,
    required this.requiresAdmin,
  });
}

class AdminRouteStructure {
  static const List<AdminRouteDefinition> routes = [
    AdminRouteDefinition(
      name: 'Login',
      path: AdminRouteNames.login,
      requiresAdmin: false,
    ),
    AdminRouteDefinition(
      name: 'Dashboard',
      path: AdminRouteNames.dashboard,
      requiresAdmin: true,
    ),
    AdminRouteDefinition(
      name: 'Students',
      path: AdminRouteNames.students,
      requiresAdmin: true,
    ),
    AdminRouteDefinition(
      name: 'Add Student',
      path: AdminRouteNames.addStudent,
      requiresAdmin: true,
    ),
    AdminRouteDefinition(
      name: 'Schools',
      path: AdminRouteNames.schools,
      requiresAdmin: true,
    ),
    AdminRouteDefinition(
      name: 'Add School',
      path: AdminRouteNames.addSchool,
      requiresAdmin: true,
    ),
    AdminRouteDefinition(
      name: 'Proposals',
      path: AdminRouteNames.proposals,
      requiresAdmin: true,
    ),
    AdminRouteDefinition(
      name: 'Attendance',
      path: AdminRouteNames.attendance,
      requiresAdmin: true,
    ),
    AdminRouteDefinition(
      name: 'Certificates',
      path: AdminRouteNames.certificates,
      requiresAdmin: true,
    ),
  ];

  const AdminRouteStructure._();
}
