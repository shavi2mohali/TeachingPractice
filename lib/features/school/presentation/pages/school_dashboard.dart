import 'package:flutter/material.dart';

import 'attendance_page.dart';

class SchoolDashboard extends StatelessWidget {
  const SchoolDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SchoolDashboard')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AttendancePage(),
              ),
            );
          },
          child: const Text('Mark Attendance'),
        ),
      ),
    );
  }
}
