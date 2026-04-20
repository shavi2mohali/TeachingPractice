import 'package:flutter/material.dart';

import '../../data/dashboard_firestore_service.dart';
import '../widgets/dashboard_stat_card.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final DashboardFirestoreService _dashboardService =
      DashboardFirestoreService();
  late final Stream<int> _studentsCountStream =
      _dashboardService.watchTotalStudents();
  late final Stream<int> _schoolsCountStream =
      _dashboardService.watchTotalSchools();
  late final Stream<int> _proposalsCountStream =
      _dashboardService.watchTotalProposals();
  late final Stream<int> _certificatesCountStream =
      _dashboardService.watchTotalCertificates();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth >= 1100
                      ? 4
                      : constraints.maxWidth >= 700
                          ? 2
                          : 1;

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.7,
                    children: [
                      DashboardStatCard(
                        title: 'Total Students',
                        countStream: _studentsCountStream,
                        icon: Icons.people_outline,
                      ),
                      DashboardStatCard(
                        title: 'Total Schools',
                        countStream: _schoolsCountStream,
                        icon: Icons.school_outlined,
                      ),
                      DashboardStatCard(
                        title: 'Total Proposals',
                        countStream: _proposalsCountStream,
                        icon: Icons.assignment_outlined,
                      ),
                      DashboardStatCard(
                        title: 'Total Certificates',
                        countStream: _certificatesCountStream,
                        icon: Icons.card_membership_outlined,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
