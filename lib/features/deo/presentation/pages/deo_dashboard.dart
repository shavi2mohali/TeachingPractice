import 'package:flutter/material.dart';

import '../../../auth/presentation/widgets/home_logout_actions.dart';
import '../../../students/presentation/pages/view_students_page.dart';
import 'proposal_review_page.dart';

class DeoDashboard extends StatelessWidget {
  const DeoDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DeoDashboard'),
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
                    builder: (_) => const ProposalReviewPage(),
                  ),
                );
              },
              child: const Text('Review Proposals'),
            ),
          ],
        ),
      ),
    );
  }
}
