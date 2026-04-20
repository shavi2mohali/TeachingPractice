import 'package:flutter/material.dart';

import 'final_assignment_page.dart';

class DietDashboard extends StatelessWidget {
  const DietDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DietDashboard')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const FinalAssignmentPage(),
              ),
            );
          },
          child: const Text('Final Assignment'),
        ),
      ),
    );
  }
}
