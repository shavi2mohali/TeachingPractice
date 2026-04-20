import 'package:flutter/material.dart';

import '../../../../../../core/firebase/firestore_service.dart';
import '../../../../../../features/admin/data/models/student_model.dart';
import '../../../../../../features/school/data/models/attendance_model.dart';
import '../widgets/attendance_records_table.dart';

const int _totalAttendanceDays = 28;

class AttendanceMonitoringPage extends StatefulWidget {
  const AttendanceMonitoringPage({super.key});

  @override
  State<AttendanceMonitoringPage> createState() =>
      _AttendanceMonitoringPageState();
}

class _AttendanceMonitoringPageState extends State<AttendanceMonitoringPage> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _selectedStudentId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Monitoring')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<List<StudentModel>>(
              stream: _firestoreService.streamStudents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    width: 280,
                    child: LinearProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Text('Unable to load students: ${snapshot.error}');
                }

                final students = snapshot.data ?? [];
                final selectedValue = students.any(
                  (student) => student.studentId == _selectedStudentId,
                )
                    ? _selectedStudentId
                    : null;

                return SizedBox(
                  width: 360,
                  child: DropdownButtonFormField<String>(
                    value: selectedValue,
                    decoration: const InputDecoration(
                      labelText: 'Select student',
                      border: OutlineInputBorder(),
                    ),
                    items: students
                        .map(
                          (student) => DropdownMenuItem<String>(
                            value: student.studentId,
                            child: Text(
                              student.name.isEmpty
                                  ? student.studentId
                                  : student.name,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (studentId) {
                      setState(() => _selectedStudentId = studentId);
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _selectedStudentId == null
                  ? const Center(child: Text('Select a student'))
                  : StreamBuilder<List<AttendanceModel>>(
                      stream: _firestoreService.streamAttendanceByStudent(
                        _selectedStudentId!,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Unable to load attendance: ${snapshot.error}',
                            ),
                          );
                        }

                        final records = snapshot.data ?? [];
                        final summary = _AttendanceSummary.fromRecords(records);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 16,
                              runSpacing: 12,
                              children: [
                                _SummaryCard(
                                  label: 'Present Days',
                                  value:
                                      '${summary.presentDays} / $_totalAttendanceDays',
                                ),
                                _SummaryCard(
                                  label: 'Percentage',
                                  value:
                                      '${summary.percentage.toStringAsFixed(2)}%',
                                  valueColor: summary.percentage < 90
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: AttendanceRecordsTable(records: records),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        width: 220,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: valueColor,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendanceSummary {
  final int presentDays;
  final double percentage;

  const _AttendanceSummary({
    required this.presentDays,
    required this.percentage,
  });

  factory _AttendanceSummary.fromRecords(List<AttendanceModel> records) {
    final presentDayNumbers = <int>{};

    for (final record in records) {
      if (record.dayNumber < 1 || record.dayNumber > _totalAttendanceDays) {
        continue;
      }

      if (record.status == 'present') {
        presentDayNumbers.add(record.dayNumber);
      }
    }

    final presentDays = presentDayNumbers.length;

    return _AttendanceSummary(
      presentDays: presentDays,
      percentage: (presentDays / _totalAttendanceDays) * 100,
    );
  }
}
