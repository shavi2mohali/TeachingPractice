import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/firebase/firestore_service.dart';
import '../../../admin/data/models/school_model.dart';
import '../../../admin/data/models/student_model.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/proposal_model.dart';

class ProposeSchoolPage extends StatefulWidget {
  const ProposeSchoolPage({super.key});

  @override
  State<ProposeSchoolPage> createState() => _ProposeSchoolPageState();
}

class _ProposeSchoolPageState extends State<ProposeSchoolPage> {
  final FirestoreService _firestoreService = FirestoreService();

  String? _selectedStudentId;
  String? _selectedSchoolId;
  bool _isSubmitting = false;

  Future<void> _submitProposal(AppUserContext userContext) async {
    final studentId = _selectedStudentId;
    final schoolId = _selectedSchoolId;

    if (studentId == null || schoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select student and school')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final proposal = ProposalModel(
        proposalId: '',
        studentId: studentId,
        collegeId: userContext.collegeId,
        proposedSchoolId: schoolId,
        districtId: userContext.districtId,
        status: 'pending',
        proposedBy: userContext.uid,
        proposedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      await _firestoreService.createProposal(proposal);

      if (!mounted) return;

      setState(() {
        _selectedStudentId = null;
        _selectedSchoolId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proposal submitted')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to submit proposal: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Login required')),
      );
    }

    final userContext = AppUserContext.fromUser(currentUser);

    if (userContext.collegeId.isEmpty || userContext.districtId.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('College or district is not assigned to this user'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Propose School')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StudentDropdown(
                  firestoreService: _firestoreService,
                  collegeId: userContext.collegeId,
                  selectedStudentId: _selectedStudentId,
                  onChanged: (studentId) {
                    setState(() => _selectedStudentId = studentId);
                  },
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<SchoolModel>>(
                  stream: _firestoreService.streamSchoolsByDistrict(
                    userContext.districtId,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Text('Unable to load schools: ${snapshot.error}');
                    }

                    final schools = snapshot.data ?? [];

                    if (schools.isEmpty) {
                      return const Text('No schools found for this district');
                    }

                    final selectedSchoolValue = schools.any(
                      (school) => school.schoolId == _selectedSchoolId,
                    )
                        ? _selectedSchoolId
                        : null;

                    return DropdownButtonFormField<String>(
                      value: selectedSchoolValue,
                      decoration: const InputDecoration(
                        labelText: 'Select school',
                        border: OutlineInputBorder(),
                      ),
                      items: schools
                          .map(
                            (school) => DropdownMenuItem<String>(
                              value: school.schoolId,
                              child: Text(school.name),
                            ),
                          )
                          .toList(),
                      onChanged: _isSubmitting
                          ? null
                          : (schoolId) {
                              setState(() => _selectedSchoolId = schoolId);
                            },
                    );
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => _submitProposal(userContext),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Proposal'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentDropdown extends StatelessWidget {
  const _StudentDropdown({
    required this.firestoreService,
    required this.collegeId,
    required this.selectedStudentId,
    required this.onChanged,
  });

  final FirestoreService firestoreService;
  final String collegeId;
  final String? selectedStudentId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StudentModel>>(
      stream: firestoreService.streamStudentsByCollege(collegeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('Unable to load students: ${snapshot.error}');
        }

        final students = (snapshot.data ?? [])
            .where((student) => student.status == 'created')
            .toList();

        if (students.isEmpty) {
          return const Text('No students available for proposal');
        }

        final selectedStudentValue = students.any(
          (student) => student.studentId == selectedStudentId,
        )
            ? selectedStudentId
            : null;

        return DropdownButtonFormField<String>(
          value: selectedStudentValue,
          decoration: const InputDecoration(
            labelText: 'Select student',
            border: OutlineInputBorder(),
          ),
          items: students
              .map(
                (student) => DropdownMenuItem<String>(
                  value: student.studentId,
                  child: Text(student.name),
                ),
              )
              .toList(),
          onChanged: onChanged,
        );
      },
    );
  }
}

class AppUserContext {
  final String uid;
  final String collegeId;
  final String districtId;

  const AppUserContext({
    required this.uid,
    required this.collegeId,
    required this.districtId,
  });

  factory AppUserContext.fromUser(UserModel user) {
    return AppUserContext(
      uid: user.uid,
      collegeId: user.collegeId ?? user.uid,
      districtId: user.districtId ?? '',
    );
  }
}
