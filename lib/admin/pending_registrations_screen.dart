import 'package:flutter/material.dart';

import '../core/firebase/firestore_service.dart';
import '../features/auth/presentation/widgets/home_logout_actions.dart';

class PendingRegistrationsScreen extends StatefulWidget {
  const PendingRegistrationsScreen({super.key});

  @override
  State<PendingRegistrationsScreen> createState() =>
      _PendingRegistrationsScreenState();
}

class _PendingRegistrationsScreenState
    extends State<PendingRegistrationsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final Set<String> _processingUids = {};

  Future<void> _approve(String uid) async {
    await _runAction(
      uid: uid,
      message: 'Registration approved',
      action: () => _firestoreService.approveRegistration(uid),
    );
  }

  Future<void> _reject(String uid) async {
    await _runAction(
      uid: uid,
      message: 'Registration rejected',
      action: () => _firestoreService.rejectRegistration(uid),
    );
  }

  Future<void> _runAction({
    required String uid,
    required String message,
    required Future<void> Function() action,
  }) async {
    setState(() => _processingUids.add(uid));

    try {
      await action();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update registration: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _processingUids.remove(uid));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Registrations'),
        actions: const [HomeLogoutActions()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: StreamBuilder<List<PendingRegistration>>(
          stream: _firestoreService.streamPendingRegistrations(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Unable to load registrations: ${snapshot.error}'),
              );
            }

            final registrations = snapshot.data ?? [];

            if (registrations.isEmpty) {
              return const Center(child: Text('No pending registrations'));
            }

            return Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Registration No.')),
                      DataColumn(label: Text('Officer Name')),
                      DataColumn(label: Text('Mobile')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Role')),
                      DataColumn(label: Text('District')),
                      DataColumn(label: Text('Created At')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: registrations
                        .map(
                          (registration) => DataRow(
                            cells: [
                              DataCell(Text(registration.registrationNumber)),
                              DataCell(Text(registration.officerName)),
                              DataCell(Text(registration.mobile)),
                              DataCell(Text(registration.email)),
                              DataCell(Text(registration.role)),
                              DataCell(Text(registration.districtId)),
                              DataCell(Text(_formatDate(registration.createdAt))),
                              DataCell(
                                _RegistrationActions(
                                  isProcessing: _processingUids.contains(
                                    registration.uid,
                                  ),
                                  onApprove: () => _approve(registration.uid),
                                  onReject: () => _reject(registration.uid),
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    if (date.millisecondsSinceEpoch == 0) return '-';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().padLeft(4, '0');
    return '$day-$month-$year';
  }
}

class _RegistrationActions extends StatelessWidget {
  const _RegistrationActions({
    required this.isProcessing,
    required this.onApprove,
    required this.onReject,
  });

  final bool isProcessing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton(
          onPressed: isProcessing ? null : onApprove,
          child: const Text('Approve'),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: isProcessing ? null : onReject,
          child: const Text('Reject'),
        ),
      ],
    );
  }
}
