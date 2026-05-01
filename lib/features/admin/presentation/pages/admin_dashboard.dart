import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../admin/pending_registrations_screen.dart';
import '../../../../admin_web/features/schools/presentation/pages/school_excel_upload_page.dart';
import '../../../../admin_web/features/students/presentation/pages/student_excel_upload_page.dart';
import '../../../auth/presentation/widgets/home_logout_actions.dart';
import '../../../students/presentation/pages/view_students_page.dart';
import 'student_status_overview_page.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: const [HomeLogoutActions()],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'Admin Dashboard',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.4,
                    children: [
                      _AdminHomeCard(
                        title: 'Upload Students',
                        icon: Icons.upload_file,
                        onTap: () => _openPage(
                          context,
                          const StudentExcelUploadPage(),
                        ),
                      ),
                      _AdminHomeCard(
                        title: 'View Students',
                        icon: Icons.people_outline,
                        onTap: () => _openPage(
                          context,
                          const ViewStudentsPage(),
                        ),
                      ),
                      _AdminHomeCard(
                        title: 'Upload Schools from Excel',
                        icon: Icons.maps_home_work_outlined,
                        onTap: () => _openPage(
                          context,
                          const SchoolExcelUploadPage(),
                        ),
                      ),
                      _AdminHomeCard(
                        title: 'Registrations',
                        icon: Icons.how_to_reg_outlined,
                        onTap: () => _openPage(
                          context,
                          const PendingRegistrationsScreen(),
                        ),
                      ),
                      _AdminHomeCard(
                        title: 'Student Status Overview',
                        icon: Icons.analytics_outlined,
                        onTap: () => _openPage(
                          context,
                          const StudentStatusOverviewPage(),
                        ),
                      ),
                      _AdminHomeCard(
                        title: 'Reset All College Proposals',
                        icon: Icons.restart_alt_outlined,
                        onTap: () => _confirmResetAllCollegeProposals(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openPage(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  Future<void> _confirmResetAllCollegeProposals(BuildContext context) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset All College Proposals'),
          content: const Text(
            'Are you sure you want to reset all college proposals?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (shouldReset == true) {
      await resetAllCollegeProposals(context);
    }
  }

  Future<void> resetAllCollegeProposals(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final studentsSnapshot = await firestore.collection('students').get();

      WriteBatch batch = firestore.batch();
      var pendingOperations = 0;

      Future<void> commitBatchIfNeeded({bool force = false}) async {
        if (pendingOperations == 0) return;

        if (force || pendingOperations >= 450) {
          await batch.commit();
          batch = firestore.batch();
          pendingOperations = 0;
        }
      }

      for (final studentDoc in studentsSnapshot.docs) {
        final data = studentDoc.data();
        final hasProposalFields =
            data.containsKey('proposedSchoolId') ||
            data.containsKey('propoosaed at') ||
            data.containsKey('collegeProposalTimestamp') ||
            data.containsKey('proposedSchoolName') ||
            data.containsKey('submittedOn');

        if (!hasProposalFields) {
          continue;
        }

        batch.update(studentDoc.reference, {
          'proposedSchoolId': FieldValue.delete(),
          'propoosaed at': FieldValue.delete(),
          'collegeProposalTimestamp': FieldValue.delete(),
          'proposedSchoolName': FieldValue.delete(),
          'submittedOn': FieldValue.delete(),
          'updatedAt': Timestamp.now(),
        });
        pendingOperations++;
        await commitBatchIfNeeded();
      }

      await commitBatchIfNeeded(force: true);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('College proposals reset successfully')),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to reset college proposals: $error')),
      );
    }
  }
}

class _AdminHomeCard extends StatelessWidget {
  const _AdminHomeCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
