import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/firebase/firestore_service.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/home_logout_actions.dart';

class CollegeCorrectionsPage extends StatelessWidget {
  const CollegeCorrectionsPage({super.key});

  static const List<_CorrectionListColumn> _columns = [
    _CorrectionListColumn('Registration Number', [
      'registrationId',
      'studentId',
    ]),
    _CorrectionListColumn('Submitted On', ['correctionRequestedAt']),
    _CorrectionListColumn('Name', ['studentName', 'name']),
    _CorrectionListColumn('Father Name', ['fatherName']),
    _CorrectionListColumn('Mother Name', ['motherName']),
    _CorrectionListColumn('Category Name', ['categoryName']),
    _CorrectionListColumn('Alloted Category', ['allotedCategory']),
    _CorrectionListColumn('Joining Status', ['joiningStatus']),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final collegeId = (user?.collegeId ?? '').trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Corrections'),
        actions: const [HomeLogoutActions()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: collegeId.isEmpty
            ? const Center(child: Text('College details not found'))
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('correction_requests')
                    .where('collegeId', isEqualTo: collegeId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Unable to load correction requests: ${snapshot.error}',
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final requests = [...?snapshot.data?.docs];
                  // College equality only: no composite index, and include
                  // legacy requests that have no createdAt field.
                  requests.sort((a, b) {
                    final first = a.data()['createdAt'];
                    final second = b.data()['createdAt'];
                    return (second is Timestamp
                            ? second.millisecondsSinceEpoch
                            : 0)
                        .compareTo(
                          first is Timestamp ? first.millisecondsSinceEpoch : 0,
                        );
                  });

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirestoreService().streamCollegeCorrectionStudents(
                      collegeId,
                    ),
                    builder: (context, studentsSnapshot) {
                      if (studentsSnapshot.hasError) {
                        return Center(
                          child: Text(
                            'Unable to load students: ${studentsSnapshot.error}',
                          ),
                        );
                      }

                      if (studentsSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final studentsById =
                          <String, QueryDocumentSnapshot<Map<String, dynamic>>>{
                            for (final doc in studentsSnapshot.data?.docs ?? [])
                              doc.id: doc,
                          };

                      if (requests.isEmpty && studentsById.isEmpty) {
                        return const Center(
                          child: Text(
                            'No students or correction requests found for this college',
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CollegeHeading(collegeId: collegeId),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _CorrectionsTable(
                              requests: requests,
                              studentsById: studentsById,
                              user: user,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  static dynamic _columnValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null) {
        return value;
      }
    }

    return null;
  }

  static String _formatValue(dynamic value) {
    if (value == null) return '';
    if (value is Timestamp) return _formatDateTime(value.toDate());
    return value.toString();
  }

  static String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = (date.hour % 12 == 0 ? 12 : date.hour % 12).toString().padLeft(
      2,
      '0',
    );
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    return '$day/$month/$year $hour:$minute $suffix';
  }

  static Future<void> _showRejectionRemarks(
    BuildContext context,
    String remarks,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Rejection Remarks'),
          content: Text(
            remarks.trim().isEmpty ? 'No remarks provided.' : remarks,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _CorrectionsTable extends StatefulWidget {
  const _CorrectionsTable({
    required this.requests,
    required this.studentsById,
    required this.user,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> requests;
  final Map<String, QueryDocumentSnapshot<Map<String, dynamic>>> studentsById;
  final UserModel? user;

  @override
  State<_CorrectionsTable> createState() => _CorrectionsTableState();
}

class _CorrectionsTableState extends State<_CorrectionsTable> {
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
    // Keep every request (including rejected history), then add students who
    // have never submitted. Requests are already newest first.
    final latestByStudent = <String, Map<String, dynamic>>{};
    final rows = <Map<String, dynamic>>[];
    for (final request in widget.requests) {
      final data = request.data();
      latestByStudent.putIfAbsent(
        data['studentId'] as String? ?? '',
        () => data,
      );
      rows.add(data);
    }
    for (final student in widget.studentsById.values) {
      if (!latestByStudent.containsKey(student.id)) {
        rows.add({
          ...student.data(),
          'studentId': student.id,
          'status': student.data()['correctionRequestStatus'] ?? '',
        });
      }
    }
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
                ...CollegeCorrectionsPage._columns.map(
                  (column) => DataColumn(
                    label: Text(
                      column.label,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
              rows: rows.asMap().entries.map((entry) {
                final data = entry.value;
                final studentId = data['studentId'] as String? ?? '';
                final student = widget.studentsById[studentId];
                final studentData = student?.data() ?? <String, dynamic>{};
                final combinedData = <String, dynamic>{...studentData, ...data};

                return DataRow(
                  cells: [
                    DataCell(Text('${entry.key + 1}')),
                    ...CollegeCorrectionsPage._columns.map((column) {
                      final value = CollegeCorrectionsPage._columnValue(
                        combinedData,
                        column.keys,
                      );

                      if (column.label == 'Registration Number') {
                        final correctionStatus =
                            (latestByStudent[studentId]?['status'] as String? ??
                                    studentData['correctionRequestStatus']
                                        as String? ??
                                    '')
                                .trim()
                                .toLowerCase();
                        final isClickable =
                            (correctionStatus.isEmpty ||
                                correctionStatus == 'rejected') &&
                            student != null;

                        return DataCell(
                          isClickable
                              ? TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            CollegeCorrectionDetailPage(
                                              student: student,
                                              user: widget.user,
                                            ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    CollegeCorrectionsPage._formatValue(value),
                                  ),
                                )
                              : Text(
                                  CollegeCorrectionsPage._formatValue(value),
                                  style: const TextStyle(color: Colors.grey),
                                ),
                        );
                      }

                      if (column.label == 'Submitted On') {
                        final correctionStatus =
                            (data['status'] as String? ?? '')
                                .trim()
                                .toLowerCase();

                        if (correctionStatus == 'approved') {
                          return const DataCell(
                            Text(
                              'Approved',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }

                        if (correctionStatus == 'rejected') {
                          return DataCell(
                            InkWell(
                              onTap: () =>
                                  CollegeCorrectionsPage._showRejectionRemarks(
                                    context,
                                    data['rejectionRemarks'] as String? ?? '',
                                  ),
                              child: const Text(
                                'Rejected',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }

                        return DataCell(
                          Text(
                            correctionStatus.isEmpty
                                ? 'Not submitted'
                                : 'Pending — ${CollegeCorrectionsPage._formatValue(data['createdAt'] ?? data['correctionRequestedAt'])}',
                          ),
                        );
                      }

                      return DataCell(
                        Text(CollegeCorrectionsPage._formatValue(value)),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class CollegeCorrectionDetailPage extends StatefulWidget {
  const CollegeCorrectionDetailPage({
    super.key,
    required this.student,
    required this.user,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> student;
  final UserModel? user;

  @override
  State<CollegeCorrectionDetailPage> createState() =>
      _CollegeCorrectionDetailPageState();
}

class _CollegeCorrectionDetailPageState
    extends State<CollegeCorrectionDetailPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCorrectionEnglishController =
      TextEditingController();
  final TextEditingController _namePunjabiController = TextEditingController();
  final TextEditingController _fatherNameCorrectionEnglishController =
      TextEditingController();
  final TextEditingController _fatherNamePunjabiController =
      TextEditingController();
  final TextEditingController _motherNameCorrectionEnglishController =
      TextEditingController();
  final TextEditingController _motherNamePunjabiController =
      TextEditingController();

  Uint8List? _certificateBytes;
  String? _certificateFileName;
  bool _isSubmitting = false;

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
  void dispose() {
    _nameCorrectionEnglishController.dispose();
    _namePunjabiController.dispose();
    _fatherNameCorrectionEnglishController.dispose();
    _fatherNamePunjabiController.dispose();
    _motherNameCorrectionEnglishController.dispose();
    _motherNamePunjabiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentData = widget.student.data();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Correction Details'),
        actions: const [HomeLogoutActions()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._detailFields.asMap().entries.map((entry) {
                final field = entry.value;

                if (entry.key <= 2) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CorrectionInputRow(
                      label: field.label,
                      originalValue: _formatDetailValue(
                        studentData[field.key],
                        key: field.key,
                      ),
                      englishController: switch (entry.key) {
                        0 => _nameCorrectionEnglishController,
                        1 => _fatherNameCorrectionEnglishController,
                        _ => _motherNameCorrectionEnglishController,
                      },
                      punjabiController: switch (entry.key) {
                        0 => _namePunjabiController,
                        1 => _fatherNamePunjabiController,
                        _ => _motherNamePunjabiController,
                      },
                      englishLabel: 'Correction in English',
                      punjabiLabel: 'Name in Punjabi',
                      validator: _requiredCorrection,
                    ),
                  );
                }

                return Padding(
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
                );
              }),
              const SizedBox(height: 24),
              const Text(
                'Upload 10th Certificate',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickCertificatePdf,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Upload PDF File'),
              ),
              if (_certificateFileName != null) ...[
                const SizedBox(height: 8),
                Text(_certificateFileName!),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isSubmitting ? null : _submitCorrectionRequest,
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
      ),
    );
  }

  Future<void> _pickCertificatePdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );

    final file = result?.files.single;

    if (file == null || file.bytes == null) {
      return;
    }

    setState(() {
      _certificateBytes = file.bytes;
      _certificateFileName = file.name;
    });
  }

  Future<void> _submitCorrectionRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_certificateBytes == null || _certificateFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload the 10th certificate PDF first.'),
        ),
      );
      return;
    }

    final user = widget.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to identify current user.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final studentData = widget.student.data();
      await _firestoreService.createCorrectionRequest(
        // Rules and the transaction reference the actual Firestore document.
        studentId: widget.student.id,
        registrationId: _registrationId(widget.student),
        collegeId: (user.collegeId ?? '').trim(),
        districtId: user.districtId ?? '',
        requestedBy: user.uid,
        studentName: studentData['name'] as String? ?? '',
        fatherName: studentData['fatherName'] as String? ?? '',
        motherName: studentData['motherName'] as String? ?? '',
        nameCorrectionEnglish: _nameCorrectionEnglishController.text.trim(),
        namePunjabi: _namePunjabiController.text.trim(),
        fatherNameCorrectionEnglish: _fatherNameCorrectionEnglishController.text
            .trim(),
        fatherNamePunjabi: _fatherNamePunjabiController.text.trim(),
        motherNameCorrectionEnglish: _motherNameCorrectionEnglishController.text
            .trim(),
        motherNamePunjabi: _motherNamePunjabiController.text.trim(),
        certificateBytes: _certificateBytes!,
        certificateFileName: _certificateFileName!,
        certificateMimeType: 'application/pdf',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Correction request sent to admin successfully.'),
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to submit correction request: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String? _requiredCorrection(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }

    return null;
  }

  String _registrationId(QueryDocumentSnapshot<Map<String, dynamic>> student) {
    final data = student.data();
    return data['registrationId'] as String? ??
        data['studentId'] as String? ??
        student.id;
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

    if (value is Timestamp) {
      return _formatDateOnly(value.toDate());
    }

    return value.toString();
  }

  String _formatDateOnly(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}

class _CollegeHeading extends StatelessWidget {
  const _CollegeHeading({required this.collegeId});

  final String collegeId;

  @override
  Widget build(BuildContext context) {
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

class _CorrectionListColumn {
  const _CorrectionListColumn(this.label, this.keys);

  final String label;
  final List<String> keys;
}

class _StudentDetailField {
  const _StudentDetailField(this.label, this.key);

  final String label;
  final String key;
}

class _CorrectionInputRow extends StatelessWidget {
  const _CorrectionInputRow({
    required this.label,
    required this.originalValue,
    required this.englishController,
    required this.punjabiController,
    required this.englishLabel,
    required this.punjabiLabel,
    required this.validator,
  });

  final String label;
  final String originalValue;
  final TextEditingController englishController;
  final TextEditingController punjabiController;
  final String englishLabel;
  final String punjabiLabel;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 900;

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Original Value: $originalValue'),
              const SizedBox(height: 8),
              TextFormField(
                controller: englishController,
                decoration: InputDecoration(
                  labelText: englishLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: validator,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: punjabiController,
                decoration: InputDecoration(
                  labelText: punjabiLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: validator,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 180,
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(originalValue),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: englishController,
                decoration: InputDecoration(
                  labelText: englishLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: validator,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: punjabiController,
                decoration: InputDecoration(
                  labelText: punjabiLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: validator,
              ),
            ),
          ],
        );
      },
    );
  }
}
