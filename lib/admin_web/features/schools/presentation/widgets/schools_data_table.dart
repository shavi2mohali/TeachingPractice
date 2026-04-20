import 'package:flutter/material.dart';

import '../../../../../../features/admin/data/models/school_model.dart';

class SchoolsDataTable extends StatelessWidget {
  const SchoolsDataTable({
    super.key,
    required this.schools,
  });

  final List<SchoolModel> schools;

  @override
  Widget build(BuildContext context) {
    if (schools.isEmpty) {
      return const Center(child: Text('No schools found'));
    }

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('School ID')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('District')),
              DataColumn(label: Text('Principal ID')),
              DataColumn(label: Text('Assigned')),
              DataColumn(label: Text('Active')),
            ],
            rows: schools
                .map(
                  (school) => DataRow(
                    cells: [
                      DataCell(Text(school.schoolId)),
                      DataCell(Text(school.name)),
                      DataCell(Text(school.districtName)),
                      DataCell(Text(school.principalUserId ?? '')),
                      DataCell(Text(school.currentAssignedCount.toString())),
                      DataCell(Text(school.isActive ? 'Yes' : 'No')),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
