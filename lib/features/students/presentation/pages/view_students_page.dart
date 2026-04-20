import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/home_logout_actions.dart';

class ViewStudentsPage extends StatelessWidget {
  const ViewStudentsPage({super.key});

  static const List<String> _columns = [
    'registrationId',
    'name',
    'districtId',
    'collegeId',
    'finalSchoolId',
    'status',
    'fatherName',
    'motherName',
    'categoryName',
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final query = _studentsQuery(user);

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

                  return _StudentsTable(students: students);
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
  const _StudentsTable({required this.students});

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> students;

  @override
  State<_StudentsTable> createState() => _StudentsTableState();
}

class _StudentsTableState extends State<_StudentsTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              columns: ViewStudentsPage._columns
                  .map(
                    (column) => DataColumn(
                      label: Text(
                        column,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                  .toList(),
              rows: widget.students
                  .map(
                    (student) => DataRow(
                      cells: ViewStudentsPage._columns
                          .map(
                            (column) => DataCell(
                              Text(_formatValue(student.data()[column])),
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
    if (value is Timestamp) return value.toDate().toString();
    return value.toString();
  }
}
