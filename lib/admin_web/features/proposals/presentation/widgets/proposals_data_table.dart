import 'package:flutter/material.dart';

import '../../../../../../features/college/data/models/proposal_model.dart';

class ProposalsDataTable extends StatelessWidget {
  const ProposalsDataTable({
    super.key,
    required this.proposals,
  });

  final List<ProposalModel> proposals;

  @override
  Widget build(BuildContext context) {
    if (proposals.isEmpty) {
      return const Center(child: Text('No proposals found'));
    }

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Student ID')),
              DataColumn(label: Text('College ID')),
              DataColumn(label: Text('Proposed School ID')),
              DataColumn(label: Text('Status')),
            ],
            rows: proposals
                .map(
                  (proposal) => DataRow(
                    cells: [
                      DataCell(Text(proposal.studentId)),
                      DataCell(Text(proposal.collegeId)),
                      DataCell(Text(proposal.proposedSchoolId)),
                      DataCell(Text(proposal.status)),
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
