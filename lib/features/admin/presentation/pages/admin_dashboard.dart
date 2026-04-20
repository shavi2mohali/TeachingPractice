import 'package:flutter/material.dart';

import '../../../../admin/pending_registrations_screen.dart';
import '../../../../admin_web/features/students/presentation/pages/student_excel_upload_page.dart';
import '../../../auth/presentation/widgets/home_logout_actions.dart';
import '../../../students/presentation/pages/view_students_page.dart';
import 'manage_schools_placeholder_page.dart';
import 'view_proposals_placeholder_page.dart';

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
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 5,
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
                  title: 'Manage Schools',
                  icon: Icons.school_outlined,
                  onTap: () => _openPage(
                    context,
                    const ManageSchoolsPlaceholderPage(),
                  ),
                ),
                _AdminHomeCard(
                  title: 'View Proposals',
                  icon: Icons.assignment_outlined,
                  onTap: () => _openPage(
                    context,
                    const ViewProposalsPlaceholderPage(),
                  ),
                ),
                _AdminHomeCard(
                  title: 'Pending Registrations',
                  icon: Icons.how_to_reg_outlined,
                  onTap: () => _openPage(
                    context,
                    const PendingRegistrationsScreen(),
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
}

class _AdminHomeCard extends StatelessWidget {
  const _AdminHomeCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

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
