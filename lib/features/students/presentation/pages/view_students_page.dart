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
    if (widget.isCollegeRole) {
      return _CollegeStudentsTable(
        students: widget.students,
        user: widget.user,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

    return [
      DataCell(Text(serialNumber.toString())),
      ..._fixedColumns.map(
        (column) => DataCell(
          Text(_formatValue(_columnValue(studentData, column.keys))),
        ),
      ),
    ];
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

class _CollegeStudentsTable extends StatelessWidget {
  const _CollegeStudentsTable({
    required this.students,
    required this.user,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> students;
  final UserModel? user;
  static const String _collegeInstruction =
      'ਆਪ ਦੀ ਸੰਸਥਾ ਵਿੱਚ ਦਾਖਲ ਹੇਠ ਲਿਖੇ ਸਿੱਖਿਆਰਥੀਆਂ ਦਾ ਰਜਿਸਟ੍ਰੇਸ਼ਨ ਨੰਬਰ ਕਲਿੱਕ ਕਰਦੇ ਹੋਏ ਅਗਲੇ ਪੇਜ ਦੇ ਅਖੀਰ ਵਿੱਚ ਐਲੀ੍ਮੈਂਟਰੀ ਸਕੂਲ ਦਾ ਨਾਮ ਸਲੈਕਟ ਕਰਦੇ ਹੋਏ ਸਬਮਿਟ ਕੀਤਾ ਜਾਵੇ।';

  static const List<_StudentColumn> _collegeColumns = [
    _StudentColumn('Sr. No.', []),
    _StudentColumn('Registration Number', ['registrationId', 'studentId']),
    _StudentColumn('Submitted On', ['submittedOn']),
    _StudentColumn('Allotted School', ['proposedSchoolName', 'finalSchoolName']),
    _StudentColumn('Name', ['name']),
    _StudentColumn('Father Name', ['fatherName']),
    _StudentColumn('Mother Name', ['motherName']),
    _StudentColumn('Category Name', ['categoryName']),
    _StudentColumn('Alloted Category', ['allotedCategory']),
    _StudentColumn('Joining Status', ['joiningStatus']),
  ];

  @override
  Widget build(BuildContext context) {
    final collegeId = (user?.collegeId ?? '').trim();
    final districtId = (user?.districtId ?? '').trim();
    final horizontalController = ScrollController();
    final verticalController = ScrollController();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: districtId.isEmpty
          ? null
          : FirebaseFirestore.instance
              .collection('schools')
              .where('districtId', isEqualTo: districtId)
              .snapshots(),
      builder: (context, schoolSnapshot) {
        final schoolNames = <String, String>{
          for (final doc in schoolSnapshot.data?.docs ?? [])
            _schoolId(doc): doc.data()['name'] as String? ?? doc.id,
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CollegeNameHeading(collegeId: collegeId),
            const SizedBox(height: 12),
            Text(
              _collegeInstruction,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Scrollbar(
                controller: horizontalController,
                thumbVisibility: true,
                notificationPredicate: (notification) {
                  return notification.metrics.axis == Axis.horizontal;
                },
                child: SingleChildScrollView(
                  controller: horizontalController,
                  scrollDirection: Axis.horizontal,
                  child: Scrollbar(
                    controller: verticalController,
                    thumbVisibility: true,
                    notificationPredicate: (notification) {
                      return notification.metrics.axis == Axis.vertical;
                    },
                    child: SingleChildScrollView(
                      controller: verticalController,
                      child: DataTable(
                        columns: _collegeColumns
                            .map(
                              (column) => DataColumn(
                                label: Text(
                                  column.label,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            )
                            .toList(),
                        rows: students
                            .asMap()
                            .entries
                            .map(
                              (entry) => DataRow(
                                cells: _collegeColumns.map((column) {
                                  if (column.label == 'Sr. No.') {
                                    return DataCell(Text('${entry.key + 1}'));
                                  }

                                  final studentData = entry.value.data();
                                  final value =
                                      _columnValue(studentData, column.keys);

                              if (column.label == 'Registration Number') {
                                final isSubmitted =
                                    studentData['submittedOn'] != null;

                                return DataCell(
                                  isSubmitted
                                      ? Text(
                                          _formatValue(value),
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        )
                                      : TextButton(
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    CollegeStudentDetailPage(
                                                  student: entry.value,
                                                  user: user,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Text(_formatValue(value)),
                                        ),
                                );
                              }

                              if (column.label == 'Allotted School') {
                                final schoolId =
                                    studentData['finalSchoolId'] as String? ?? '';
                                final schoolName =
                                    schoolNames[schoolId] ??
                                        _formatValue(value);
                                return DataCell(Text(schoolName));
                              }

                                  return DataCell(Text(_formatValue(value)));
                                }).toList(),
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
      },
    );
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

  String _formatValue(dynamic value) {
    if (value == null) return '';
    if (value is Timestamp) return value.toDate().toString();
    return value.toString();
  }

  String _schoolId(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return data['schoolId'] as String? ?? data['udise'] as String? ?? doc.id;
  }
}

class _CollegeNameHeading extends StatelessWidget {
  const _CollegeNameHeading({
    required this.collegeId,
  });

  final String collegeId;

  @override
  Widget build(BuildContext context) {
    if (collegeId.isEmpty) {
      return Text(
        'College',
        style: Theme.of(context).textTheme.headlineSmall,
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('colleges')
          .doc(collegeId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final collegeName =
            data?['name'] as String? ?? data?['shortName'] as String?;

        return Text(
          collegeName?.trim().isNotEmpty == true ? collegeName! : 'College',
          style: Theme.of(context).textTheme.headlineSmall,
        );
      },
    );
  }
}

class _StudentColumn {
  const _StudentColumn(this.label, this.keys);

  final String label;
  final List<String> keys;
}

class CollegeStudentDetailPage extends StatefulWidget {
  const CollegeStudentDetailPage({
    super.key,
    required this.student,
    required this.user,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> student;
  final UserModel? user;

  @override
  State<CollegeStudentDetailPage> createState() => _CollegeStudentDetailPageState();
}

class _CollegeStudentDetailPageState extends State<CollegeStudentDetailPage> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isSubmitting = false;
  String? _selectedSchoolId;
  static const List<_StudentDetailField> _detailFields = [
    _StudentDetailField('Name', 'name'),
    _StudentDetailField('Father Name', 'fatherName'),
    _StudentDetailField('Mother Name', 'motherName'),
    _StudentDetailField('Category Name', 'categoryName'),
    _StudentDetailField('Date of Birth', 'dob'),
    _StudentDetailField('Alloted Category', 'allotedCategory'),
    _StudentDetailField('Joining Status', 'joiningStatus'),
    _StudentDetailField('Percentage in 12th', 'percentage12th'),
    _StudentDetailField('Result', 'result'),
    _StudentDetailField('Station Choice', 'stationChoice'),
  ];

  @override
  Widget build(BuildContext context) {
    final studentData = widget.student.data();
    final districtId = (widget.user?.districtId ?? '').trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Details'),
        actions: const [HomeLogoutActions()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._detailFields.map(
              (field) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 220,
                      child: Text(
                        field.label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _formatDetailValue(
                          studentData[field.key],
                          key: field.key,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Allotted Station',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (districtId.isEmpty)
              const Text('District is not assigned to this college')
            else
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('schools')
                    .where('districtId', isEqualTo: districtId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Unable to load schools: ${snapshot.error}');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  }

                  final schools = snapshot.data?.docs ?? [];

                  if (schools.isEmpty) {
                    return const Text('No schools found for this district');
                  }

                  final selectedValue = schools.any(
                    (doc) => _schoolId(doc) == _selectedSchoolId,
                  )
                      ? _selectedSchoolId
                      : null;

                  return DropdownButtonFormField<String>(
                    value: selectedValue,
                    decoration: const InputDecoration(
                      labelText: 'School Name',
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
                    onChanged: (value) {
                      setState(() => _selectedSchoolId = value);
                    },
                  );
                },
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isSubmitting ? null : _submitProposal,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitProposal() async {
    final user = widget.user;
    final schoolId = _selectedSchoolId;

    if (user == null || schoolId == null || schoolId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select school before submitting')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      await _firestoreService.createProposal(
        ProposalModel(
          proposalId: '',
          studentId: _studentIdentifier(widget.student),
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

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proposal sent to DEO')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to send proposal: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _studentIdentifier(QueryDocumentSnapshot<Map<String, dynamic>> student) {
    final data = student.data();
    return data['studentId'] as String? ??
        data['registrationId'] as String? ??
        student.id;
  }

  String _schoolId(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return data['schoolId'] as String? ?? data['udise'] as String? ?? doc.id;
  }

  String _formatValue(dynamic value) {
    if (value == null) return '';
    if (value is Timestamp) {
      final date = value.toDate();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      final hour = (date.hour % 12 == 0 ? 12 : date.hour % 12)
          .toString()
          .padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      final suffix = date.hour >= 12 ? 'PM' : 'AM';
      return '$day/$month/$year $hour:$minute $suffix';
    }
    return value.toString();
  }

  String _formatDetailValue(dynamic value, {required String key}) {
    if (value == null) return '';

    if (key == 'dob' || key == 'dateOfBirth') {
      if (value is Timestamp) {
        return _formatDateOnly(value.toDate());
      }
      if (value is DateTime) {
        return _formatDateOnly(value);
      }
      final parsed = DateTime.tryParse(value.toString());
      if (parsed != null) {
        return _formatDateOnly(parsed);
      }
    }

    return _formatValue(value);
  }

  String _formatDateOnly(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}

class _StudentDetailField {
  const _StudentDetailField(this.label, this.key);

  final String label;
  final String key;
}
