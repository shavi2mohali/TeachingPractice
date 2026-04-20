import 'package:flutter/material.dart';

import '../../../../core/constants/registration_constants.dart';
import '../widgets/home_logout_actions.dart';

class ApprovalPendingPage extends StatelessWidget {
  const ApprovalPendingPage({
    super.key,
    this.registrationNumber,
    this.message = RegistrationConstants.registrationPendingMessage,
  });

  final String? registrationNumber;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approval Pending'),
        actions: const [HomeLogoutActions()],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.hourglass_top, size: 48),
                  const SizedBox(height: 16),
                  if (registrationNumber != null) ...[
                    Text('Registration Number: $registrationNumber'),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
