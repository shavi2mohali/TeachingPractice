import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/firebase/firestore_service.dart';
import '../../../admin/data/models/school_model.dart';
import '../../../admin/data/models/student_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../college/data/models/proposal_model.dart';

class ProposalReviewPage extends StatefulWidget {
  const ProposalReviewPage({super.key});

  @override
  State<ProposalReviewPage> createState() => _ProposalReviewPageState();
}

class _ProposalReviewPageState extends State<ProposalReviewPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _districtController = TextEditingController();
  final Set<String> _processingProposalIds = {};
  String? _districtFilter;
  bool _hasInitializedDistrict = false;

  @override
  void dispose() {
    _districtController.dispose();
    super.dispose();
  }

  Future<_ProposalDetails> _loadProposalDetails(ProposalModel proposal) async {
    final results = await Future.wait<Object?>([
      _firestoreService.getStudentById(proposal.studentId),
      _firestoreService.getSchoolById(proposal.proposedSchoolId),
    ]);

    return _ProposalDetails(
      proposal: proposal,
      student: results[0] as StudentModel?,
      school: results[1] as SchoolModel?,
    );
  }

  Future<void> _approveProposal({
    required ProposalModel proposal,
    required String reviewedBy,
  }) async {
    await _runProposalAction(
      proposalId: proposal.proposalId,
      successMessage: 'Proposal approved',
      action: () => _firestoreService.approveProposal(
        proposalId: proposal.proposalId,
        studentId: proposal.studentId,
        reviewedBy: reviewedBy,
      ),
    );
  }

  Future<void> _rejectProposal({
    required ProposalModel proposal,
    required String reviewedBy,
  }) async {
    await _runProposalAction(
      proposalId: proposal.proposalId,
      successMessage: 'Proposal rejected',
      action: () => _firestoreService.rejectProposal(
        proposalId: proposal.proposalId,
        studentId: proposal.studentId,
        reviewedBy: reviewedBy,
      ),
    );
  }

  Future<void> _runProposalAction({
    required String proposalId,
    required String successMessage,
    required Future<void> Function() action,
  }) async {
    setState(() => _processingProposalIds.add(proposalId));

    try {
      await action();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update proposal: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _processingProposalIds.remove(proposalId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().currentUser;
    final reviewedBy = currentUser?.uid ?? '';

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Login required')),
      );
    }

    if (!_hasInitializedDistrict) {
      _districtFilter = currentUser.districtId ?? '';
      _districtController.text = _districtFilter ?? '';
      _hasInitializedDistrict = true;
    }

    final districtId = _districtFilter?.trim() ?? '';

    if (districtId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('District is not assigned to this user')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Proposal Review')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _districtController,
              decoration: InputDecoration(
                labelText: 'District ID',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _districtFilter = _districtController.text.trim();
                    });
                  },
                ),
              ),
              onSubmitted: (value) {
                setState(() => _districtFilter = value.trim());
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ProposalModel>>(
              stream: _firestoreService.streamPendingProposalsByDistrict(
                districtId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Unable to load proposals: ${snapshot.error}'),
                  );
                }

                final proposals = snapshot.data ?? [];

                if (proposals.isEmpty) {
                  return const Center(child: Text('No pending proposals'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: proposals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final proposal = proposals[index];

                    return FutureBuilder<_ProposalDetails>(
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

                        return _ProposalCard(
                          details: details,
                          isProcessing: _processingProposalIds.contains(
                            proposal.proposalId,
                          ),
                          onApprove: () => _approveProposal(
                            proposal: proposal,
                            reviewedBy: reviewedBy,
                          ),
                          onReject: () => _rejectProposal(
                            proposal: proposal,
                            reviewedBy: reviewedBy,
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({
    required this.details,
    required this.isProcessing,
    required this.onApprove,
    required this.onReject,
  });

  final _ProposalDetails details;
  final bool isProcessing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final student = details.student;
    final school = details.school;

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
            Text('School: ${school?.name ?? 'School not found'}'),
            Text('Status: ${details.proposal.status}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: isProcessing ? null : onReject,
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isProcessing ? null : onApprove,
                  child: isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProposalDetails {
  final ProposalModel proposal;
  final StudentModel? student;
  final SchoolModel? school;

  const _ProposalDetails({
    required this.proposal,
    required this.student,
    required this.school,
  });
}
