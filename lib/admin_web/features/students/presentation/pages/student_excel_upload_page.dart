import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../data/student_bulk_upload_service.dart';
import '../../data/student_excel_parser.dart';
import '../widgets/dynamic_map_data_table.dart';
import '../../../../../features/auth/presentation/widgets/home_logout_actions.dart';

class StudentExcelUploadPage extends StatefulWidget {
  const StudentExcelUploadPage({super.key});

  @override
  State<StudentExcelUploadPage> createState() => _StudentExcelUploadPageState();
}

class _StudentExcelUploadPageState extends State<StudentExcelUploadPage> {
  final StudentBulkUploadService _uploadService = StudentBulkUploadService();

  List<Map<String, dynamic>> _students = [];
  String? _fileName;
  bool _isParsing = false;
  bool _isUploading = false;
  int _uploadedProgress = 0;
  int _totalProgress = 0;
  StudentBulkUploadResult? _uploadResult;

  Future<void> _pickAndParseExcel() async {
    setState(() {
      _isParsing = true;
      _uploadResult = null;
      _uploadedProgress = 0;
      _totalProgress = 0;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      final file = result?.files.single;
      final bytes = file?.bytes;

      if (file == null || bytes == null) {
        return;
      }

      final students = await parseStudentExcel(bytes);

      if (!mounted) return;

      setState(() {
        _fileName = file.name;
        _students = students;
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to read Excel file: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isParsing = false);
      }
    }
  }

  Future<void> _uploadStudents() async {
    if (_students.isEmpty) return;

    setState(() {
      _isUploading = true;
      _uploadResult = null;
      _uploadedProgress = 0;
      _totalProgress = _students.length;
    });

    try {
      final result = await _uploadService.uploadStudentsBatch(
        _students,
        onProgress: (processedCount, totalCount) {
          if (!mounted) return;

          setState(() {
            _uploadedProgress = processedCount;
            _totalProgress = totalCount;
          });
        },
      );

      if (!mounted) return;

      setState(() => _uploadResult = result);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student upload completed')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to upload students: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _isParsing || _isUploading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Students from Excel'),
        actions: const [HomeLogoutActions()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: isBusy ? null : _pickAndParseExcel,
                  child: Text(_isParsing ? 'Reading...' : 'Choose .xlsx File'),
                ),
                ElevatedButton(
                  onPressed:
                      isBusy || _students.isEmpty ? null : _uploadStudents,
                  child: Text(
                    _isUploading ? 'Importing...' : 'Import Students',
                  ),
                ),
                if (_fileName != null) Text(_fileName!),
                if (_students.isNotEmpty) Text('${_students.length} rows'),
              ],
            ),
            if (_isUploading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _totalProgress == 0
                    ? null
                    : _uploadedProgress / _totalProgress,
              ),
              const SizedBox(height: 8),
              Text('Imported $_uploadedProgress/$_totalProgress students'),
            ],
            if (_uploadResult != null) ...[
              const SizedBox(height: 16),
              Text(
                'Uploaded: ${_uploadResult!.uploadedCount} | '
                'Duplicates skipped: '
                '${_uploadResult!.skippedDuplicateCount} | '
                'Invalid skipped: ${_uploadResult!.skippedInvalidCount}',
              ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: DynamicMapDataTable(rows: _students),
            ),
          ],
        ),
      ),
    );
  }
}
