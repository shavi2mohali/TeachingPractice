import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/firebase/firestore_service.dart';
import '../../../admin/data/models/student_model.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/home_logout_actions.dart';
import '../../data/models/exam_eligibility_submission.dart';

class CollegeExamEligibilityPage extends StatefulWidget {
  const CollegeExamEligibilityPage({super.key});

  @override
  State<CollegeExamEligibilityPage> createState() =>
      _CollegeExamEligibilityPageState();
}

class _CollegeExamEligibilityPageState
    extends State<CollegeExamEligibilityPage> {
  static const int _maximumCertificateBytes = 900 * 1024;

  final FirestoreService _firestoreService = FirestoreService();
  final Map<String, TextEditingController> _attendedDaysControllers = {};
  final Set<String> _initializedStudents = {};
  final Map<String, Uint8List> _certificateBytes = {};
  final Map<String, String> _certificateNames = {};
  final Set<String> _submittingStudentIds = {};
  String _streamCollegeId = '';
  Stream<List<StudentModel>>? _studentsStream;
  Stream<List<ExamEligibilitySubmission>>? _submissionsStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final collegeId =
        (context.watch<AuthProvider>().currentUser?.collegeId ?? '').trim();
    if (collegeId == _streamCollegeId) return;

    _streamCollegeId = collegeId;
    _studentsStream = collegeId.isEmpty
        ? null
        : _firestoreService.streamExamEligibilityStudentsByCollege(collegeId);
    _submissionsStream = collegeId.isEmpty
        ? null
        : _firestoreService.streamExamEligibilitySubmissionsByCollege(
            collegeId,
          );
  }

  @override
  void dispose() {
    for (final controller in _attendedDaysControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final collegeId = (user?.collegeId ?? '').trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('October 2026 Exam Eligibility'),
        actions: const [HomeLogoutActions()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: collegeId.isEmpty
            ? const Center(child: Text('College details not found'))
            : StreamBuilder<List<StudentModel>>(
                stream: _studentsStream,
                builder: (context, studentsSnapshot) {
                  if (studentsSnapshot.hasError) {
                    return Center(
                      child: Text(
                        'Unable to load students: ${studentsSnapshot.error}',
                      ),
                    );
                  }
                  if (!studentsSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final students = studentsSnapshot.data!;
                  if (students.isEmpty) {
                    return const Center(
                      child: Text('No students found for this college'),
                    );
                  }

                  return StreamBuilder<List<ExamEligibilitySubmission>>(
                    stream: _submissionsStream,
                    builder: (context, submissionsSnapshot) {
                      if (submissionsSnapshot.hasError) {
                        return Center(
                          child: Text(
                            'Unable to load eligibility submissions: '
                            '${submissionsSnapshot.error}',
                          ),
                        );
                      }
                      if (!submissionsSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final submissionsByStudent = {
                        for (final submission in submissionsSnapshot.data!)
                          submission.studentId: submission,
                      };

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attendance summary',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Minimum attendance: 150 of 200 working days (75%).',
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: Scrollbar(
                              child: SingleChildScrollView(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columns: const [
                                      DataColumn(
                                        label: Text('Registration ID'),
                                      ),
                                      DataColumn(label: Text('Student Name')),
                                      DataColumn(
                                        label: Text('Total Working Days'),
                                      ),
                                      DataColumn(
                                        label: Text('Attended Working Days'),
                                      ),
                                      DataColumn(label: Text('Attendance %')),
                                      DataColumn(label: Text('TP Certificate')),
                                      DataColumn(label: Text('Status')),
                                      DataColumn(label: Text('Action')),
                                    ],
                                    rows: students.map((student) {
                                      final existing =
                                          submissionsByStudent[student
                                              .studentId];
                                      return _buildStudentRow(
                                        student: student,
                                        existing: existing,
                                        user: user!,
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
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

  DataRow _buildStudentRow({
    required StudentModel student,
    required ExamEligibilitySubmission? existing,
    required UserModel user,
  }) {
    final controller = _controllerFor(student.studentId, existing);
    final attendedDays = int.tryParse(controller.text);
    final percentage = attendedDays == null
        ? null
        : ExamEligibilitySubmission.calculateAttendancePercentage(attendedDays);
    final canSubmit =
        existing == null ||
        existing.status == ExamEligibilityStatus.needsCorrection;
    final isSubmitting = _submittingStudentIds.contains(student.studentId);
    final selectedFileName = _certificateNames[student.studentId];
    final existingFileName = existing?.tpCertificateFileName.trim();

    return DataRow(
      cells: [
        DataCell(
          Text(
            student.registrationNumber.trim().isEmpty
                ? student.studentId
                : student.registrationNumber,
          ),
        ),
        DataCell(Text(student.name)),
        const DataCell(Text('200')),
        DataCell(
          SizedBox(
            width: 110,
            child: TextField(
              controller: controller,
              enabled: canSubmit && !isSubmitting,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: '0–200',
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 165,
            child: percentage == null
                ? const Text('—')
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${percentage.toStringAsFixed(1)}%'),
                      Text(
                        percentage >=
                                ExamEligibilitySubmission.eligibilityThreshold
                            ? 'Eligible by attendance'
                            : 'Below minimum attendance',
                        style: TextStyle(
                          color:
                              percentage >=
                                  ExamEligibilitySubmission.eligibilityThreshold
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 180,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton.icon(
                  onPressed: canSubmit && !isSubmitting
                      ? () => _pickCertificate(student.studentId)
                      : null,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Upload PDF'),
                ),
                if (selectedFileName != null ||
                    (existingFileName?.isNotEmpty ?? false))
                  Text(
                    selectedFileName ?? existingFileName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ),
        ),
        DataCell(Text(_statusLabel(existing?.status))),
        DataCell(
          FilledButton(
            onPressed: canSubmit && !isSubmitting
                ? () => _submit(student, existing, user)
                : null,
            child: isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit to DIET'),
          ),
        ),
      ],
    );
  }

  TextEditingController _controllerFor(
    String studentId,
    ExamEligibilitySubmission? existing,
  ) {
    final controller = _attendedDaysControllers.putIfAbsent(
      studentId,
      TextEditingController.new,
    );
    if (_initializedStudents.add(studentId) && existing != null) {
      controller.text = existing.attendedWorkingDays.toString();
    }
    return controller;
  }

  Future<void> _pickCertificate(String studentId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return;

    if (bytes.length > _maximumCertificateBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('TP certificate PDF must be smaller than 900 KB.'),
        ),
      );
      return;
    }

    setState(() {
      _certificateBytes[studentId] = bytes;
      _certificateNames[studentId] = file.name;
    });
  }

  Future<void> _submit(
    StudentModel student,
    ExamEligibilitySubmission? existing,
    UserModel user,
  ) async {
    final attendedDays = int.tryParse(
      _attendedDaysControllers[student.studentId]?.text ?? '',
    );
    if (attendedDays == null ||
        attendedDays < 0 ||
        attendedDays > ExamEligibilitySubmission.requiredWorkingDays) {
      _showMessage('Enter attended working days between 0 and 200.');
      return;
    }

    final certificateBytes =
        _certificateBytes[student.studentId] ?? existing?.tpCertificatePdf;
    final certificateName =
        _certificateNames[student.studentId] ?? existing?.tpCertificateFileName;
    if (certificateBytes == null ||
        certificateBytes.isEmpty ||
        certificateName == null ||
        certificateName.trim().isEmpty) {
      _showMessage('Upload the TP certificate PDF before submitting.');
      return;
    }

    final districtId = student.districtId.trim().isNotEmpty
        ? student.districtId.trim()
        : (user.districtId ?? '').trim();
    if (districtId.isEmpty) {
      _showMessage('District details not found');
      return;
    }

    setState(() => _submittingStudentIds.add(student.studentId));
    final now = DateTime.now();
    try {
      await _firestoreService.submitExamEligibilityRecord(
        ExamEligibilitySubmission(
          submissionId: existing?.submissionId ?? '',
          studentId: student.studentId,
          registrationId: student.registrationNumber.trim().isEmpty
              ? student.studentId
              : student.registrationNumber.trim(),
          studentName: student.name.trim(),
          collegeId: user.collegeId!.trim(),
          districtId: districtId,
          dietId: user.dietId?.trim(),
          attendedWorkingDays: attendedDays,
          tpCertificateFileName: certificateName.trim(),
          tpCertificateMimeType: 'application/pdf',
          tpCertificatePdf: certificateBytes,
          collegeRemarks: existing?.collegeRemarks ?? '',
          status: ExamEligibilityStatus.submittedToDiet,
          submittedBy: user.uid,
          submittedAt: now,
          updatedAt: now,
        ),
      );
      _certificateBytes.remove(student.studentId);
      _certificateNames.remove(student.studentId);
      if (mounted) {
        _showMessage('Exam eligibility record submitted to DIET.');
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Unable to submit eligibility record: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _submittingStudentIds.remove(student.studentId));
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _statusLabel(String? status) {
    return switch (status) {
      ExamEligibilityStatus.submittedToDiet => 'Submitted to DIET',
      ExamEligibilityStatus.needsCorrection => 'Needs correction',
      ExamEligibilityStatus.eligible => 'Eligible',
      ExamEligibilityStatus.notEligible => 'Not eligible',
      ExamEligibilityStatus.draft => 'Draft',
      _ => 'Not submitted',
    };
  }
}
