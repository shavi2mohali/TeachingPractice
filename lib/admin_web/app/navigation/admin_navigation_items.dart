import '../routes/admin_route_names.dart';

class AdminNavigationItem {
  final String label;
  final String routeName;

  const AdminNavigationItem({
    required this.label,
    required this.routeName,
  });
}

class AdminNavigationItems {
  static const List<AdminNavigationItem> sidebarItems = [
    AdminNavigationItem(
      label: 'Dashboard',
      routeName: AdminRouteNames.dashboard,
    ),
    AdminNavigationItem(
      label: 'Students',
      routeName: AdminRouteNames.students,
    ),
    AdminNavigationItem(
      label: 'Schools',
      routeName: AdminRouteNames.schools,
    ),
    AdminNavigationItem(
      label: 'Proposals',
      routeName: AdminRouteNames.proposals,
    ),
    AdminNavigationItem(
      label: 'Attendance',
      routeName: AdminRouteNames.attendance,
    ),
    AdminNavigationItem(
      label: 'Certificates',
      routeName: AdminRouteNames.certificates,
    ),
  ];

  const AdminNavigationItems._();
}
