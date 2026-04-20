import 'dart:typed_data';

import 'package:excel/excel.dart';

Future<List<Map<String, dynamic>>> parseStudentExcel(Uint8List fileBytes) async {
  final excel = Excel.decodeBytes(fileBytes);

  if (excel.tables.isEmpty) {
    return [];
  }

  final firstSheetName = excel.tables.keys.first;
  final sheet = excel.tables[firstSheetName];

  if (sheet == null || sheet.rows.isEmpty) {
    return [];
  }

  const requiredHeaders = [
    'Registration Id',
    'Name',
    'DOB',
    'Father Name',
    'Mother Name',
    'Category Name',
    'Alloted category',
    'Marks Obtained in 12th',
    'Total Marks 12th',
    '%age in 12th',
    'DISTRICT NAME',
    'Result',
    'Joining status',
    'Station choice',
  ];

  final headerRow = sheet.rows.first;
  final headerIndexMap = <String, int>{};

  for (var index = 0; index < headerRow.length; index++) {
    final headerValue = _cellValue(headerRow[index])?.toString() ?? '';
    if (headerValue.trim().isEmpty) continue;

    headerIndexMap[_normalizeHeader(headerValue)] = index;
  }

  for (final header in requiredHeaders) {
    if (!headerIndexMap.containsKey(_normalizeHeader(header))) {
      throw FormatException('Missing required column: $header');
    }
  }

  final students = <Map<String, dynamic>>[];

  for (var rowIndex = 1; rowIndex < sheet.rows.length; rowIndex++) {
    final row = sheet.rows[rowIndex];
    final student = <String, dynamic>{};

    for (final header in requiredHeaders) {
      final columnIndex = headerIndexMap[_normalizeHeader(header)]!;
      final value =
          columnIndex < row.length ? _cellValue(row[columnIndex]) : null;

      student[header] = value;
    }

    final hasAnyValue = student.values.any((value) {
      return value != null && value.toString().trim().isNotEmpty;
    });

    if (hasAnyValue) {
      students.add(student);
    }
  }

  return students;
}

String _normalizeHeader(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}

dynamic _cellValue(Data? cell) {
  final value = cell?.value;

  if (value == null) return null;
  if (value is TextCellValue) return value.value.text?.trim() ?? '';
  if (value is IntCellValue) return value.value;
  if (value is DoubleCellValue) return value.value;
  if (value is BoolCellValue) return value.value;
  if (value is DateCellValue) {
    return DateTime(value.year, value.month, value.day);
  }
  if (value is TimeCellValue) {
    return value.toString();
  }
  if (value is DateTimeCellValue) {
    return DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
    );
  }

  return value.toString().trim();
}
