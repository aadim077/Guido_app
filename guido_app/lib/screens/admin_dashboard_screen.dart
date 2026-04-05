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
        _error = 'Missing auth token. Please log in again.';
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
    final stats = _payload?['stats'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Admin Dashboard',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        actions: [
          IconButton(
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                            onPressed: _loadDashboard, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (user != null) _WelcomeBanner(username: user.username),
                      const SizedBox(height: 20),
                      _StatsGrid(stats: stats ?? {}),
                      const SizedBox(height: 24),
                      _CourseBreakdownSection(
                        breakdown: (stats?['course_breakdown'] as List<dynamic>? ?? [])
                            .cast<Map<String, dynamic>>(),
                      ),
                      const SizedBox(height: 24),
                      _RecentEnrollmentsSection(
                        enrollments: (stats?['recent_enrollments'] as List<dynamic>? ?? [])
                            .cast<Map<String, dynamic>>(),
                      ),
                      const SizedBox(height: 24),
                      _RecentUsersSection(
                        users: (stats?['recent_users'] as List<dynamic>? ?? [])
                            .cast<Map<String, dynamic>>(),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  final String username;

  const _WelcomeBanner({required this.username});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white24,
            radius: 24,
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : 'A',
              style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back, $username 👋',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              const SizedBox(height: 3),
              const Text('Admin Panel — Guido Platform',
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem(
        icon: Icons.people_alt_outlined,
        color: const Color(0xFF2563EB),
        label: 'Total Users',
        value: stats['total_users']?.toString() ?? '0',
      ),
      _StatItem(
        icon: Icons.school_outlined,
        color: const Color(0xFF16A34A),
        label: 'Courses',
        value: stats['total_courses']?.toString() ?? '0',
      ),
      _StatItem(
        icon: Icons.bookmark_added_outlined,
        color: const Color(0xFFF59E0B),
        label: 'Enrollments',
        value: stats['total_enrollments']?.toString() ?? '0',
      ),
      _StatItem(
        icon: Icons.workspace_premium_outlined,
        color: const Color(0xFF7C3AED),
        label: 'Certificates',
        value: stats['total_certificates']?.toString() ?? '0',
      ),
      _StatItem(
        icon: Icons.code_rounded,
        color: const Color(0xFF0891B2),
        label: 'Code Questions',
        value: stats['total_coding_questions']?.toString() ?? '0',
      ),
      _StatItem(
        icon: Icons.send_rounded,
        color: const Color(0xFFE11D48),
        label: 'Submissions',
        value: stats['total_code_submissions']?.toString() ?? '0',
      ),
      _StatItem(
        icon: Icons.check_circle_outline_rounded,
        color: const Color(0xFF059669),
        label: 'Passed Code',
        value: stats['passed_code_submissions']?.toString() ?? '0',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: items.map((item) => _StatCard(item: item)).toList(),
    );
  }
}

class _StatItem {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });
}

class _StatCard extends StatelessWidget {
  final _StatItem item;

  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(item.icon, color: item.color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(item.value,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          Text(item.label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}

class _CourseBreakdownSection extends StatelessWidget {
  final List<Map<String, dynamic>> breakdown;

  const _CourseBreakdownSection({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      title: 'Course Enrollments',
      icon: Icons.bar_chart_rounded,
      child: Column(
        children: breakdown.map((item) {
          final diff = (item['difficulty'] ?? '') as String;
          final color = diff == 'beginner'
              ? const Color(0xFF16A34A)
              : diff == 'intermediate'
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFFDC2626);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text((item['course'] ?? '') as String,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                Text(
                  '${item['enrollments'] ?? 0} enrolled',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RecentEnrollmentsSection extends StatelessWidget {
  final List<Map<String, dynamic>> enrollments;

  const _RecentEnrollmentsSection({required this.enrollments});

  @override
  Widget build(BuildContext context) {
    if (enrollments.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      title: 'Recent Enrollments',
      icon: Icons.history_edu_rounded,
      child: Column(
        children: enrollments.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: Color(0xFF6B7280)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${e['user']} → ${e['course']}',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  (e['enrolled_at'] ?? '') as String,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RecentUsersSection extends StatelessWidget {
  final List<Map<String, dynamic>> users;

  const _RecentUsersSection({required this.users});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      title: 'Recent Users',
      icon: Icons.group_outlined,
      child: Column(
        children: users.map((u) {
          final username = (u['username'] ?? '') as String;
          final email = (u['email'] ?? '') as String;
          final role = (u['role'] ?? 'user') as String;
          final isAdmin = role == 'admin';

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor:
                      isAdmin ? const Color(0xFF7C3AED) : const Color(0xFF2563EB),
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(username,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      Text(email,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF6B7280))),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? const Color(0xFFEDE9FE)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isAdmin
                          ? const Color(0xFF7C3AED)
                          : const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
