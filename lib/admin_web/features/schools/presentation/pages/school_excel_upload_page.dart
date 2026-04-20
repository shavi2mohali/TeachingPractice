import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../../features/auth/presentation/widgets/home_logout_actions.dart';
import '../../../students/presentation/widgets/dynamic_map_data_table.dart';
import '../../data/school_bulk_upload_service.dart';
import '../../data/school_excel_parser.dart';

class SchoolExcelUploadPage extends StatefulWidget {
  const SchoolExcelUploadPage({super.key});

  @override
  State<SchoolExcelUploadPage> createState() => _SchoolExcelUploadPageState();
}

class _SchoolExcelUploadPageState extends State<SchoolExcelUploadPage> {
  final SchoolBulkUploadService _uploadService = SchoolBulkUploadService();

  List<Map<String, dynamic>> _schools = [];
  String? _fileName;
  bool _isParsing = false;
  bool _isUploading = false;
  int _uploadedProgress = 0;
  int _totalProgress = 0;
  SchoolBulkUploadResult? _uploadResult;

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

      final schools = await parseSchoolExcel(bytes);

      if (!mounted) return;

      setState(() {
        _fileName = file.name;
        _schools = schools;
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to read schools Excel file: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isParsing = false);
      }
    }
  }

  Future<void> _uploadSchools() async {
    if (_schools.isEmpty) return;

    setState(() {
      _isUploading = true;
      _uploadResult = null;
      _uploadedProgress = 0;
      _totalProgress = _schools.length;
    });

    try {
      final result = await _uploadService.uploadSchoolsBatch(
        _schools,
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
        const SnackBar(content: Text('Schools upload completed')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to upload schools: $error')),
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
        title: const Text('Upload Schools from Excel'),
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
                  onPressed: isBusy || _schools.isEmpty ? null : _uploadSchools,
                  child: Text(
                    _isUploading ? 'Uploading...' : 'Upload Schools',
                  ),
                ),
                if (_fileName != null) Text(_fileName!),
                if (_schools.isNotEmpty) Text('${_schools.length} rows'),
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
              Text('Uploaded $_uploadedProgress/$_totalProgress schools'),
            ],
            if (_uploadResult != null) ...[
              const SizedBox(height: 16),
              Text(
                'Uploaded: ${_uploadResult!.uploadedCount} | '
                'Invalid skipped: ${_uploadResult!.skippedInvalidCount}',
              ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: DynamicMapDataTable(rows: _schools),
            ),
          ],
        ),
      ),
    );
  }
}
