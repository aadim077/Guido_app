import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/validators.dart';
import '../widgets/custom_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    final confirmError = Validators.validateConfirmPassword(password, confirm);
    if (confirmError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(confirmError)));
      return;
    }

    final auth = context.read<AuthProvider>();
    final role = await auth.signup(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: password,
    );

    if (!mounted) return;

    if (role == 'user') {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return Form(
              key: _formKey,
              child: ListView(
                children: [
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _usernameController,
                    labelText: 'Username',
                    hintText: 'johndoe',
                    prefixIcon: Icons.person_outline,
                    validator: Validators.validateUsername,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _emailController,
                    labelText: 'Email',
                    hintText: 'you@guido.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: Validators.validateEmail,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _passwordController,
                    labelText: 'Password',
                    hintText: '••••••••',
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                    validator: Validators.validatePassword,
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    labelText: 'Confirm Password',
                    hintText: '••••••••',
                    obscureText: true,
                    prefixIcon: Icons.lock_outline,
                    validator: (v) => Validators.validateConfirmPassword(_passwordController.text, v),
                  ),
                  const SizedBox(height: 18),
                  if (auth.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        auth.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ElevatedButton(
                    onPressed: auth.isLoading ? null : _submit,
                    child: auth.isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign Up'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: const Text('Already have an account? Login'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

