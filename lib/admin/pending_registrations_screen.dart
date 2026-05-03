import 'package:flutter/material.dart';

import '../core/firebase/firestore_service.dart';
import '../features/admin/data/services/registration_history_report_service.dart';
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
  final RegistrationHistoryReportService _historyReportService =
      RegistrationHistoryReportService();
  final Set<String> _processingUids = {};
  bool _isDownloadingHistory = false;

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

  Future<void> _downloadHistoryAsExcel() async {
    setState(() => _isDownloadingHistory = true);

    try {
      await _historyReportService.downloadHistoryReport();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('History report downloaded successfully')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to download history report: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isDownloadingHistory = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrations'),
        actions: const [HomeLogoutActions()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pending Registrations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Expanded(
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

                  return _RegistrationsTable(
                    registrations: registrations,
                    processingUids: _processingUids,
                    onApprove: _approve,
                    onReject: _reject,
                    showActions: true,
                    showStatus: false,
                    timestampLabel: 'Created At',
                    timestampBuilder: (registration) =>
                        _formatDateTime(registration.createdAt),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'History',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                FilledButton.icon(
                  onPressed:
                      _isDownloadingHistory ? null : _downloadHistoryAsExcel,
                  icon: _isDownloadingHistory
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_outlined),
                  label: const Text('Download History as Excel'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<PendingRegistration>>(
                stream: _firestoreService.streamRegistrationHistory(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Unable to load history: ${snapshot.error}'),
                    );
                  }

                  final registrations = snapshot.data ?? [];

                  if (registrations.isEmpty) {
                    return const Center(child: Text('No registration history'));
                  }

                  return _RegistrationsTable(
                    registrations: registrations,
                    processingUids: _processingUids,
                    onApprove: _approve,
                    onReject: _reject,
                    showActions: false,
                    showStatus: true,
                    timestampLabel: 'Actioned At',
                    timestampBuilder: (registration) =>
                        _formatDateTime(registration.actionedAt),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    if (date.millisecondsSinceEpoch == 0) return '-';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().padLeft(4, '0');
    final hour = (date.hour % 12 == 0 ? 12 : date.hour % 12)
        .toString()
        .padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    return '$day-$month-$year $hour:$minute $suffix';
  }
}

class _RegistrationsTable extends StatelessWidget {
  const _RegistrationsTable({
    required this.registrations,
    required this.processingUids,
    required this.onApprove,
    required this.onReject,
    required this.showActions,
    required this.showStatus,
    required this.timestampLabel,
    required this.timestampBuilder,
  });

  final List<PendingRegistration> registrations;
  final Set<String> processingUids;
  final ValueChanged<String> onApprove;
  final ValueChanged<String> onReject;
  final bool showActions;
  final bool showStatus;
  final String timestampLabel;
  final String Function(PendingRegistration registration) timestampBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalController = ScrollController();
        final verticalController = ScrollController();

        final rows = registrations.map((registration) {
          final statusColor = registration.status.toLowerCase() == 'approved'
              ? Colors.green
              : registration.status.toLowerCase() == 'rejected'
                  ? Colors.red
                  : null;

          TextStyle? coloredStyle([FontWeight? fontWeight]) => statusColor ==
                  null
              ? null
              : TextStyle(
                  color: statusColor,
                  fontWeight: fontWeight,
                );

          return DataRow(
            cells: [
              DataCell(
                Text(
                  registration.registrationNumber,
                  style: coloredStyle(),
                ),
              ),
              DataCell(
                Text(
                  registration.entityName,
                  style: coloredStyle(),
                ),
              ),
              DataCell(
                Text(
                  registration.officerName,
                  style: coloredStyle(),
                ),
              ),
              DataCell(Text(registration.mobile, style: coloredStyle())),
              DataCell(Text(registration.email, style: coloredStyle())),
              DataCell(Text(registration.role, style: coloredStyle())),
              DataCell(Text(registration.districtId, style: coloredStyle())),
              if (showStatus)
                DataCell(
                  Text(
                    registration.status,
                    style: coloredStyle(FontWeight.w700),
                  ),
                ),
              DataCell(
                Text(
                  timestampBuilder(registration),
                  style: coloredStyle(),
                ),
              ),
              if (showActions)
                DataCell(
                  _RegistrationActions(
                    isProcessing: processingUids.contains(registration.uid),
                    onApprove: () => onApprove(registration.uid),
                    onReject: () => onReject(registration.uid),
                  ),
                ),
            ],
          );
        }).toList();

        return Scrollbar(
          controller: horizontalController,
          thumbVisibility: true,
          notificationPredicate: (notification) {
            return notification.metrics.axis == Axis.horizontal;
          },
          child: SingleChildScrollView(
            controller: horizontalController,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Scrollbar(
                controller: verticalController,
                thumbVisibility: true,
                notificationPredicate: (notification) {
                  return notification.metrics.axis == Axis.vertical;
                },
                child: SingleChildScrollView(
                  controller: verticalController,
                  child: DataTable(
                    columns: [
                      const DataColumn(label: Text('Registration No.')),
                      const DataColumn(label: Text('Entity Name')),
                      const DataColumn(label: Text('Officer Name')),
                      const DataColumn(label: Text('Mobile')),
                      const DataColumn(label: Text('Email')),
                      const DataColumn(label: Text('Role')),
                      const DataColumn(label: Text('District')),
                      if (showStatus) const DataColumn(label: Text('Status')),
                      DataColumn(label: Text(timestampLabel)),
                      if (showActions) const DataColumn(label: Text('Actions')),
                    ],
                    rows: rows,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
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
