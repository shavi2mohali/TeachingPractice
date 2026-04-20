import 'package:flutter/material.dart';

import '../../../auth/presentation/widgets/home_logout_actions.dart';
import '../../../students/presentation/pages/view_students_page.dart';
import 'attendance_page.dart';

class SchoolDashboard extends StatelessWidget {
  const SchoolDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SchoolDashboard'),
        actions: const [HomeLogoutActions()],
      ),
      body: Center(
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
    );
  }
}
