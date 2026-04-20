import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../pages/home_page.dart';
import '../providers/auth_provider.dart';

class HomeLogoutActions extends StatelessWidget {
  const HomeLogoutActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: () => _goHome(context),
          child: const Text('Home'),
        ),
        TextButton(
          onPressed: () async {
            await context.read<AuthProvider>().logout();

            if (!context.mounted) return;

            _goHome(context);
          },
          child: const Text('Logout'),
        ),
      ],
    );
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomePage()),
      (_) => false,
    );
  }
}
