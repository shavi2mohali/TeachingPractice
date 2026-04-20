import 'package:flutter/material.dart';

import '../../../../../../features/school/data/models/attendance_model.dart';

class AttendanceRecordsTable extends StatelessWidget {
  const AttendanceRecordsTable({
    super.key,
    required this.records,
  });

  final List<AttendanceModel> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Center(child: Text('No attendance records found'));
    }

    final sortedRecords = [...records]
      ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Day')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('School ID')),
            ],
            rows: sortedRecords
                .map(
                  (record) => DataRow(
                    cells: [
                      DataCell(Text(record.dayNumber.toString())),
                      DataCell(Text(_formatDate(record.date))),
                      DataCell(Text(record.status)),
                      DataCell(Text(record.schoolId)),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().padLeft(4, '0');
    return '$day-$month-$year';
  }
}
