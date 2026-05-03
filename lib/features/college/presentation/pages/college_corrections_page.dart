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
    _CorrectionListColumn('Registration Number', ['registrationId', 'studentId']),
    _CorrectionListColumn('Submitted On', ['correctionRequestedAt']),
    _CorrectionListColumn('Name', ['name']),
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
                    .collection('students')
                    .where('collegeId', isEqualTo: collegeId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Unable to load students: ${snapshot.error}',
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final students = snapshot.data?.docs ?? [];

                  if (students.isEmpty) {
                    return const Center(child: Text('No students found'));
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CollegeHeading(collegeId: collegeId),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              columns: [
                                const DataColumn(label: Text('Sr. No.')),
                                ..._columns.map(
                                  (column) => DataColumn(
                                    label: Text(
                                      column.label,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              rows: students.asMap().entries.map((entry) {
                                final student = entry.value;
                                final data = student.data();

                                return DataRow(
                                  cells: [
                                    DataCell(Text('${entry.key + 1}')),
                                    ..._columns.map((column) {
                                      final value = _columnValue(
                                        data,
                                        column.keys,
                                      );

                                    if (column.label ==
                                          'Registration Number') {
                                        final correctionStatus =
                                            (data['correctionRequestStatus']
                                                    as String? ??
                                                '')
                                                .trim()
                                                .toLowerCase();
                                        final isSubmitted =
                                            correctionStatus.isNotEmpty;

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
                                                            CollegeCorrectionDetailPage(
                                                          student: student,
                                                          user: user,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: Text(_formatValue(value)),
                                                ),
                                        );
                                      }

                                      if (column.label == 'Submitted On') {
                                        final correctionStatus =
                                            (data['correctionRequestStatus']
                                                    as String? ??
                                                '')
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
                                          return const DataCell(
                                            Text(
                                              'Rejected',
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          );
                                        }

                                        return DataCell(Text(_formatValue(value)));
                                      }

                                      return DataCell(
                                        Text(_formatValue(value)),
                                      );
                                    }),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
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

  static String _formatDateOnly(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  static String _formatDateTime(DateTime date) {
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
        studentId: _studentIdentifier(widget.student),
        registrationId: _registrationId(widget.student),
        collegeId: user.collegeId ?? '',
        districtId: user.districtId ?? '',
        requestedBy: user.uid,
        studentName: studentData['name'] as String? ?? '',
        fatherName: studentData['fatherName'] as String? ?? '',
        motherName: studentData['motherName'] as String? ?? '',
        nameCorrectionEnglish: _nameCorrectionEnglishController.text.trim(),
        namePunjabi: _namePunjabiController.text.trim(),
        fatherNameCorrectionEnglish:
            _fatherNameCorrectionEnglishController.text.trim(),
        fatherNamePunjabi: _fatherNamePunjabiController.text.trim(),
        motherNameCorrectionEnglish:
            _motherNameCorrectionEnglishController.text.trim(),
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
        SnackBar(
          content: Text('Unable to submit correction request: $error'),
        ),
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

  String _studentIdentifier(QueryDocumentSnapshot<Map<String, dynamic>> student) {
    final data = student.data();
    return data['studentId'] as String? ??
        data['registrationId'] as String? ??
        student.id;
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
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
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
