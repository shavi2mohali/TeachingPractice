import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/home_logout_actions.dart';
import '../../../college/presentation/pages/propose_school_page.dart';

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
    required this.isCollegeRole,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> students;
  final bool isCollegeRole;

  @override
  State<_StudentsTable> createState() => _StudentsTableState();
}

class _StudentsTableState extends State<_StudentsTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final Set<String> _selectedStudentIds = <String>{};

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final columns = _studentColumns();

    return Scrollbar(
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
                const DataColumn(label: Text('Select')),
                if (widget.isCollegeRole) const DataColumn(label: Text('Action')),
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
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ProposeSchoolPage(
                    initialStudentId:
                        student.data()['studentId'] as String? ?? student.id,
                  ),
                ),
              );
            },
            child: const Text('Propose'),
          ),
        ),
      ...columns.map(
        (column) => DataCell(
          Text(_formatValue(student.data()[column])),
        ),
      ),
    ];
  }

  String _formatValue(dynamic value) {
    if (value == null) return '';
    if (value is Timestamp) return value.toDate().toString();
    return value.toString();
  }
}
