import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/firebase/firestore_service.dart';
import '../../../admin/data/models/school_model.dart';
import '../../../admin/data/models/student_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../college/data/models/proposal_model.dart';

class FinalAssignmentPage extends StatefulWidget {
  const FinalAssignmentPage({super.key});

  @override
  State<FinalAssignmentPage> createState() => _FinalAssignmentPageState();
}

class _FinalAssignmentPageState extends State<FinalAssignmentPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final Map<String, String> _selectedSchoolIds = {};
  final Set<String> _processingProposalIds = {};

  Future<_DietProposalDetails> _loadProposalDetails(
    ProposalModel proposal,
  ) async {
    final results = await Future.wait<Object?>([
      _firestoreService.getStudentById(proposal.studentId),
      _firestoreService.getSchoolById(proposal.proposedSchoolId),
    ]);

    return _DietProposalDetails(
      proposal: proposal,
      student: results[0] as StudentModel?,
      proposedSchool: results[1] as SchoolModel?,
    );
  }

  Future<void> _assignSchool({
    required ProposalModel proposal,
    required String assignedBy,
  }) async {
    final selectedSchoolId = _selectedSchoolIds[proposal.proposalId] ??
        proposal.proposedSchoolId;

    setState(() => _processingProposalIds.add(proposal.proposalId));

    try {
      await _firestoreService.assignSchool(
        proposalId: proposal.proposalId,
        studentId: proposal.studentId,
        collegeId: proposal.collegeId,
        districtId: proposal.districtId,
        schoolId: selectedSchoolId,
        assignedBy: assignedBy,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('School assigned')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to assign school: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _processingProposalIds.remove(proposal.proposalId));
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

    final districtId = currentUser.districtId ?? '';

    if (districtId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('District is not assigned to this user')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Final Assignment')),
      body: StreamBuilder<List<ProposalModel>>(
        stream: _firestoreService.streamApprovedProposalsByDistrict(districtId),
        builder: (context, proposalSnapshot) {
          if (proposalSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (proposalSnapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load approved proposals: '
                '${proposalSnapshot.error}',
              ),
            );
          }

          final proposals = proposalSnapshot.data ?? [];

          if (proposals.isEmpty) {
            return const Center(child: Text('No approved proposals'));
          }

          return StreamBuilder<List<SchoolModel>>(
            stream: _firestoreService.streamSchoolsByDistrict(districtId),
            builder: (context, schoolSnapshot) {
              if (schoolSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (schoolSnapshot.hasError) {
                return Center(
                  child: Text('Unable to load schools: ${schoolSnapshot.error}'),
                );
              }

              final schools = schoolSnapshot.data ?? [];

              if (schools.isEmpty) {
                return const Center(child: Text('No schools found'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: proposals.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final proposal = proposals[index];

                  return FutureBuilder<_DietProposalDetails>(
                    future: _loadProposalDetails(proposal),
                    builder: (context, detailsSnapshot) {
                      if (detailsSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: LinearProgressIndicator(),
                          ),
                        );
                      }

                      if (detailsSnapshot.hasError) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Unable to load proposal details: '
                              '${detailsSnapshot.error}',
                            ),
                          ),
                        );
                      }

                      final details = detailsSnapshot.data;

                      if (details == null) {
                        return const SizedBox.shrink();
                      }

                      return _AssignmentCard(
                        details: details,
                        schools: schools,
                        selectedSchoolId:
                            _selectedSchoolIds[proposal.proposalId],
                        isProcessing: _processingProposalIds.contains(
                          proposal.proposalId,
                        ),
                        onSchoolChanged: (schoolId) {
                          if (schoolId == null) return;

                          setState(() {
                            _selectedSchoolIds[proposal.proposalId] = schoolId;
                          });
                        },
                        onAssign: () => _assignSchool(
                          proposal: proposal,
                          assignedBy: currentUser.uid,
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.details,
    required this.schools,
    required this.selectedSchoolId,
    required this.isProcessing,
    required this.onSchoolChanged,
    required this.onAssign,
  });

  final _DietProposalDetails details;
  final List<SchoolModel> schools;
  final String? selectedSchoolId;
  final bool isProcessing;
  final ValueChanged<String?> onSchoolChanged;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    final proposal = details.proposal;
    final student = details.student;
    final proposedSchool = details.proposedSchool;
    final dropdownValue = schools.any(
      (school) => school.schoolId == selectedSchoolId,
    )
        ? selectedSchoolId
        : schools.any((school) => school.schoolId == proposal.proposedSchoolId)
            ? proposal.proposedSchoolId
            : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              student?.name ?? 'Student not found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Registration: ${student?.registrationNumber ?? '-'}'),
            Text('Proposed school: ${proposedSchool?.name ?? '-'}'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: dropdownValue,
              decoration: const InputDecoration(
                labelText: 'Final school',
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
              onChanged: isProcessing ? null : onSchoolChanged,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: isProcessing || dropdownValue == null
                    ? null
                    : onAssign,
                child: isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Assign Final School'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DietProposalDetails {
  final ProposalModel proposal;
  final StudentModel? student;
  final SchoolModel? proposedSchool;

  const _DietProposalDetails({
    required this.proposal,
    required this.student,
    required this.proposedSchool,
  });
}
