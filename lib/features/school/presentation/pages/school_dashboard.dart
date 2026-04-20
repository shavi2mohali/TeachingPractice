import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/home_logout_actions.dart';
import '../../../students/presentation/pages/view_students_page.dart';
import 'attendance_page.dart';

class SchoolDashboard extends StatelessWidget {
  const SchoolDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final schoolId = context.watch<AuthProvider>().currentUser?.schoolId ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('School Dashboard'),
        actions: const [HomeLogoutActions()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _SchoolHeading(schoolId: schoolId),
            const SizedBox(height: 24),
            Center(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ViewStudentsPage(),
                        ),
                      );
                    },
                    child: const Text('View Students'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AttendancePage(),
                        ),
                      );
                    },
                    child: const Text('Mark Attendance'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SchoolHeading extends StatelessWidget {
  const _SchoolHeading({required this.schoolId});

  final String schoolId;

  @override
  Widget build(BuildContext context) {
    if (schoolId.isEmpty) {
      return _DashboardHeading(text: 'School Dashboard');
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .snapshots(),
      builder: (context, snapshot) {
        final schoolName = snapshot.data?.data()?['name'] as String?;

        return _DashboardHeading(
          text: schoolName?.trim().isNotEmpty == true
              ? schoolName!
              : 'School Dashboard',
        );
      },
    );
  }
}

class _DashboardHeading extends StatelessWidget {
  const _DashboardHeading({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }
}
