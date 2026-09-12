import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/registration_constants.dart';
import '../../../../core/firebase/firestore_service.dart';
import '../../../admin/data/services/file_download_service.dart';
import '../../../auth/presentation/widgets/home_logout_actions.dart';
import '../../data/models/exam_eligibility_submission.dart';

class AdminExamRollNumberEligibilityPage extends StatefulWidget {
  const AdminExamRollNumberEligibilityPage({super.key});

  @override
  State<AdminExamRollNumberEligibilityPage> createState() =>
      _AdminExamRollNumberEligibilityPageState();
}

class _AdminExamRollNumberEligibilityPageState
    extends State<AdminExamRollNumberEligibilityPage> {
  static const _filterStatuses = [
    ExamEligibilityStatus.submittedToDiet,
    ExamEligibilityStatus.needsCorrection,
    ExamEligibilityStatus.eligible,
    ExamEligibilityStatus.notEligible,
  ];

  final FirestoreService _firestoreService = FirestoreService();

  String? _selectedDistrictId;
  String? _selectedCollegeId;
  String? _selectedCollegeName;
  String? _selectedStatus;
  String? _shownDistrictId;
  String? _shownCollegeId;
  String? _shownCollegeName;
  String? _shownStatus;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _collegesStream;
  Stream<List<ExamEligibilitySubmission>>? _summaryStream;
  Stream<List<ExamEligibilitySubmission>>? _recordsStream;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Roll Number Eligibility'),
        actions: const [HomeLogoutActions()],
      ),
      body: Column(
        children: [
          Padding(padding: const EdgeInsets.all(24), child: _buildFilters()),
          Expanded(
            child: _recordsStream == null || _summaryStream == null
                ? const Center(
                    child: Text(
                      'Select district, college and status to view eligibility records',
                    ),
                  )
                : _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String>(
            initialValue: _selectedDistrictId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'District',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final district in RegistrationConstants.districts)
                DropdownMenuItem(value: district, child: Text(district)),
            ],
            onChanged: _districtChanged,
          ),
        ),
        SizedBox(width: 280, child: _buildCollegeDropdown()),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String>(
            initialValue: _selectedStatus,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final status in _filterStatuses)
                DropdownMenuItem(
                  value: status,
                  child: Text(_statusLabel(status)),
                ),
            ],
            onChanged: (value) => setState(() {
              _selectedStatus = value;
              _clearShownResults();
            }),
          ),
        ),
        FilledButton(
          onPressed:
              _selectedDistrictId == null ||
                  _selectedCollegeId == null ||
                  _selectedStatus == null
              ? null
              : _showResults,
          child: const Text('Show'),
        ),
      ],
    );
  }

  Widget _buildCollegeDropdown() {
    if (_collegesStream == null) {
      return DropdownButtonFormField<String>(
        items: const [],
        onChanged: null,
        decoration: const InputDecoration(
          labelText: 'College',
          hintText: 'Select district first',
          border: OutlineInputBorder(),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _collegesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return InputDecorator(
            decoration: const InputDecoration(
              labelText: 'College',
              border: OutlineInputBorder(),
              errorText: 'Unable to load colleges',
            ),
            child: const Text(''),
          );
        }
        if (!snapshot.hasData) {
          return const LinearProgressIndicator();
        }

        final colleges = [...snapshot.data!.docs]
          ..sort((first, second) {
            return _collegeName(first).compareTo(_collegeName(second));
          });
        final selectedCollegeId =
            colleges.any((college) => college.id == _selectedCollegeId)
            ? _selectedCollegeId
            : null;

        return DropdownButtonFormField<String>(
          key: ValueKey('college-$_selectedDistrictId-$selectedCollegeId'),
          initialValue: selectedCollegeId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'College',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final college in colleges)
              DropdownMenuItem(
                value: college.id,
                child: Text(
                  _collegeName(college),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: colleges.isEmpty
              ? null
              : (value) => setState(() {
                  _selectedCollegeId = value;
                  _selectedCollegeName = value == null
                      ? null
                      : _collegeName(
                          colleges.firstWhere((college) => college.id == value),
                        );
                  _clearShownResults();
                }),
        );
      },
    );
  }

  void _districtChanged(String? districtId) {
    setState(() {
      _selectedDistrictId = districtId;
      _selectedCollegeId = null;
      _selectedCollegeName = null;
      _clearShownResults();
      _collegesStream = districtId == null
          ? null
          : FirebaseFirestore.instance
                .collection('colleges')
                .where('districtId', isEqualTo: districtId)
                .snapshots();
    });
  }

  void _clearShownResults() {
    _shownDistrictId = null;
    _shownCollegeId = null;
    _shownCollegeName = null;
    _shownStatus = null;
    _summaryStream = null;
    _recordsStream = null;
  }

  void _showResults() {
    final districtId = _selectedDistrictId!;
    final collegeId = _selectedCollegeId!;
    final status = _selectedStatus!;
    setState(() {
      _shownDistrictId = districtId;
      _shownCollegeId = collegeId;
      _shownCollegeName = _selectedCollegeName ?? collegeId;
      _shownStatus = status;
      _summaryStream = _firestoreService
          .streamExamEligibilitySubmissionsForAdmin(
            districtId: districtId,
            collegeId: collegeId,
          );
      _recordsStream = _firestoreService
          .streamExamEligibilitySubmissionsForAdmin(
            districtId: districtId,
            collegeId: collegeId,
            status: status,
          );
    });
  }

  Widget _buildResults() {
    return StreamBuilder<List<ExamEligibilitySubmission>>(
      key: ValueKey('summary-$_shownDistrictId-$_shownCollegeId'),
      stream: _summaryStream,
      builder: (context, summarySnapshot) {
        if (summarySnapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load eligibility summary: ${summarySnapshot.error}',
            ),
          );
        }
        if (!summarySnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final summary = _EligibilitySummary.fromSubmissions(
          summarySnapshot.data!,
        );
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _SummaryCard(
                    label: 'Total submitted',
                    value: summary.total,
                    color: Colors.blue,
                  ),
                  _SummaryCard(
                    label: 'Eligible',
                    value: summary.eligible,
                    color: Colors.green,
                  ),
                  _SummaryCard(
                    label: 'Not eligible',
                    value: summary.notEligible,
                    color: Colors.red,
                  ),
                  _SummaryCard(
                    label: 'Needs correction',
                    value: summary.needsCorrection,
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
            Expanded(child: _buildRecordsTable()),
          ],
        );
      },
    );
  }

  Widget _buildRecordsTable() {
    return StreamBuilder<List<ExamEligibilitySubmission>>(
      key: ValueKey('records-$_shownDistrictId-$_shownCollegeId-$_shownStatus'),
      stream: _recordsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load eligibility records: ${snapshot.error}',
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final submissions = snapshot.data!;
        if (submissions.isEmpty) {
          return const Center(
            child: Text('No eligibility records found for these filters'),
          );
        }

        return Scrollbar(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Sr. No.')),
                  DataColumn(label: Text('Registration ID')),
                  DataColumn(label: Text('Student Name')),
                  DataColumn(label: Text('College')),
                  DataColumn(label: Text('District')),
                  DataColumn(label: Text('Total Working Days')),
                  DataColumn(label: Text('Attended Working Days')),
                  DataColumn(label: Text('Attendance %')),
                  DataColumn(label: Text('TP Certificate')),
                  DataColumn(label: Text('DIET Decision')),
                  DataColumn(label: Text('DIET Remarks')),
                  DataColumn(label: Text('Reviewed On')),
                ],
                rows: [
                  for (var index = 0; index < submissions.length; index++)
                    _submissionRow(index + 1, submissions[index]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  DataRow _submissionRow(
    int serialNumber,
    ExamEligibilitySubmission submission,
  ) {
    final percentage = ExamEligibilitySubmission.calculateAttendancePercentage(
      submission.attendedWorkingDays,
    );
    return DataRow(
      cells: [
        DataCell(Text(serialNumber.toString())),
        DataCell(Text(submission.registrationId)),
        DataCell(Text(submission.studentName)),
        DataCell(Text(_shownCollegeName ?? submission.collegeId)),
        DataCell(Text(submission.districtId)),
        DataCell(Text(submission.totalWorkingDays.toString())),
        DataCell(Text(submission.attendedWorkingDays.toString())),
        DataCell(Text('${percentage.toStringAsFixed(1)}%')),
        DataCell(
          TextButton.icon(
            onPressed: submission.tpCertificatePdf.isEmpty
                ? null
                : () => _downloadCertificate(submission),
            icon: const Icon(Icons.download_outlined),
            label: const Text('Download PDF'),
          ),
        ),
        DataCell(_DecisionChip(status: submission.status)),
        DataCell(
          SizedBox(
            width: 180,
            child: Text(
              (submission.dietRemarks ?? '').trim().isEmpty
                  ? '—'
                  : submission.dietRemarks!,
            ),
          ),
        ),
        DataCell(Text(_formatDateTime(submission.reviewedAt))),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to download TP certificate: $error')),
      );
    }
  }

  String _collegeName(QueryDocumentSnapshot<Map<String, dynamic>> college) {
    return college.data()['name'] as String? ??
        college.data()['shortName'] as String? ??
        college.id;
  }

  String _statusLabel(String status) {
    return switch (status) {
      ExamEligibilityStatus.submittedToDiet => 'Submitted to DIET',
      ExamEligibilityStatus.needsCorrection => 'Needs correction',
      ExamEligibilityStatus.eligible => 'Eligible',
      ExamEligibilityStatus.notEligible => 'Not eligible',
      _ => status,
    };
  }

  String _formatDateTime(DateTime? date) {
    if (date == null || date.millisecondsSinceEpoch == 0) return '—';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
  }
}

class _DecisionChip extends StatelessWidget {
  const _DecisionChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ExamEligibilityStatus.eligible => ('Eligible', Colors.green),
      ExamEligibilityStatus.notEligible => ('Not eligible', Colors.red),
      ExamEligibilityStatus.needsCorrection => (
        'Needs correction',
        Colors.orange,
      ),
      ExamEligibilityStatus.submittedToDiet => (
        'Submitted to DIET',
        Colors.blue,
      ),
      _ => (status, Colors.grey),
    };
    return Chip(
      label: Text(label),
      side: BorderSide(color: color),
      backgroundColor: color.withValues(alpha: 0.12),
      labelStyle: TextStyle(color: color.shade700),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final MaterialColor color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        color: color.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                value.toString(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _EligibilitySummary {
  const _EligibilitySummary({
    required this.total,
    required this.eligible,
    required this.notEligible,
    required this.needsCorrection,
  });

  final int total;
  final int eligible;
  final int notEligible;
  final int needsCorrection;

  factory _EligibilitySummary.fromSubmissions(
    List<ExamEligibilitySubmission> submissions,
  ) {
    return _EligibilitySummary(
      total: submissions.length,
      eligible: submissions
          .where((item) => item.status == ExamEligibilityStatus.eligible)
          .length,
      notEligible: submissions
          .where((item) => item.status == ExamEligibilityStatus.notEligible)
          .length,
      needsCorrection: submissions
          .where((item) => item.status == ExamEligibilityStatus.needsCorrection)
          .length,
    );
  }
}
