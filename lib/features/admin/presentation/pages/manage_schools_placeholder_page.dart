import 'package:flutter/material.dart';

import '../../../auth/presentation/widgets/home_logout_actions.dart';

class ManageSchoolsPlaceholderPage extends StatelessWidget {
  const ManageSchoolsPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Schools'),
        actions: const [HomeLogoutActions()],
      ),
      body: const Center(child: Text('Manage Schools')),
    );
  }
}
