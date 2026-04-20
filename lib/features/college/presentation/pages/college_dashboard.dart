import 'package:flutter/material.dart';

import 'propose_school_page.dart';

class CollegeDashboard extends StatelessWidget {
  const CollegeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CollegeDashboard')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ProposeSchoolPage(),
              ),
            );
          },
          child: const Text('Propose School'),
        ),
      ),
    );
  }
}
