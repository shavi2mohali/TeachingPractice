import 'package:excel/excel.dart';

import '../../../../core/firebase/firestore_service.dart';
import 'file_download_service.dart';

class RegistrationHistoryReportService {
  RegistrationHistoryReportService({
    FirestoreService? firestoreService,
  }) : _firestoreService = firestoreService ?? FirestoreService();

  final FirestoreService _firestoreService;

  Future<void> downloadHistoryReport() async {
    final history = await _firestoreService.getRegistrationHistory();
    final excel = Excel.createExcel();
    final sheet = excel['Registration History'];
    excel.delete('Sheet1');

    const headers = <String>[
      'Registration No.',
      'Entity Name',
      'Officer Name',
      'Mobile',
      'Email',
      'Role',
      'District',
      'Status',
      'Timestamp',
    ];

    final headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    for (var columnIndex = 0; columnIndex < headers.length; columnIndex++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(
          columnIndex: columnIndex,
          rowIndex: 0,
        ),
      );
      cell.value = TextCellValue(headers[columnIndex]);
      cell.cellStyle = headerStyle;
    }

    for (var rowIndex = 0; rowIndex < history.length; rowIndex++) {
      final registration = history[rowIndex];
      final values = <String>[
        registration.registrationNumber,
        registration.entityName,
        registration.officerName,
        registration.mobile,
        registration.email,
        registration.role,
        registration.districtId,
        registration.status,
        _formatDateTime(registration.actionedAt),
      ];

      for (var columnIndex = 0; columnIndex < values.length; columnIndex++) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: columnIndex,
                rowIndex: rowIndex + 1,
              ),
            )
            .value = TextCellValue(values[columnIndex]);
      }
    }

    final columnWidths = <int, double>{
      0: 20,
      1: 34,
      2: 28,
      3: 16,
      4: 30,
      5: 14,
      6: 18,
      7: 14,
      8: 22,
    };

    for (final entry in columnWidths.entries) {
      sheet.setColumnWidth(entry.key, entry.value);
    }

    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('Unable to generate registration history report.');
    }

    await downloadBytes(
      bytes: bytes,
      fileName: 'registration_history.xlsx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  String _formatDateTime(DateTime date) {
    if (date.millisecondsSinceEpoch == 0) return '-';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().padLeft(4, '0');
    final hour = (date.hour % 12 == 0 ? 12 : date.hour % 12)
        .toString()
        .padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    return '$day-$month-$year $hour:$minute $suffix';
  }
}
