import 'package:flutter/material.dart';

import '../../../../../../core/firebase/firestore_service.dart';
import '../../../../../../features/admin/data/models/school_model.dart';
import '../widgets/add_school_form.dart';
import '../widgets/schools_data_table.dart';

class SchoolManagementPage extends StatefulWidget {
  const SchoolManagementPage({super.key});

  @override
  State<SchoolManagementPage> createState() => _SchoolManagementPageState();
}

class _SchoolManagementPageState extends State<SchoolManagementPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _districtFilterController =
      TextEditingController();
  String? _districtFilter;

  @override
  void dispose() {
    _districtFilterController.dispose();
    super.dispose();
  }

  void _applyDistrictFilter() {
    setState(() {
      _districtFilter = _districtFilterController.text.trim();
    });
  }

  void _clearDistrictFilter() {
    _districtFilterController.clear();
    setState(() => _districtFilter = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('School Management')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AddSchoolForm(firestoreService: _firestoreService),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _districtFilterController,
                    decoration: const InputDecoration(
                      labelText: 'Filter by district',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _applyDistrictFilter(),
                  ),
                ),
                ElevatedButton(
                  onPressed: _applyDistrictFilter,
                  child: const Text('Apply'),
                ),
                TextButton(
                  onPressed: _clearDistrictFilter,
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<SchoolModel>>(
                stream: _firestoreService.streamSchools(
                  districtId: _districtFilter,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Unable to load schools: ${snapshot.error}'),
                    );
                  }

                  return SchoolsDataTable(schools: snapshot.data ?? []);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
