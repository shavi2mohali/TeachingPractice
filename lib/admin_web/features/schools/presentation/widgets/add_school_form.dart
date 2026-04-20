import 'package:flutter/material.dart';

import '../../../../../../core/firebase/firestore_service.dart';
import '../../../../../../features/admin/data/models/school_model.dart';

class AddSchoolForm extends StatefulWidget {
  const AddSchoolForm({
    super.key,
    required this.firestoreService,
  });

  final FirestoreService firestoreService;

  @override
  State<AddSchoolForm> createState() => _AddSchoolFormState();
}

class _AddSchoolFormState extends State<AddSchoolForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _principalIdController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _districtController.dispose();
    _principalIdController.dispose();
    super.dispose();
  }

  Future<void> _saveSchool() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final district = _districtController.text.trim();
      final school = SchoolModel(
        schoolId: '',
        name: _nameController.text.trim(),
        code: '',
        districtId: district,
        districtName: district,
        address: '',
        block: '',
        cluster: '',
        principalUserId: _principalIdController.text.trim(),
        capacity: 0,
        currentAssignedCount: 0,
        isActive: true,
        createdBy: 'admin',
        createdAt: now,
        updatedAt: now,
      );

      await widget.firestoreService.addSchool(school);

      if (!mounted) return;

      _nameController.clear();
      _districtController.clear();
      _principalIdController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('School added')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to add school: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 260,
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'School name',
                    border: OutlineInputBorder(),
                  ),
                  validator: _required,
                ),
              ),
              SizedBox(
                width: 220,
                child: TextFormField(
                  controller: _districtController,
                  decoration: const InputDecoration(
                    labelText: 'District',
                    border: OutlineInputBorder(),
                  ),
                  validator: _required,
                ),
              ),
              SizedBox(
                width: 260,
                child: TextFormField(
                  controller: _principalIdController,
                  decoration: const InputDecoration(
                    labelText: 'Principal ID',
                    border: OutlineInputBorder(),
                  ),
                  validator: _required,
                ),
              ),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveSchool,
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add School'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }

    return null;
  }
}
