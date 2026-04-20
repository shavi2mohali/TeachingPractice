import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../admin/pending_registrations_screen.dart';
import '../../../../admin_web/features/schools/presentation/pages/school_excel_upload_page.dart';
import '../../../../admin_web/features/students/presentation/pages/student_excel_upload_page.dart';
import '../../../auth/presentation/widgets/home_logout_actions.dart';
import '../../../students/presentation/pages/view_students_page.dart';
import 'manage_schools_placeholder_page.dart';
import 'view_proposals_placeholder_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isSeedingColleges = false;

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
                        title: 'Manage Schools',
                        icon: Icons.school_outlined,
                        onTap: () => _openPage(
                          context,
                          const ManageSchoolsPlaceholderPage(),
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
                      _AdminHomeCard(
                        title: _isSeedingColleges
                            ? 'Seeding Colleges...'
                            : 'Seed Colleges Data',
                        icon: Icons.dataset_outlined,
                        onTap: _isSeedingColleges ? null : _seedCollegesData,
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

  Future<void> _seedCollegesData() async {
    setState(() => _isSeedingColleges = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      final colleges = firestore.collection('colleges');

      for (final college in _collegeSeedData) {
        final collegeId = college['collegeId']!;
        batch.set(colleges.doc(collegeId), college);
      }

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Colleges data seeded successfully')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to seed colleges data: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSeedingColleges = false);
      }
    }
  }

  void _openPage(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }
}

const List<Map<String, String>> _collegeSeedData = [
  {
    'collegeId': 'C001',
    'name':
        'Akal College of Physical Education, Gurusagar Mastuana Saahib (Sangrur)',
    'districtId': 'Sangrur',
    'shortName': 'Akal College Sangrur',
  },
  {
    'collegeId': 'C002',
    'name': 'Govind National College of Physical Education, Narangwal Ludhiana',
    'districtId': 'Ludhiana',
    'shortName': 'Govind College Ludhiana',
  },
  {
    'collegeId': 'C003',
    'name': 'Khalsa College of Physical Education, Amritsar',
    'districtId': 'Amritsar',
    'shortName': 'Khalsa College Amritsar',
  },
  {
    'collegeId': 'C004',
    'name': 'Malwa College of Physical Education, Bathinda',
    'districtId': 'Bathinda',
    'shortName': 'Malwa College Bathinda',
  },
  {
    'collegeId': 'C005',
    'name':
        'Mata Gurdev Kaur Shahi College of Physical Education, Jhakdaudi Ludhiana',
    'districtId': 'Ludhiana',
    'shortName': 'Mata Gurdev College Ludhiana',
  },
  {
    'collegeId': 'C006',
    'name':
        'Professor Gursewak Singh Government College of Physical Education, Patiala',
    'districtId': 'Patiala',
    'shortName': 'Govt College Patiala',
  },
  {
    'collegeId': 'C007',
    'name': 'S. Rajinder Chahal College of Physical Education, Kalyan Patiala',
    'districtId': 'Patiala',
    'shortName': 'Rajinder Chahal College Patiala',
  },
  {
    'collegeId': 'C008',
    'name': 'Saint Soldier College of Physical Education, Lidran Jalandhar',
    'districtId': 'Jalandhar',
    'shortName': 'Saint Soldier Jalandhar',
  },
  {
    'collegeId': 'C009',
    'name': 'Shaheed Kansi Ram College of Physical Education, Bhago Majra Mohali',
    'districtId': 'SAS Nagar',
    'shortName': 'Shaheed Kansi Ram Mohali',
  },
  {
    'collegeId': 'C010',
    'name': 'Shri Guru Gobind Singh Khalsa College, Mehadpur Hoshiarpur',
    'districtId': 'Hoshiarpur',
    'shortName': 'SGGS Khalsa Hoshiarpur',
  },
  {
    'collegeId': 'C011',
    'name': 'The Enlightened College of Physical Education, Jhunir Mansa',
    'districtId': 'Mansa',
    'shortName': 'Enlightened College Mansa',
  },
];

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
