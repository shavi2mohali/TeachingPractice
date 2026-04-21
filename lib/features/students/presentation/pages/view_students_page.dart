import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/firebase/firestore_service.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/home_logout_actions.dart';
import '../../../college/data/models/proposal_model.dart';

class ViewStudentsPage extends StatelessWidget {
  const ViewStudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final query = _studentsQuery(user);
    final isCollegeRole = user?.role.toLowerCase() == 'college';

    return Scaffold(
      appBar: AppBar(
        title: const Text('View Students'),
        actions: const [HomeLogoutActions()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: query == null
            ? const Center(child: Text('Student access details not found'))
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: query.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Unable to load students: ${snapshot.error}'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final students = snapshot.data?.docs ?? [];

                  if (students.isEmpty) {
                    return const Center(child: Text('No students found'));
                  }

                  return _StudentsTable(
                    students: students,
                    user: user,
                    isCollegeRole: isCollegeRole,
                  );
                },
              ),
      ),
    );
  }

  Query<Map<String, dynamic>>? _studentsQuery(UserModel? user) {
    final students = FirebaseFirestore.instance.collection('students');
    final role = user?.role.toLowerCase();

    switch (role) {
      case 'admin':
        return students;
      case 'deo':
      case 'diet':
        final districtId = user?.districtId ?? '';
        if (districtId.isEmpty) return null;
        return students.where('districtId', isEqualTo: districtId);
      case 'college':
        final collegeId = user?.collegeId ?? '';
        if (collegeId.isEmpty) return null;
        return students.where('collegeId', isEqualTo: collegeId);
      case 'school':
        final schoolId = user?.schoolId ?? '';
        if (schoolId.isEmpty) return null;
        return students.where('finalSchoolId', isEqualTo: schoolId);
      default:
        return null;
    }
  }
}

class _StudentsTable extends StatefulWidget {
  const _StudentsTable({
    required this.students,
    required this.user,
    required this.isCollegeRole,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> students;
  final UserModel? user;
  final bool isCollegeRole;

  @override
  State<_StudentsTable> createState() => _StudentsTableState();
}

class _StudentsTableState extends State<_StudentsTable> {
  final FirestoreService _firestoreService = FirestoreService();
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final TextEditingController _schoolSearchController = TextEditingController();
  final Set<String> _selectedStudentIds = <String>{};
  final Set<String> _processingStudentIds = <String>{};
  String? _selectedSchoolId;
  String _schoolSearchText = '';

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    _schoolSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final columns = _studentColumns();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isCollegeRole) ...[
          _CollegeSchoolSearch(
            districtId: widget.user?.districtId ?? '',
            controller: _schoolSearchController,
            searchText: _schoolSearchText,
            selectedSchoolId: _selectedSchoolId,
            onSearchChanged: (value) {
              setState(() => _schoolSearchText = value);
            },
            onSchoolChanged: (value) {
              setState(() => _selectedSchoolId = value);
            },
          ),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: Scrollbar(
            controller: _horizontalController,
            thumbVisibility: true,
            notificationPredicate: (notification) {
              return notification.metrics.axis == Axis.horizontal;
            },
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: Scrollbar(
                controller: _verticalController,
                thumbVisibility: true,
                notificationPredicate: (notification) {
                  return notification.metrics.axis == Axis.vertical;
                },
                child: SingleChildScrollView(
                  controller: _verticalController,
                  child: DataTable(
                    columns: [
                      const DataColumn(label: Text('Sr. No.')),
                      if (!widget.isCollegeRole)
                        const DataColumn(label: Text('Select')),
                      if (widget.isCollegeRole)
                        const DataColumn(label: Text('Action')),
                      ...columns.map(
                        (column) => DataColumn(
                          label: Text(
                            column,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                    rows: widget.students
                        .asMap()
                        .entries
                        .map(
                          (entry) => DataRow(
                            cells: _studentCells(
                              context: context,
                              serialNumber: entry.key + 1,
                              student: entry.value,
                              columns: columns,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<String> _studentColumns() {
    final columns = <String>{};

    for (final student in widget.students) {
      columns.addAll(student.data().keys);
    }

    return columns.toList()..sort();
  }

  List<DataCell> _studentCells({
    required BuildContext context,
    required int serialNumber,
    required QueryDocumentSnapshot<Map<String, dynamic>> student,
    required List<String> columns,
  }) {
    final studentId = student.id;

    return [
      DataCell(Text(serialNumber.toString())),
      if (!widget.isCollegeRole)
        DataCell(
          Checkbox(
            value: _selectedStudentIds.contains(studentId),
            onChanged: (value) {
              setState(() {
                if (value ?? false) {
                  _selectedStudentIds.add(studentId);
                } else {
                  _selectedStudentIds.remove(studentId);
                }
              });
            },
          ),
        ),
      if (widget.isCollegeRole)
        DataCell(
          FilledButton(
            onPressed: _processingStudentIds.contains(studentId)
                ? null
                : () => _confirmProposal(context, student),
            child: _processingStudentIds.contains(studentId)
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Confirm'),
          ),
        ),
      ...columns.map(
        (column) => DataCell(
          Text(_formatValue(student.data()[column])),
        ),
      ),
    ];
  }

  Future<void> _confirmProposal(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> student,
  ) async {
    final user = widget.user;
    final schoolId = _selectedSchoolId;

    if (user == null || schoolId == null || schoolId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select school before confirming')),
      );
      return;
    }

    final studentId = student.data()['studentId'] as String? ?? student.id;

    setState(() => _processingStudentIds.add(studentId));

    try {
      final now = DateTime.now();
      await _firestoreService.createProposal(
        ProposalModel(
          proposalId: '',
          studentId: studentId,
          collegeId: user.collegeId ?? '',
          proposedSchoolId: schoolId,
          districtId: user.districtId ?? '',
          status: 'pending',
          proposedBy: user.uid,
          proposedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proposal sent to DEO')),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to send proposal: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _processingStudentIds.remove(studentId));
      }
    }
  }

  String _formatValue(dynamic value) {
    if (value == null) return '';
    if (value is Timestamp) return value.toDate().toString();
    return value.toString();
  }
}

class _CollegeSchoolSearch extends StatelessWidget {
  const _CollegeSchoolSearch({
    required this.districtId,
    required this.controller,
    required this.searchText,
    required this.selectedSchoolId,
    required this.onSearchChanged,
    required this.onSchoolChanged,
  });

  final String districtId;
  final TextEditingController controller;
  final String searchText;
  final String? selectedSchoolId;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onSchoolChanged;

  @override
  Widget build(BuildContext context) {
    if (districtId.trim().isEmpty) {
      return const Text('District is not assigned to this college');
    }

    final schoolDistrictId = districtId.trim().toUpperCase();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .where('districtId', isEqualTo: schoolDistrictId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Unable to load schools: ${snapshot.error}');
        }

        final allSchools = snapshot.data?.docs ?? [];
        final normalizedSearch = searchText.trim().toLowerCase();
        final schools = normalizedSearch.isEmpty
            ? allSchools
            : allSchools.where((doc) {
                final name = doc.data()['name'] as String? ?? '';
                return name.toLowerCase().contains(normalizedSearch);
              }).toList();

        final selectedValue = schools.any((doc) => _schoolId(doc) == selectedSchoolId)
            ? selectedSchoolId
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Search schools by name',
                border: OutlineInputBorder(),
              ),
              onChanged: onSearchChanged,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedValue,
              decoration: const InputDecoration(
                labelText: 'Select school for proposal',
                border: OutlineInputBorder(),
              ),
              items: schools
                  .map(
                    (doc) => DropdownMenuItem<String>(
                      value: _schoolId(doc),
                      child: Text(doc.data()['name'] as String? ?? doc.id),
                    ),
                  )
                  .toList(),
              onChanged:
                  snapshot.connectionState == ConnectionState.waiting
                      ? null
                      : onSchoolChanged,
            ),
          ],
        );
      },
    );
  }

  String _schoolId(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return data['schoolId'] as String? ?? data['udise'] as String? ?? doc.id;
  }
}
