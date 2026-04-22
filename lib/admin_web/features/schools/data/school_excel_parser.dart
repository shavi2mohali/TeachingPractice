import 'dart:typed_data';

import 'package:excel/excel.dart';

Future<List<Map<String, dynamic>>> parseSchoolExcel(Uint8List fileBytes) async {
  final excel = Excel.decodeBytes(fileBytes);

  if (excel.tables.isEmpty) {
    return [];
  }

  final sheet = excel.tables.values.first;

  if (sheet.rows.isEmpty) {
    return [];
  }

  const requiredHeaders = [
    'UDISE',
    'DISTRICT_NAME',
    'School_Name',
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

  final schools = <Map<String, dynamic>>[];

  for (var rowIndex = 1; rowIndex < sheet.rows.length; rowIndex++) {
    final row = sheet.rows[rowIndex];
    final udise = _stringValue(_readCell(row, headerIndexMap, 'UDISE'));
    final districtId = _toTitleCase(
      _stringValue(_readCell(row, headerIndexMap, 'DISTRICT_NAME')),
    );
    final name = _toTitleCase(
      _stringValue(_readCell(row, headerIndexMap, 'School_Name')),
    );

    if (udise.isEmpty && districtId.isEmpty && name.isEmpty) {
      continue;
    }

    schools.add({
      'schoolId': udise,
      'udise': udise,
      'districtId': districtId,
      'name': name,
    });
  }

  return schools;
}

dynamic _readCell(
  List<Data?> row,
  Map<String, int> headerIndexMap,
  String header,
) {
  final columnIndex = headerIndexMap[_normalizeHeader(header)]!;
  return columnIndex < row.length ? _cellValue(row[columnIndex]) : null;
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

String _stringValue(dynamic value) {
  if (value == null) return '';
  return value.toString().trim();
}

String _toTitleCase(String value) {
  final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.isEmpty) return '';

  const lowerCaseWords = {
    'a',
    'an',
    'and',
    'as',
    'at',
    'by',
    'for',
    'from',
    'in',
    'of',
    'on',
    'or',
    'the',
    'to',
    'with',
  };

  final words = normalized.split(' ');

  return words.asMap().entries.map((entry) {
    final index = entry.key;
    final word = entry.value.toLowerCase();

    if (word.isEmpty) return '';

    final isFirst = index == 0;
    final isLast = index == words.length - 1;
    if (!isFirst && !isLast && lowerCaseWords.contains(word)) {
      return word;
    }

    return word
        .split('-')
        .map((segment) {
          if (segment.isEmpty) return '';
          return '${segment[0].toUpperCase()}${segment.substring(1)}';
        })
        .join('-');
  }).join(' ');
}
