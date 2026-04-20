import 'package:flutter/material.dart';

class ManageSchoolsPlaceholderPage extends StatelessWidget {
  const ManageSchoolsPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Schools')),
      body: const Center(child: Text('Manage Schools')),
    );
  }
}
