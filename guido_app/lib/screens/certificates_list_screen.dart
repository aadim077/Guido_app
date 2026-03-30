import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../models/certificate_model.dart';
import '../providers/course_provider.dart';
import 'certificate_screen.dart';

class CertificatesListScreen extends StatefulWidget {
  const CertificatesListScreen({super.key});

  @override
  State<CertificatesListScreen> createState() => _CertificatesListScreenState();
}

class _CertificatesListScreenState extends State<CertificatesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadCertificates();
    });
  }

  Future<void> _quickDownload(BuildContext context, Certificate cert, String slug) async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission required.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Downloading…'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 20),
      ),
    );

    final path = await context.read<CourseProvider>().downloadCertificate(cert.certificateId, slug);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();

    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download failed.'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloaded! ✅'), backgroundColor: Color(0xFF16A34A), behavior: SnackBarBehavior.floating),
    );

    await OpenFilex.open(path);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    final certs = provider.certificates;
    final loading = provider.loadingCertificates;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text('My Certificates', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : certs.isEmpty
              ? _EmptyState()
              : RefreshIndicator(
                  onRefresh: () => provider.loadCertificates(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    itemCount: certs.length,
                    itemBuilder: (context, index) {
                      final cert = certs[index];
                      final slug = cert.courseTitle
                          .toLowerCase()
                          .replaceAll(' ', '-')
                          .replaceAll(RegExp(r'[^a-z0-9\-]'), '');
                      return _CertificateTile(
                        certificate: cert,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CertificateScreen(
                              certificate: cert,
                              courseSlug: slug,
                            ),
                          ),
                        ),
                        onDownload: () => _quickDownload(context, cert, slug),
                      );
                    },
                  ),
                ),
    );
  }
}

class _CertificateTile extends StatelessWidget {
  final Certificate certificate;
  final VoidCallback onTap;
  final VoidCallback onDownload;

  const _CertificateTile({
    required this.certificate,
    required this.onTap,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final issued = certificate.issuedAt;
    final dateStr =
        '${_monthShort(issued.month)} ${issued.day}, ${issued.year}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.workspace_premium, color: Color(0xFF7C3AED), size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    certificate.courseTitle,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${certificate.certificateId}',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF6B7280), fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Issued: $dateStr',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDownload,
              icon: const Icon(Icons.download_rounded, color: Color(0xFF2563EB)),
              tooltip: 'Download PDF',
            ),
          ],
        ),
      ),
    );
  }

  String _monthShort(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_outlined, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No Certificates Yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete a full course to earn\nyour first certificate.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.5),
          ),
        ],
      ),
    );
  }
}
