import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/firebase/firestore_service.dart';
import '../../../admin/data/services/file_download_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/home_logout_actions.dart';
import '../../data/models/exam_eligibility_submission.dart';
import '../widgets/two_axis_data_table_view.dart';

class DietExamEligibilityReviewPage extends StatefulWidget {
  const DietExamEligibilityReviewPage({super.key});

  @override
  State<DietExamEligibilityReviewPage> createState() =>
      _DietExamEligibilityReviewPageState();
}

class _DietExamEligibilityReviewPageState
    extends State<DietExamEligibilityReviewPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final Set<String> _processingSubmissionIds = {};

  String _streamDistrictId = '';
  String? _selectedCollegeId;
  String? _shownCollegeId;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _collegesStream;
  Stream<List<ExamEligibilitySubmission>>? _submissionsStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final districtId =
        (context.watch<AuthProvider>().currentUser?.districtId ?? '').trim();
    if (districtId == _streamDistrictId) return;

    _streamDistrictId = districtId;
    _selectedCollegeId = null;
    _shownCollegeId = null;
    _submissionsStream = null;
    _collegesStream = districtId.isEmpty
        ? null
        : FirebaseFirestore.instance
              .collection('colleges')
              .where('districtId', isEqualTo: districtId)
              .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final districtId = (user?.districtId ?? '').trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Eligibility Review'),
        actions: const [HomeLogoutActions()],
      ),
      body: districtId.isEmpty
          ? const Center(child: Text('District details not found'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _collegesStream,
              builder: (context, collegesSnapshot) {
                if (collegesSnapshot.hasError) {
                  return Center(
                    child: Text(
                      'Unable to load colleges: ${collegesSnapshot.error}',
                    ),
                  );
                }
                if (!collegesSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final collegeNames = <String, String>{
                  for (final college in collegesSnapshot.data!.docs)
                    college.id:
                        college.data()['name'] as String? ??
                        college.data()['shortName'] as String? ??
                        college.id,
                };
                final colleges = collegeNames.entries.toList()
                  ..sort(
                    (first, second) => first.value.compareTo(second.value),
                  );
                final selectedCollegeId =
                    collegeNames.containsKey(_selectedCollegeId)
                    ? _selectedCollegeId
                    : null;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: ValueKey(selectedCollegeId),
                              initialValue: selectedCollegeId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Select College',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                for (final college in colleges)
                                  DropdownMenuItem<String>(
                                    value: college.key,
                                    child: Text(
                                      college.value,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (value) => setState(() {
                                _selectedCollegeId = value;
                                _shownCollegeId = null;
                                _submissionsStream = null;
                              }),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: selectedCollegeId == null
                                ? null
                                : () => _showCollege(
                                    districtId,
                                    selectedCollegeId,
                                  ),
                            child: const Text('Show'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: colleges.isEmpty
                          ? const Center(
                              child: Text(
                                'No colleges found for this district',
                              ),
                            )
                          : _submissionsStream == null ||
                                !collegeNames.containsKey(_shownCollegeId)
                          ? const Center(
                              child: Text(
                                'Select a college to view eligibility submissions',
                              ),
                            )
                          : _buildSubmissionsTable(collegeNames, user!.uid),
                    ),
                  ],
                );
              },
            ),
    );
  }

  void _showCollege(String districtId, String collegeId) {
    setState(() {
      _shownCollegeId = collegeId;
      _submissionsStream = _firestoreService
          .streamExamEligibilitySubmissionsForDietReview(
            districtId: districtId,
            collegeId: collegeId,
          );
    });
  }

  Widget _buildSubmissionsTable(
    Map<String, String> collegeNames,
    String reviewerUid,
  ) {
    return StreamBuilder<List<ExamEligibilitySubmission>>(
      key: ValueKey(_shownCollegeId),
      stream: _submissionsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load eligibility submissions: ${snapshot.error}',
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final submissions = snapshot.data!;
        if (submissions.isEmpty) {
          return const Center(
            child: Text('No eligibility submissions found for this college'),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: TwoAxisDataTableView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Registration ID')),
                DataColumn(label: Text('Student Name')),
                DataColumn(label: Text('College')),
                DataColumn(label: Text('Total Working Days')),
                DataColumn(label: Text('Attended Working Days')),
                DataColumn(label: Text('Attendance %')),
                DataColumn(label: Text('TP Certificate')),
                DataColumn(label: Text('College Remarks')),
                DataColumn(label: Text('Current Status')),
                DataColumn(label: Text('Review Action')),
              ],
              rows: submissions
                  .map(
                    (submission) => _buildSubmissionRow(
                      submission,
                      collegeNames[submission.collegeId] ??
                          submission.collegeId,
                      reviewerUid,
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  DataRow _buildSubmissionRow(
    ExamEligibilitySubmission submission,
    String collegeName,
    String reviewerUid,
  ) {
    final percentage = ExamEligibilitySubmission.calculateAttendancePercentage(
      submission.attendedWorkingDays,
    );
    final meetsThreshold =
        submission.totalWorkingDays ==
            ExamEligibilitySubmission.requiredWorkingDays &&
        submission.attendedWorkingDays >=
            ExamEligibilitySubmission.minimumAttendedWorkingDays;
    final canReview =
        submission.status == ExamEligibilityStatus.submittedToDiet;
    final isProcessing = _processingSubmissionIds.contains(
      submission.submissionId,
    );

    return DataRow(
      cells: [
        DataCell(Text(submission.registrationId)),
        DataCell(Text(submission.studentName)),
        DataCell(Text(collegeName)),
        DataCell(Text(submission.totalWorkingDays.toString())),
        DataCell(Text(submission.attendedWorkingDays.toString())),
        DataCell(
          SizedBox(
            width: 165,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${percentage.toStringAsFixed(1)}%'),
                Text(
                  meetsThreshold
                      ? 'Eligible by attendance'
                      : 'Below minimum attendance',
                  style: TextStyle(
                    color: meetsThreshold
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          TextButton.icon(
            onPressed: submission.tpCertificatePdf.isEmpty
                ? null
                : () => _downloadCertificate(submission),
            icon: const Icon(Icons.download_outlined),
            label: const Text('Download PDF'),
          ),
        ),
        DataCell(
          SizedBox(
            width: 180,
            child: Text(
              submission.collegeRemarks.trim().isEmpty
                  ? '—'
                  : submission.collegeRemarks,
            ),
          ),
        ),
        DataCell(Text(_statusLabel(submission.status))),
        DataCell(
          isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : PopupMenuButton<String>(
                  enabled: canReview,
                  tooltip: canReview
                      ? 'Review submission'
                      : 'This submission has already been reviewed',
                  onSelected: (status) =>
                      _reviewSubmission(submission, status, reviewerUid),
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: ExamEligibilityStatus.eligible,
                      enabled: meetsThreshold,
                      child: const Text('Mark Eligible'),
                    ),
                    PopupMenuItem<String>(
                      value: ExamEligibilityStatus.notEligible,
                      enabled: !meetsThreshold,
                      child: const Text('Mark Not Eligible'),
                    ),
                    const PopupMenuItem<String>(
                      value: ExamEligibilityStatus.needsCorrection,
                      child: Text('Needs Correction'),
                    ),
                  ],
                  child: const Chip(label: Text('Review')),
                ),
        ),
      ],
    );
  }

  Future<void> _downloadCertificate(
    ExamEligibilitySubmission submission,
  ) async {
    try {
      await downloadBytes(
        bytes: submission.tpCertificatePdf,
        fileName: submission.tpCertificateFileName,
        mimeType: submission.tpCertificateMimeType,
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage('Unable to download TP certificate: $error');
    }
  }

  Future<void> _reviewSubmission(
    ExamEligibilitySubmission submission,
    String status,
    String reviewerUid,
  ) async {
    final remarksController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final remarksRequired = status != ExamEligibilityStatus.eligible;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_reviewActionLabel(status)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: remarksController,
            autofocus: remarksRequired,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: remarksRequired
                  ? 'DIET Remarks *'
                  : 'DIET Remarks (optional)',
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (remarksRequired && (value ?? '').trim().isEmpty) {
                return 'DIET remarks are required';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    final remarks = remarksController.text.trim();
    remarksController.dispose();
    if (confirmed != true || !mounted) return;

    setState(() => _processingSubmissionIds.add(submission.submissionId));
    try {
      await _firestoreService.reviewExamEligibilitySubmission(
        submissionId: submission.submissionId,
        status: status,
        reviewedBy: reviewerUid,
        dietRemarks: remarks,
      );
      if (mounted) {
        _showMessage('Eligibility review saved.');
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Unable to save eligibility review: $error');
      }
    } finally {
      if (mounted) {
        setState(
          () => _processingSubmissionIds.remove(submission.submissionId),
        );
      }
    }
  }

  String _reviewActionLabel(String status) {
    return switch (status) {
      ExamEligibilityStatus.eligible => 'Mark Eligible',
      ExamEligibilityStatus.notEligible => 'Mark Not Eligible',
      _ => 'Needs Correction',
    };
  }

  String _statusLabel(String status) {
    return switch (status) {
      ExamEligibilityStatus.submittedToDiet => 'Submitted to DIET',
      ExamEligibilityStatus.needsCorrection => 'Needs correction',
      ExamEligibilityStatus.eligible => 'Eligible',
      ExamEligibilityStatus.notEligible => 'Not eligible',
      ExamEligibilityStatus.draft => 'Draft',
      _ => status,
    };
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
