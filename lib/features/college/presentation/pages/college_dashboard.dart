import 'package:flutter/material.dart';

import '../../../auth/presentation/widgets/home_logout_actions.dart';
import '../../../students/presentation/pages/view_students_page.dart';
import 'propose_school_page.dart';

class CollegeDashboard extends StatelessWidget {
  const CollegeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CollegeDashboard'),
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
                    builder: (_) => const ProposeSchoolPage(),
                  ),
                );
              },
              child: const Text('Propose School'),
            ),
          ],
        ),
      ),
    );
  }
}
