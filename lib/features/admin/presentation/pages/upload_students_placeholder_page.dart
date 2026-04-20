import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../admin_web/features/students/data/student_excel_parser.dart';
import '../../../../admin_web/features/students/presentation/widgets/dynamic_map_data_table.dart';
import '../../../auth/presentation/widgets/home_logout_actions.dart';

class UploadStudentsPlaceholderPage extends StatefulWidget {
  const UploadStudentsPlaceholderPage({super.key});

  @override
  State<UploadStudentsPlaceholderPage> createState() =>
      _UploadStudentsPlaceholderPageState();
}

class _UploadStudentsPlaceholderPageState
    extends State<UploadStudentsPlaceholderPage> {
  List<Map<String, dynamic>> _rows = [];
  String? _fileName;
  bool _isReading = false;

  Future<void> _selectExcelFile() async {
    setState(() => _isReading = true);

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

      final rows = await parseStudentExcel(bytes);

      if (!mounted) return;

      setState(() {
        _fileName = file.name;
        _rows = rows;
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to read Excel file: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isReading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Students'),
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
                  onPressed: _isReading ? null : _selectExcelFile,
                  child: Text(_isReading ? 'Reading...' : 'Select .xlsx File'),
                ),
                if (_fileName != null) Text(_fileName!),
                if (_rows.isNotEmpty) Text('${_rows.length} rows loaded'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: DynamicMapDataTable(rows: _rows),
            ),
          ],
        ),
      ),
    );
  }
}
