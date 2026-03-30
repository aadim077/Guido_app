import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../models/certificate_model.dart';
import '../providers/auth_provider.dart';
import '../providers/course_provider.dart';
import 'certificate_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadUserProgress();
      context.read<CourseProvider>().loadCertificates();
    });
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Future<void> _downloadCert(BuildContext context, Certificate cert) async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission required.'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
        return;
      }
    }
    if (!context.mounted) return;

    final slug = cert.courseTitle.toLowerCase().replaceAll(' ', '-').replaceAll(RegExp(r'[^a-z0-9\-]'), '');
    final path = await context.read<CourseProvider>().downloadCertificate(cert.certificateId, slug);

    if (!context.mounted) return;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download failed.'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloaded! ✅'), backgroundColor: Color(0xFF16A34A), behavior: SnackBarBehavior.floating));
    await OpenFilex.open(path);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final courseProvider = context.watch<CourseProvider>();
    final user = auth.user;
    final progress = courseProvider.userProgress;
    final certificates = courseProvider.certificates;

    final username = user?.username ?? 'User';
    final email = user?.email ?? '';
    final initials = username.isNotEmpty ? username[0].toUpperCase() : 'U';

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await courseProvider.loadUserProgress();
          await courseProvider.loadCertificates();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: const Color(0xFF2563EB),
                child: Text(
                  initials,
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                username,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(email,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
              ],
              const SizedBox(height: 28),
              _StatsGrid(
                points: progress?.totalPoints ?? 0,
                enrolled: progress?.enrolledCoursesCount ?? 0,
                completed: progress?.completedCoursesCount ?? 0,
                certCount: certificates.length,
              ),
              const SizedBox(height: 28),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('My Certificates',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 12),
              if (courseProvider.loadingCertificates)
                const Center(child: CircularProgressIndicator())
              else if (certificates.isEmpty)
                _EmptyCertificates()
              else
                ...certificates.map((cert) {
                  final slug = cert.courseTitle
                      .toLowerCase()
                      .replaceAll(' ', '-')
                      .replaceAll(RegExp(r'[^a-z0-9\-]'), '');
                  return _ProfileCertTile(
                    cert: cert,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CertificateScreen(certificate: cert, courseSlug: slug),
                      ),
                    ),
                    onDownload: () => _downloadCert(context, cert),
                  );
                }),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEE2E2),
                    foregroundColor: const Color(0xFFDC2626),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  onPressed: () => _logout(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final int points;
  final int enrolled;
  final int completed;
  final int certCount;

  const _StatsGrid({
    required this.points,
    required this.enrolled,
    required this.completed,
    required this.certCount,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.7,
      children: [
        _StatCell(
          icon: Icons.bolt,
          color: const Color(0xFF2563EB),
          value: points.toString(),
          label: 'Points',
        ),
        _StatCell(
          icon: Icons.menu_book_outlined,
          color: const Color(0xFF16A34A),
          value: enrolled.toString(),
          label: 'Enrolled',
        ),
        _StatCell(
          icon: Icons.check_circle_outline,
          color: const Color(0xFFF59E0B),
          value: completed.toString(),
          label: 'Completed',
        ),
        _StatCell(
          icon: Icons.workspace_premium_outlined,
          color: const Color(0xFF7C3AED),
          value: certCount.toString(),
          label: 'Certificates',
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _StatCell({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileCertTile extends StatelessWidget {
  final Certificate cert;
  final VoidCallback onTap;
  final VoidCallback onDownload;

  const _ProfileCertTile({
    required this.cert,
    required this.onTap,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEDE9FE)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium, color: Color(0xFF7C3AED), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cert.courseTitle,
                      style:
                          const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('ID: ${cert.certificateId}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                          fontFamily: 'monospace')),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.download_rounded, color: Color(0xFF2563EB)),
              onPressed: onDownload,
              tooltip: 'Download PDF',
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCertificates extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.workspace_premium_outlined, color: Color(0xFF9CA3AF), size: 32),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Complete a full course to earn certificates.',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
