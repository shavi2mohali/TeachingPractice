import 'package:flutter/material.dart';

import 'manage_schools_placeholder_page.dart';
import 'upload_students_placeholder_page.dart';
import 'view_proposals_placeholder_page.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(24),
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
                    const UploadStudentsPlaceholderPage(),
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
