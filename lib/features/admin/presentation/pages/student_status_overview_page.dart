import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../data/services/college_students_report_service.dart';
import '../../../auth/presentation/widgets/home_logout_actions.dart';

class StudentStatusOverviewPage extends StatefulWidget {
  const StudentStatusOverviewPage({super.key});

  @override
  State<StudentStatusOverviewPage> createState() =>
      _StudentStatusOverviewPageState();
}

class _StudentStatusOverviewPageState extends State<StudentStatusOverviewPage> {
  final CollegeStudentsReportService _reportService =
      CollegeStudentsReportService();
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Status Overview'),
        actions: const [HomeLogoutActions()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('students').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Unable to load student status overview: ${snapshot.error}',
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final students = snapshot.data?.docs ?? [];
            final statusGroups = _buildStatusGroups(students);
            final orderedGroups = statusGroups.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _ClickableStatCard(
                      title: 'Total Students',
                      value: students.length.toString(),
                      onTap: () => _openStatusDetails(
                        title: 'Total Students',
                        students: students,
                      ),
                    ),
                    ...orderedGroups.map(
                      (group) => _ClickableStatCard(
                        title: _titleCase(group.key),
                        value: group.value.length.toString(),
                        onTap: () => _openStatusDetails(
                          title: _titleCase(group.key),
                          students: group.value,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: _isDownloading ? null : _downloadReport,
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_outlined),
                    label: Text(
                      _isDownloading
                          ? 'Preparing Report...'
                          : 'Download College-wise Report',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Card(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: orderedGroups.length,
                      separatorBuilder: (_, __) => const Divider(height: 24),
                      itemBuilder: (context, index) {
                        final group = orderedGroups[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(_titleCase(group.key)),
                          trailing: Text(
                            '${group.value.length}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          onTap: () => _openStatusDetails(
                            title: _titleCase(group.key),
                            students: group.value,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> _buildStatusGroups(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> students,
  ) {
    final groups = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};

    for (final student in students) {
      final status = (student.data()['status'] as String? ?? 'unknown').trim();
      groups.putIfAbsent(status, () => []).add(student);
    }

    return groups;
  }

  void _openStatusDetails({
    required String title,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> students,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudentStatusDetailsPage(
          title: title,
          students: students,
        ),
      ),
    );
  }

  Future<void> _downloadReport() async {
    setState(() => _isDownloading = true);

    try {
      await _reportService.downloadCollegeWiseReport();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('College-wise report downloaded')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to download report: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  String _titleCase(String value) {
    final words = value.split(RegExp(r'[_\s]+'));
    return words
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

class StudentStatusDetailsPage extends StatelessWidget {
  const StudentStatusDetailsPage({
    super.key,
    required this.title,
    required this.students,
  });

  final String title;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> students;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: const [HomeLogoutActions()],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: students.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final student = students[index];
          final studentData = student.data();
          final studentId =
              studentData['studentId'] as String? ??
              studentData['registrationId'] as String? ??
              student.id;

          return FutureBuilder<_StudentTimelineBundle>(
            future: _StudentTimelineBundle.load(studentId: studentId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: LinearProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Unable to load timeline: ${snapshot.error}',
                    ),
                  ),
                );
              }

              final bundle = snapshot.data ?? const _StudentTimelineBundle();

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentData['name'] as String? ?? 'Student',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Registration: ${studentData['registrationId'] ?? studentId}',
                      ),
                      Text('Current Status: ${studentData['status'] ?? '-'}'),
                      const SizedBox(height: 16),
                      const Text(
                        'Timeline',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      ...bundle.timelineEntries.map(
                        (entry) => _TimelineTile(entry: entry),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ClickableStatCard extends StatelessWidget {
  const _ClickableStatCard({
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.entry,
  });

  final _TimelineEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = entry.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.more_time, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.description,
                  style: TextStyle(color: color),
                ),
                if (entry.dateTimeText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.dateTimeText!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentTimelineBundle {
  const _StudentTimelineBundle({
    this.proposal,
    this.allocation,
    this.student,
    this.collegeName,
    this.proposedSchoolName,
    this.finalSchoolName,
    this.deoName,
    this.dietName,
  });

  final Map<String, dynamic>? proposal;
  final Map<String, dynamic>? allocation;
  final Map<String, dynamic>? student;
  final String? collegeName;
  final String? proposedSchoolName;
  final String? finalSchoolName;
  final String? deoName;
  final String? dietName;

  static Future<_StudentTimelineBundle> load({
    required String studentId,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final studentSnapshot = await firestore.collection('students').doc(studentId).get();
    final proposalSnapshot = await firestore
        .collection('proposals')
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();
    final allocationSnapshot = await firestore
        .collection('allocations')
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();

    final studentData = studentSnapshot.data();
    final proposalData = proposalSnapshot.docs.isEmpty
        ? null
        : proposalSnapshot.docs.first.data();
    final allocationData = allocationSnapshot.docs.isEmpty
        ? null
        : allocationSnapshot.docs.first.data();

    final collegeId = (proposalData?['collegeId'] as String?) ??
        (studentData?['collegeId'] as String?) ??
        '';
    final proposedSchoolId = proposalData?['proposedSchoolId'] as String? ?? '';
    final finalSchoolId = (studentData?['finalSchoolId'] as String?) ??
        (allocationData?['schoolId'] as String?) ??
        '';
    final deoUserId = proposalData?['reviewedBy'] as String? ?? '';
    final dietUserId = proposalData?['finalAssignedBy'] as String? ?? '';

    final lookups = await Future.wait<DocumentSnapshot<Map<String, dynamic>>?>([
      collegeId.isEmpty
          ? Future.value(null)
          : firestore.collection('colleges').doc(collegeId).get(),
      proposedSchoolId.isEmpty
          ? Future.value(null)
          : firestore.collection('schools').doc(proposedSchoolId).get(),
      finalSchoolId.isEmpty
          ? Future.value(null)
          : firestore.collection('schools').doc(finalSchoolId).get(),
      deoUserId.isEmpty
          ? Future.value(null)
          : firestore.collection('users').doc(deoUserId).get(),
      dietUserId.isEmpty
          ? Future.value(null)
          : firestore.collection('users').doc(dietUserId).get(),
    ]);

    final collegeData = lookups[0]?.data();
    final proposedSchoolData = lookups[1]?.data();
    final finalSchoolData = lookups[2]?.data();
    final deoUserData = lookups[3]?.data();
    final dietUserData = lookups[4]?.data();

    return _StudentTimelineBundle(
      proposal: proposalData,
      allocation: allocationData,
      student: studentData,
      collegeName: collegeData?['name'] as String? ??
          collegeData?['shortName'] as String? ??
          collegeId,
      proposedSchoolName: proposedSchoolData?['name'] as String? ??
          proposedSchoolId,
      finalSchoolName: finalSchoolData?['name'] as String? ?? finalSchoolId,
      deoName: deoUserData?['name'] as String? ??
          deoUserData?['officerName'] as String? ??
          deoUserData?['email'] as String? ??
          deoUserId,
      dietName: dietUserData?['name'] as String? ??
          dietUserData?['officerName'] as String? ??
          dietUserData?['email'] as String? ??
          dietUserId,
    );
  }

  List<_TimelineEntry> get timelineEntries {
    final currentStudentName = student?['name'] as String? ?? 'Student';
    final districtName = proposal?['districtId'] as String? ??
        student?['districtId'] as String? ??
        '';
    final proposalStatus = (proposal?['status'] as String? ?? '').trim();
    final hasDeoAction = proposal?['reviewedAt'] != null;
    final deoApproved = hasDeoAction && proposalStatus != 'rejected';
    final hasDietAction = proposal?['finalAssignedAt'] != null || allocation != null;
    final dietRejected = (student?['dietStatus'] as String? ?? '').trim().toLowerCase() ==
        'rejected';

    return [
      _TimelineEntry(
        label: 'College Proposed',
        description: proposal == null
            ? 'No proposal submitted yet'
            : '${collegeName ?? 'College'} proposed ${proposedSchoolName ?? 'school'}',
        dateTimeText: _formatDateTime(proposal?['proposedAt']),
        color: proposal == null ? Colors.grey : Colors.green,
      ),
      _TimelineEntry(
        label: 'DEO Action',
        description: proposal == null
            ? 'Awaiting proposal'
            : !hasDeoAction
                ? 'Awaiting DEO review'
                : '${deoName ?? 'DEO'} of $districtName '
                    '${deoApproved ? 'Approved' : 'Rejected'} '
                    '${proposedSchoolName ?? 'school'}',
        dateTimeText: _formatDateTime(proposal?['reviewedAt']),
        color: proposal == null || !hasDeoAction
            ? Colors.grey
            : deoApproved
                ? Colors.green
                : Colors.red,
      ),
      _TimelineEntry(
        label: 'DIET Action',
        description: !hasDietAction && !dietRejected
            ? 'Awaiting DIET action'
            : '${dietName ?? 'DIET'} of $districtName '
                '${dietRejected ? 'Rejected' : 'Allotted'} '
                '${finalSchoolName ?? proposedSchoolName ?? 'school'}',
        dateTimeText: _formatDateTime(proposal?['finalAssignedAt']),
        color: !hasDietAction && !dietRejected
            ? Colors.grey
            : dietRejected
                ? Colors.red
                : Colors.green,
      ),
      _TimelineEntry(
        label: 'Allotted to School',
        description: allocation == null
            ? 'Not yet allotted to school'
            : 'Student $currentStudentName was finally allotted '
                '${finalSchoolName ?? proposedSchoolName ?? 'school'}',
        dateTimeText: _formatDateTime(allocation?['assignedAt']),
        color: allocation == null ? Colors.grey : Colors.green,
      ),
    ];
  }

  String? _formatDateTime(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      final hour = (date.hour % 12 == 0 ? 12 : date.hour % 12)
          .toString()
          .padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      final suffix = date.hour >= 12 ? 'PM' : 'AM';
      return '$day/$month/$year $hour:$minute $suffix';
    }

    return null;
  }
}

class _TimelineEntry {
  const _TimelineEntry({
    required this.label,
    required this.description,
    this.dateTimeText,
    required this.color,
  });

  final String label;
  final String description;
  final String? dateTimeText;
  final Color color;
}
