import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';

import 'file_download_service.dart';

class CollegeStudentsReportService {
  CollegeStudentsReportService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> downloadCollegeWiseReport() async {
    final studentsSnapshot = await _firestore.collection('students').get();
    final collegesSnapshot = await _firestore.collection('colleges').get();
    final schoolsSnapshot = await _firestore.collection('schools').get();

    final collegeNames = <String, String>{
      for (final doc in collegesSnapshot.docs)
        doc.id: doc.data()['name'] as String? ?? doc.id,
    };

    final schoolNames = <String, String>{
      for (final doc in schoolsSnapshot.docs)
        doc.id: doc.data()['name'] as String? ?? doc.id,
    };

    final groupedStudents =
        <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};

    for (final student in studentsSnapshot.docs) {
      final collegeId =
          student.data()['collegeId'] as String? ?? 'Unassigned College';
      groupedStudents.putIfAbsent(collegeId, () => []).add(student);
    }

    final sortedCollegeIds = groupedStudents.keys.toList()..sort();

    final excel = Excel.createExcel();
    final sheet = excel['College-wise Students'];
    excel.delete('Sheet1');

    final headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final titleStyle = CellStyle(
      bold: true,
      fontSize: 14,
      horizontalAlign: HorizontalAlign.Left,
    );

    final headers = <String>[
      'Registration Id',
      'Name',
      'Father Name',
      'Mother Name',
      'Category',
      'District',
      'College Name',
      'Current Status',
      'Allotted Station',
    ];

    var rowIndex = 0;

    for (final collegeId in sortedCollegeIds) {
      final collegeName = collegeNames[collegeId] ?? collegeId;
      final students = groupedStudents[collegeId]!
        ..sort((first, second) {
          final firstName = first.data()['name'] as String? ?? '';
          final secondName = second.data()['name'] as String? ?? '';
          return firstName.toLowerCase().compareTo(secondName.toLowerCase());
        });

      final titleCell = sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
      titleCell.value = TextCellValue('College: $collegeName');
      titleCell.cellStyle = titleStyle;
      rowIndex++;

      for (var columnIndex = 0; columnIndex < headers.length; columnIndex++) {
        final headerCell = sheet.cell(
          CellIndex.indexByColumnRow(
            columnIndex: columnIndex,
            rowIndex: rowIndex,
          ),
        );
        headerCell.value = TextCellValue(headers[columnIndex]);
        headerCell.cellStyle = headerStyle;
      }
      rowIndex++;

      for (final student in students) {
        final data = student.data();
        final stationId = data['finalSchoolId'] as String? ??
            data['proposedSchoolId'] as String? ??
            '';
        final stationName = schoolNames[stationId] ?? stationId;

        final rowValues = <dynamic>[
          data['registrationId'] ?? data['studentId'] ?? student.id,
          data['name'] ?? '',
          data['fatherName'] ?? '',
          data['motherName'] ?? '',
          data['categoryName'] ?? '',
          data['districtId'] ?? '',
          collegeName,
          data['status'] ?? '',
          stationName,
        ];

        for (var columnIndex = 0; columnIndex < rowValues.length; columnIndex++) {
          sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: columnIndex,
                  rowIndex: rowIndex,
                ),
              )
              .value = _cellValue(rowValues[columnIndex]);
        }
        rowIndex++;
      }

      rowIndex++;
    }

    for (var i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, switch (i) {
        0 => 18,
        1 => 28,
        2 => 24,
        3 => 24,
        4 => 18,
        5 => 18,
        6 => 32,
        7 => 18,
        _ => 28,
      });
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('Unable to generate college-wise Excel report.');
    }

    await downloadBytes(
      bytes: bytes,
      fileName: 'college_wise_students_report.xlsx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  CellValue _cellValue(dynamic value) {
    if (value is num) {
      return DoubleCellValue(value.toDouble());
    }

    return TextCellValue(value?.toString() ?? '');
  }
}
