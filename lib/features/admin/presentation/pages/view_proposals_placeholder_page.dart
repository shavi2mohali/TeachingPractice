import 'package:flutter/material.dart';

import '../../../auth/presentation/widgets/home_logout_actions.dart';

class ViewProposalsPlaceholderPage extends StatelessWidget {
  const ViewProposalsPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Proposals'),
        actions: const [HomeLogoutActions()],
      ),
      body: const Center(child: Text('View Proposals')),
    );
  }
}
