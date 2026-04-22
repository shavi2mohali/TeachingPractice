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
  final Set<String> _processingStudentIds = <String>{};
  final Set<String> _confirmedStudentIds = <String>{};
  String? _selectedSchoolId;

  static const List<_StudentColumn> _fixedColumns = [
    _StudentColumn('Registration Id', ['registrationId', 'studentId']),
    _StudentColumn('Name', ['name']),
    _StudentColumn('DOB', ['dob', 'dateOfBirth']),
    _StudentColumn('Father Name', ['fatherName']),
    _StudentColumn('Mother Name', ['motherName']),
    _StudentColumn('Category Name', ['categoryName']),
    _StudentColumn('Alloted category', ['allotedCategory']),
    _StudentColumn('Marks Obtained in 12th', ['marks12th']),
    _StudentColumn('Total Marks 12th', ['totalMarks12th']),
    _StudentColumn('%age in 12th', ['percentage12th']),
    _StudentColumn('DISTRICT NAME', ['districtId']),
    _StudentColumn('College District name', ['collegeDistrictName']),
    _StudentColumn('Result', ['result']),
    _StudentColumn('Joining status', ['joiningStatus']),
    _StudentColumn('Station choice', ['stationChoice']),
    _StudentColumn('CollegeId', ['collegeId']),
  ];

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isCollegeRole) ...[
          _CollegeSchoolPicker(
            districtId: widget.user?.districtId ?? '',
            selectedSchoolId: _selectedSchoolId,
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
                      if (widget.isCollegeRole)
                        const DataColumn(label: Text('Action')),
                      ..._fixedColumns.map(
                        (column) => DataColumn(
                          label: Text(
                            column.label,
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

  List<DataCell> _studentCells({
    required BuildContext context,
    required int serialNumber,
    required QueryDocumentSnapshot<Map<String, dynamic>> student,
  }) {
    final studentData = student.data();
    final studentId = _studentIdentifier(student);
    final isProcessing = _processingStudentIds.contains(studentId);
    final isConfirmed = _confirmedStudentIds.contains(studentId);

    return [
      DataCell(Text(serialNumber.toString())),
      if (widget.isCollegeRole)
        DataCell(
          FilledButton(
            onPressed: isProcessing || isConfirmed
                ? null
                : () => _confirmProposal(context, student),
            style: FilledButton.styleFrom(
              backgroundColor: isConfirmed ? Colors.grey : null,
            ),
            child: isProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isConfirmed ? 'Confirmed' : 'Confirm'),
          ),
        ),
      ..._fixedColumns.map(
        (column) => DataCell(
          Text(_formatValue(_columnValue(studentData, column.keys))),
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

      setState(() => _confirmedStudentIds.add(studentId));

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

  dynamic _columnValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null) {
        return value;
      }
    }

    return null;
  }

  String _studentIdentifier(QueryDocumentSnapshot<Map<String, dynamic>> student) {
    final data = student.data();
    return data['studentId'] as String? ??
        data['registrationId'] as String? ??
        student.id;
  }

  String _formatValue(dynamic value) {
    if (value == null) return '';
    if (value is Timestamp) return value.toDate().toString();
    return value.toString();
  }
}

class _CollegeSchoolPicker extends StatelessWidget {
  const _CollegeSchoolPicker({
    required this.districtId,
    required this.selectedSchoolId,
    required this.onSchoolChanged,
  });

  final String districtId;
  final String? selectedSchoolId;
  final ValueChanged<String?> onSchoolChanged;

  @override
  Widget build(BuildContext context) {
    if (districtId.trim().isEmpty) {
      return const Text('District is not assigned to this college');
    }

    final selectedDistrict = districtId.trim();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .where('districtId', isEqualTo: selectedDistrict)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Unable to load schools: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }

        final schools = (snapshot.data?.docs ?? [])
            .toList()
          ..sort((a, b) {
            final firstName = a.data()['name'] as String? ?? '';
            final secondName = b.data()['name'] as String? ?? '';
            return firstName.toLowerCase().compareTo(secondName.toLowerCase());
          });

        if (schools.isEmpty) {
          return const Text('No schools found for this district');
        }

        final selectedValue = schools.any((doc) => _schoolId(doc) == selectedSchoolId)
            ? selectedSchoolId
            : null;

        return DropdownButtonFormField<String>(
          key: ValueKey('college-school-$selectedDistrict'),
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
          onChanged: onSchoolChanged,
        );
      },
    );
  }

  String _schoolId(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return data['schoolId'] as String? ?? data['udise'] as String? ?? doc.id;
  }
}

class _StudentColumn {
  const _StudentColumn(this.label, this.keys);

  final String label;
  final List<String> keys;
}
