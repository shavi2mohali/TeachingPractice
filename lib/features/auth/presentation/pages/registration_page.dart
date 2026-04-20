import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/registration_constants.dart';
import 'approval_pending_page.dart';
import '../providers/auth_provider.dart';
import '../widgets/home_logout_actions.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _officerNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _selectedRole;
  String? _selectedDistrict;
  String? _selectedCollegeId;
  String? _selectedDietId;

  @override
  void dispose() {
    _officerNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    try {
      final result = await authProvider.register(
        role: _selectedRole!,
        district: _selectedDistrict!,
        officerName: _officerNameController.text,
        mobile: _mobileController.text,
        email: _emailController.text,
        password: _passwordController.text,
        collegeId: _selectedCollegeId,
        dietId: _selectedDietId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Registration Number: ${result.registrationNumber}. '
            '${RegistrationConstants.pendingApprovalMessage}',
          ),
        ),
      );

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ApprovalPendingPage(
            registrationNumber: result.registrationNumber,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Unable to register.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        actions: const [HomeLogoutActions()],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                    ),
                    items: RegistrationConstants.roles
                        .map(
                          (role) => DropdownMenuItem<String>(
                            value: role,
                            child: Text(role),
                          ),
                        )
                        .toList(),
                    onChanged: isLoading
                        ? null
                        : (value) => setState(() {
                              _selectedRole = value;
                              _selectedCollegeId = null;
                              _selectedDietId = null;
                            }),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedDistrict,
                    decoration: const InputDecoration(
                      labelText: 'District',
                      border: OutlineInputBorder(),
                    ),
                    items: RegistrationConstants.districts
                        .map(
                          (district) => DropdownMenuItem<String>(
                            value: district,
                            child: Text(district),
                          ),
                        )
                        .toList(),
                    onChanged: isLoading
                        ? null
                        : (value) => setState(() {
                              _selectedDistrict = value;
                              _selectedCollegeId = null;
                              _selectedDietId = null;
                            }),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  if (_selectedRole == 'College') ...[
                    _CollegeNameDropdown(
                      value: _selectedCollegeId,
                      enabled: !isLoading,
                      onChanged: (value) {
                        setState(() => _selectedCollegeId = value);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_selectedRole == 'DIET') ...[
                    _RoleEntityDropdown(
                      label: 'DIET Name',
                      collectionPath: 'diets',
                      districtId: _selectedDistrict,
                      filterByDistrict: true,
                      valueField: 'dietId',
                      value: _selectedDietId,
                      enabled: !isLoading && _selectedDistrict != null,
                      onChanged: (value) {
                        setState(() => _selectedDietId = value);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _officerNameController,
                    decoration: const InputDecoration(
                      labelText: 'Officer Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number',
                      border: OutlineInputBorder(),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email ID',
                      border: OutlineInputBorder(),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: isLoading ? null : _register,
                    child: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Register'),
                  ),
                ],
              ),
            ),
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

class _CollegeNameDropdown extends StatelessWidget {
  const _CollegeNameDropdown({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String? value;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('colleges').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Unable to load colleges: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }

        final colleges = snapshot.data?.docs ?? [];

        if (colleges.isEmpty) {
          return const Text('No colleges found');
        }

        final selectedValue = colleges.any((doc) {
          final collegeId = doc.data()['collegeId'] as String? ?? doc.id;
          return collegeId == value;
        })
            ? value
            : null;

        return DropdownButtonFormField<String>(
          value: selectedValue,
          decoration: const InputDecoration(
            labelText: 'College Name',
            border: OutlineInputBorder(),
          ),
          items: colleges
              .map(
                (doc) => DropdownMenuItem<String>(
                  value: doc.data()['collegeId'] as String? ?? doc.id,
                  child: Text(doc.data()['name'] as String? ?? doc.id),
                ),
              )
              .toList(),
          onChanged: enabled ? onChanged : null,
          validator: (selectedValue) {
            if (selectedValue == null || selectedValue.trim().isEmpty) {
              return 'Required';
            }

            return null;
          },
        );
      },
    );
  }
}

class _RoleEntityDropdown extends StatelessWidget {
  const _RoleEntityDropdown({
    required this.label,
    required this.collectionPath,
    required this.districtId,
    required this.filterByDistrict,
    required this.valueField,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final String collectionPath;
  final String? districtId;
  final bool filterByDistrict;
  final String valueField;
  final String? value;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedDistrict = districtId;
    final collection = FirebaseFirestore.instance.collection(collectionPath);
    final stream = filterByDistrict
        ? selectedDistrict == null
            ? null
            : collection
                .where('districtId', isEqualTo: selectedDistrict)
                .snapshots()
        : collection.snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        return DropdownButtonFormField<String>(
          key: ValueKey('$collectionPath-$selectedDistrict-$filterByDistrict'),
          value: value,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          items: docs
              .map(
                (doc) => DropdownMenuItem<String>(
                  value: doc.data()[valueField] as String? ?? doc.id,
                  child: Text(
                    doc.data()['name'] as String? ??
                        doc.data()['shortName'] as String? ??
                        doc.id,
                  ),
                ),
              )
              .toList(),
          onChanged:
              enabled && !snapshot.hasError && docs.isNotEmpty ? onChanged : null,
          validator: (selectedValue) {
            if (snapshot.hasError) {
              return 'Unable to load $label';
            }

            if (filterByDistrict &&
                (selectedDistrict == null || selectedDistrict.trim().isEmpty)) {
              return 'Select district first';
            }

            if (selectedValue == null || selectedValue.trim().isEmpty) {
              return snapshot.connectionState == ConnectionState.waiting
                  ? 'Loading $label'
                  : 'Required';
            }

            return null;
          },
        );
      },
    );
  }
}
