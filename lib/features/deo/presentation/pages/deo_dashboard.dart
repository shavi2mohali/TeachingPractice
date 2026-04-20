import 'package:flutter/material.dart';

import 'proposal_review_page.dart';

class DeoDashboard extends StatelessWidget {
  const DeoDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DeoDashboard')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ProposalReviewPage(),
              ),
            );
          },
          child: const Text('Review Proposals'),
        ),
      ),
    );
  }
}
