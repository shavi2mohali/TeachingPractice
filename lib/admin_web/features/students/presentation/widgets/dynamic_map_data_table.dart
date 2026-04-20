import 'package:flutter/material.dart';

class DynamicMapDataTable extends StatelessWidget {
  const DynamicMapDataTable({
    super.key,
    required this.rows,
  });

  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(child: Text('No data found'));
    }

    final columns = rows.expand((row) => row.keys).toSet().toList();

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              columns: columns
                  .map(
                    (column) => DataColumn(
                      label: Text(
                        column,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                  .toList(),
              rows: rows
                  .map(
                    (row) => DataRow(
                      cells: columns
                          .map(
                            (column) => DataCell(
                              Text(_formatValue(row[column])),
                            ),
                          )
                          .toList(),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  String _formatValue(dynamic value) {
    if (value == null) return '';
    if (value is DateTime) {
      final day = value.day.toString().padLeft(2, '0');
      final month = value.month.toString().padLeft(2, '0');
      final year = value.year.toString().padLeft(4, '0');
      return '$day-$month-$year';
    }

    return value.toString();
  }
}
