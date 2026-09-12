import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/registration_constants.dart';
import '../../../../core/firebase/firestore_service.dart';
import '../../../auth/presentation/widgets/home_logout_actions.dart';
import '../../data/models/exam_eligibility_submission.dart';

class AdminEligibleRollNumberReportPage extends StatefulWidget {
  const AdminEligibleRollNumberReportPage({super.key});

  @override
  State<AdminEligibleRollNumberReportPage> createState() =>
      _AdminEligibleRollNumberReportPageState();
}

class _AdminEligibleRollNumberReportPageState
    extends State<AdminEligibleRollNumberReportPage> {
  final FirestoreService _firestoreService = FirestoreService();

  String _selectedDistrictId = '';
  String _selectedCollegeId = '';
  String _shownDistrictId = '';
  String _shownCollegeId = '';
  late Stream<QuerySnapshot<Map<String, dynamic>>> _collegesStream;
  Stream<List<ExamEligibilitySubmission>>? _reportStream;

  @override
  void initState() {
    super.initState();
    _collegesStream = FirebaseFirestore.instance
        .collection('colleges')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eligible for Roll Number - October 2026'),
        actions: const [HomeLogoutActions()],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _collegesStream,
        builder: (context, collegesSnapshot) {
          if (collegesSnapshot.hasError) {
            return Center(
              child: Text('Unable to load colleges: ${collegesSnapshot.error}'),
            );
          }
          if (!collegesSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final colleges = [...collegesSnapshot.data!.docs]
            ..sort((first, second) {
              return _collegeName(first).compareTo(_collegeName(second));
            });
          final collegeNames = {
            for (final college in colleges) college.id: _collegeName(college),
          };
          final selectedCollegeId = collegeNames.containsKey(_selectedCollegeId)
              ? _selectedCollegeId
              : '';

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 230,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedDistrictId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'District',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('All Districts'),
                          ),
                          for (final district
                              in RegistrationConstants.districts)
                            DropdownMenuItem(
                              value: district,
                              child: Text(district),
                            ),
                        ],
                        onChanged: _districtChanged,
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(
                          'college-$_selectedDistrictId-$selectedCollegeId',
                        ),
                        initialValue: selectedCollegeId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'College',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('All Colleges'),
                          ),
                          for (final college in colleges)
                            DropdownMenuItem(
                              value: college.id,
                              child: Text(
                                _collegeName(college),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) => setState(() {
                          _selectedCollegeId = value ?? '';
                          _reportStream = null;
                        }),
                      ),
                    ),
                    FilledButton(
                      onPressed: _showReport,
                      child: const Text('Show'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _reportStream == null
                    ? const Center(
                        child: Text('Choose report filters and click Show'),
                      )
                    : _buildReport(collegeNames),
              ),
            ],
          );
        },
      ),
    );
  }

  void _districtChanged(String? districtId) {
    final selectedDistrictId = districtId ?? '';
    setState(() {
      _selectedDistrictId = selectedDistrictId;
      _selectedCollegeId = '';
      _reportStream = null;
      _collegesStream = selectedDistrictId.isEmpty
          ? FirebaseFirestore.instance.collection('colleges').snapshots()
          : FirebaseFirestore.instance
                .collection('colleges')
                .where('districtId', isEqualTo: selectedDistrictId)
                .snapshots();
    });
  }

  void _showReport() {
    setState(() {
      _shownDistrictId = _selectedDistrictId;
      _shownCollegeId = _selectedCollegeId;
      _reportStream = _firestoreService.streamEligibleExamReport(
        districtId: _selectedDistrictId,
        collegeId: _selectedCollegeId,
      );
    });
  }

  Widget _buildReport(Map<String, String> collegeNames) {
    return StreamBuilder<List<ExamEligibilitySubmission>>(
      key: ValueKey('$_shownDistrictId-$_shownCollegeId'),
      stream: _reportStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Unable to load final report: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final submissions = snapshot.data!;
        if (submissions.isEmpty) {
          return const Center(
            child: Text('No eligible students found for these filters'),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Eligible for Roll Number - October 2026',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_scopeLabel(collegeNames)} • '
                        '${submissions.length} eligible student(s)',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SelectionArea(
                    child: Scrollbar(
                      child: SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStatePropertyAll(
                              Theme.of(context).colorScheme.primaryContainer,
                            ),
                            border: TableBorder.all(
                              color: Theme.of(context).dividerColor,
                            ),
                            columns: const [
                              DataColumn(label: Text('Registration ID')),
                              DataColumn(label: Text('Student Name')),
                              DataColumn(label: Text('College')),
                              DataColumn(label: Text('District')),
                              DataColumn(label: Text('Attendance %')),
                              DataColumn(label: Text('Attended Working Days')),
                              DataColumn(label: Text('DIET Reviewed On')),
                            ],
                            rows: [
                              for (final submission in submissions)
                                DataRow(
                                  cells: [
                                    DataCell(Text(submission.registrationId)),
                                    DataCell(Text(submission.studentName)),
                                    DataCell(
                                      Text(
                                        collegeNames[submission.collegeId] ??
                                            submission.collegeId,
                                      ),
                                    ),
                                    DataCell(Text(submission.districtId)),
                                    DataCell(
                                      Text(
                                        '${submission.attendancePercentage.toStringAsFixed(1)}%',
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        submission.attendedWorkingDays
                                            .toString(),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        _formatDateTime(submission.reviewedAt),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _scopeLabel(Map<String, String> collegeNames) {
    final district = _shownDistrictId.isEmpty
        ? 'All districts'
        : _shownDistrictId;
    final college = _shownCollegeId.isEmpty
        ? 'All colleges'
        : collegeNames[_shownCollegeId] ?? _shownCollegeId;
    return '$district • $college';
  }

  String _collegeName(QueryDocumentSnapshot<Map<String, dynamic>> college) {
    return college.data()['name'] as String? ??
        college.data()['shortName'] as String? ??
        college.id;
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
