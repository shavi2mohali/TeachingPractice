import 'package:flutter/material.dart';

import '../../../../../../core/firebase/firestore_service.dart';
import '../../../../../../features/college/data/models/proposal_model.dart';
import '../widgets/proposals_data_table.dart';

class ProposalTrackingPage extends StatefulWidget {
  const ProposalTrackingPage({super.key});

  @override
  State<ProposalTrackingPage> createState() => _ProposalTrackingPageState();
}

class _ProposalTrackingPageState extends State<ProposalTrackingPage> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _selectedStatus;

  static const List<String> _statuses = [
    'pending',
    'approved',
    'rejected',
    'assigned_by_diet',
    'pending_deo',
    'approved_by_deo',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Proposal Tracking')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 280,
              child: DropdownButtonFormField<String?>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Filter by status',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All statuses'),
                  ),
                  ..._statuses.map(
                    (status) => DropdownMenuItem<String?>(
                      value: status,
                      child: Text(status),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedStatus = value);
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<ProposalModel>>(
                stream: _firestoreService.streamProposals(
                  status: _selectedStatus,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Unable to load proposals: ${snapshot.error}',
                      ),
                    );
                  }

                  return ProposalsDataTable(proposals: snapshot.data ?? []);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
