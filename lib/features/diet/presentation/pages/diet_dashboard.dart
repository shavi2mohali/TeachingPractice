import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/home_logout_actions.dart';
import '../../../students/presentation/pages/view_students_page.dart';
import 'final_assignment_page.dart';

class DietDashboard extends StatelessWidget {
  const DietDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final districtName =
        context.watch<AuthProvider>().currentUser?.districtId ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('DIET Dashboard'),
        actions: const [HomeLogoutActions()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _DashboardHeading(
              text: 'District Institute of Education and Training'
                  '${districtName.isEmpty ? '' : ' - $districtName'}',
            ),
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
                          builder: (_) => const FinalAssignmentPage(),
                        ),
                      );
                    },
                    child: const Text('Final Assignment'),
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
