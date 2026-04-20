import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/firebase/firestore_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/attendance_model.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final Map<String, bool> _presentByStudentId = {};
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  DateTime get _attendanceDate => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _attendanceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null) return;

    setState(() {
      _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
      );
    });
  }

  Future<void> _saveAttendance({
    required List<AssignedStudentRecord> assignedStudents,
    required String markedBy,
  }) async {
    if (assignedStudents.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();

      for (final assignedStudent in assignedStudents) {
        final studentId = assignedStudent.student.studentId;
        final isPresent = _presentByStudentId[studentId] ?? false;
        final attendance = AttendanceModel(
          attendanceId: '',
          studentId: studentId,
          schoolId: assignedStudent.schoolId,
          allocationId: assignedStudent.allocationId,
          date: _attendanceDate,
          dayNumber: assignedStudent.dayNumberFor(_attendanceDate),
          status: isPresent ? 'present' : 'absent',
          markedBy: markedBy,
          markedAt: now,
          updatedBy: markedBy,
          updatedAt: now,
        );

        await _firestoreService.markAttendance(attendance);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance saved')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save attendance: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Login required')),
      );
    }

    final schoolId = currentUser.schoolId ?? '';

    if (schoolId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('School is not assigned to this user')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Attendance')),
      body: StreamBuilder<List<AssignedStudentRecord>>(
        stream: _firestoreService.streamAssignedStudentsBySchool(schoolId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load students: ${snapshot.error}'),
            );
          }

          final assignedStudents = snapshot.data ?? [];

          if (assignedStudents.isEmpty) {
            return const Center(child: Text('No assigned students'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSaving ? null : _pickDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_formatDate(_attendanceDate)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSaving
                          ? null
                          : () => _saveAttendance(
                                assignedStudents: assignedStudents,
                                markedBy: currentUser.uid,
                              ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: assignedStudents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final assignedStudent = assignedStudents[index];
                    final student = assignedStudent.student;
                    final isPresent =
                        _presentByStudentId[student.studentId] ?? false;

                    return Card(
                      child: CheckboxListTile(
                        value: isPresent,
                        onChanged: _isSaving
                            ? null
                            : (value) {
                                setState(() {
                                  _presentByStudentId[student.studentId] =
                                      value ?? false;
                                });
                              },
                        title: Text(student.name),
                        subtitle: Text(
                          'Registration: ${student.registrationNumber}',
                        ),
                        secondary: Text(isPresent ? 'Present' : 'Absent'),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().padLeft(4, '0');
    return '$day-$month-$year';
  }
}
