class Validators {
  static String? validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Email is required';

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) return 'Enter a valid email';
    return null;
  }

  static String? validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required';
    if (password.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? validateUsername(String? value) {
    final username = (value ?? '').trim();
    if (username.isEmpty) return 'Username is required';
    if (username.length < 3) return 'Username must be at least 3 characters';
    return null;
  }

  static String? validateConfirmPassword(String password, String? confirmPassword) {
    final confirm = confirmPassword ?? '';
    if (confirm.isEmpty) return 'Please confirm your password';
    if (password != confirm) return 'Passwords do not match';
    return null;
  }
}

