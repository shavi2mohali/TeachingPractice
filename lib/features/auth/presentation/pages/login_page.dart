import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes/role_navigation.dart';
import '../../../../core/constants/registration_constants.dart';
import 'approval_pending_page.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../widgets/home_logout_actions.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<app_auth.AuthProvider>();

    try {
      final user = await authProvider.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      await RoleNavigation.navigateToDashboard(
        context: context,
        role: user.role,
      );
    } catch (_) {
      if (!mounted) return;

      final message = authProvider.errorMessage ?? 'Unable to login.';

      if (message == RegistrationConstants.loginPendingMessage) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => const ApprovalPendingPage(
              message: RegistrationConstants.loginPendingMessage,
            ),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController(text: _emailController.text);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Forgot Password'),
          content: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final email = emailController.text.trim();

                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your email address.')),
                  );
                  return;
                }

                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(
                    email: email,
                  );

                  if (!mounted) return;

                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'A password reset link has been sent to your email address.',
                      ),
                    ),
                  );
                } on FirebaseAuthException catch (error) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        error.message ?? 'Unable to send reset link.',
                      ),
                    ),
                  );
                } catch (_) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Unable to send reset link.'),
                    ),
                  );
                }
              },
              child: const Text('Send Reset Link'),
            ),
          ],
        );
      },
    );

    emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<app_auth.AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        actions: const [HomeLogoutActions()],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _login,
                      child: isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: const Text('Forgot Password?'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
