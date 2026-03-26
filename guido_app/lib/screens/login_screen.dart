import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/validators.dart';
import '../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final role = await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin-dashboard');
    } else if (role == 'user') {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
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
                        : const Text('Login'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/signup'),
                    child: const Text("Don't have an account? Sign Up"),
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

