import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AuthService _authService = AuthService();

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _payload;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final token = await _authService.getAccessToken();
    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Missing token';
      });
      return;
    }

    final result = await _authService.getAdminDashboard(token);
    if (result.containsKey('error')) {
      setState(() {
        _loading = false;
        _error = result['error']?.toString();
      });
      return;
    }

    setState(() {
      _payload = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                : ListView(
                    children: [
                      if (user != null)
                        Card(
                          color: Colors.teal.withOpacity(0.08),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hi, ${user.username}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                Text('Email: ${user.email}'),
                                Text('Role: ${user.role}'),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (_payload?['message'] ?? 'Welcome back') as String,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Total users: ${_payload?['stats']?['total_users'] ?? '-'}',
                                style: const TextStyle(fontSize: 15),
                              ),
                              const SizedBox(height: 8),
                              const Text('Recent users:', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              ...((_payload?['stats']?['recent_users'] as List<dynamic>? ?? [])
                                  .map((u) => Text('- ${(u['email'] ?? '')} (${u['role'] ?? ''})'))
                                  .toList()),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

