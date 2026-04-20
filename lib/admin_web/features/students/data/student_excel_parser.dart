import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../../../core/constants/registration_constants.dart';

Future<List<Map<String, dynamic>>> parseStudentExcel(Uint8List fileBytes) async {
  final excel = Excel.decodeBytes(fileBytes);

  if (excel.tables.isEmpty) {
    return [];
  }

  const studentSheetName = '00 Ba O All filled DPEd 2025-27';
  final sheet = excel.tables[studentSheetName] ?? excel.tables.values.first;

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
    'Result',
    'DISTRICT NAME',
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
    final rawStudent = <String, dynamic>{};

    for (final header in requiredHeaders) {
      final columnIndex = headerIndexMap[_normalizeHeader(header)]!;
      final value = columnIndex < row.length ? _cellValue(row[columnIndex]) : null;

      rawStudent[header] = value;
    }

    final hasAnyValue = rawStudent.values.any((value) {
      return value != null && value.toString().trim().isNotEmpty;
    });

    if (hasAnyValue) {
      final registrationId = _stringValue(rawStudent['Registration Id']);
      final districtName = _cellValueAt(row, 11) ?? rawStudent['DISTRICT NAME'];
      final collegeId = _stringValue(_lastCellValue(row));

      students.add({
        'studentId': registrationId,
        'registrationId': registrationId,
        'name': _stringValue(rawStudent['Name']),
        'dob': rawStudent['DOB'],
        'fatherName': _stringValue(rawStudent['Father Name']),
        'motherName': _stringValue(rawStudent['Mother Name']),
        'categoryName': _stringValue(rawStudent['Category Name']),
        'allotedCategory': _stringValue(rawStudent['Alloted category']),
        'marks12th': rawStudent['Marks Obtained in 12th'],
        'totalMarks12th': rawStudent['Total Marks 12th'],
        'percentage12th': rawStudent['%age in 12th'],
        'districtId': _districtId(districtName),
        'result': _stringValue(rawStudent['Result']),
        'joiningStatus': _stringValue(rawStudent['Joining status']),
        'stationChoice': _stringValue(rawStudent['Station choice']),
        'collegeId': collegeId,
        'status': 'created',
      });
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

dynamic _cellValueAt(List<Data?> row, int index) {
  return index < row.length ? _cellValue(row[index]) : null;
}

dynamic _lastCellValue(List<Data?> row) {
  for (var index = row.length - 1; index >= 0; index--) {
    final value = _cellValue(row[index]);
    if (value != null && value.toString().trim().isNotEmpty) {
      return value;
    }
  }

  return null;
}

String _districtId(dynamic value) {
  final district = _stringValue(value);
  final normalizedDistrict = _normalizeHeader(district);

  for (final allowedDistrict in RegistrationConstants.districts) {
    if (_normalizeHeader(allowedDistrict) == normalizedDistrict) {
      return allowedDistrict;
    }
  }

  return district;
}

String _stringValue(dynamic value) {
  if (value == null) return '';
  return value.toString().trim();
}
