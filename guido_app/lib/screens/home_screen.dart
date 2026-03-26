import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
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
        child: user == null
            ? const Center(child: Text('No user loaded'))
            : Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Welcome, ${user.username}!',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      Text('Email: ${user.email}'),
                      Text('Role: ${user.role}'),
                      const SizedBox(height: 6),
                      Text('Phone: ${user.phone ?? '-'}'),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

