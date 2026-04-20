import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/home_logout_actions.dart';
import '../../../students/presentation/pages/view_students_page.dart';
import 'propose_school_page.dart';

class CollegeDashboard extends StatelessWidget {
  const CollegeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final collegeId = user?.collegeId ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('College Dashboard'),
        actions: const [HomeLogoutActions()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _CollegeHeading(collegeId: collegeId),
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
                          builder: (_) => const ProposeSchoolPage(),
                        ),
                      );
                    },
                    child: const Text('Propose School'),
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

class _CollegeHeading extends StatelessWidget {
  const _CollegeHeading({required this.collegeId});

  final String collegeId;

  @override
  Widget build(BuildContext context) {
    if (collegeId.isEmpty) {
      return _DashboardHeading(text: 'College Dashboard');
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('colleges')
          .doc(collegeId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final collegeName =
            data?['name'] as String? ?? data?['shortName'] as String?;

        return _DashboardHeading(
          text: collegeName?.trim().isNotEmpty == true
              ? collegeName!
              : 'College Dashboard',
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
