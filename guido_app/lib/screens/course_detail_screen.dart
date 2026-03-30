import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course_model.dart';
import '../models/lesson_model.dart';
import '../models/module_model.dart';
import '../providers/auth_provider.dart';
import '../providers/course_provider.dart';
import 'lesson_screen.dart';
import 'quiz_screen.dart';
import 'certificate_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final String slug;

  const CourseDetailScreen({super.key, required this.slug});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadCourseDetail(widget.slug);
    });
  }

  bool _isCourseFullyCompleted(Course course) {
    if (course.modules.isEmpty) return false;
    for (final module in course.modules) {
      for (final lesson in module.lessons) {
        if (!lesson.isCompleted) return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    final course = provider.courseDetail;
    final isLoading = provider.loadingCourseDetail;
    final error = provider.error;

    if (isLoading && course == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null && course == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.read<CourseProvider>().loadCourseDetail(widget.slug),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (course == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Course not found.')));
    }

    final enrolled = course.isEnrolled;
    final fullyCompleted = _isCourseFullyCompleted(course);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _CourseHeroHeader(course: course),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _CourseMetaRow(course: course),
            ),
          ),
          SliverToBoxAdapter(
            child: const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Text(
                'Course Content',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _ModuleSection(
                module: course.modules[index],
                moduleIndex: index,
                courseSlug: course.slug,
                isEnrolled: enrolled,
              ),
              childCount: course.modules.length,
            ),
          ),
          if (fullyCompleted)
            SliverToBoxAdapter(
              child: _CertificateBanner(course: course),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: enrolled
          ? null
          : _EnrollBar(
              slug: course.slug,
              enrolling: provider.enrolling,
            ),
    );
  }
}

class _CourseHeroHeader extends StatelessWidget {
  final Course course;

  const _CourseHeroHeader({required this.course});

  @override
  Widget build(BuildContext context) {
    final color = course.color;

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: color,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: Colors.black26,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0.6)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 32),
                Icon(
                  _iconForCourse(course.icon),
                  size: 64,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    course.difficultyLabel.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForCourse(String icon) {
    switch (icon) {
      case 'python':
        return Icons.terminal;
      case 'intermediate':
        return Icons.functions;
      case 'oop':
        return Icons.account_tree;
      case 'dsa':
        return Icons.schema;
      case 'project':
        return Icons.rocket_launch;
      default:
        return Icons.code;
    }
  }
}

class _CourseMetaRow extends StatelessWidget {
  final Course course;

  const _CourseMetaRow({required this.course});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          course.title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          course.description,
          style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _metaChip(Icons.menu_book_outlined, '${course.totalLessons} Lessons'),
            const SizedBox(width: 10),
            _metaChip(Icons.access_time_outlined, '${course.estimatedHours}h'),
            const SizedBox(width: 10),
            _metaChip(Icons.layers_outlined, '${course.totalModules} Modules'),
          ],
        ),
      ],
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6B7280)),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        ],
      ),
    );
  }
}

class _ModuleSection extends StatelessWidget {
  final Module module;
  final int moduleIndex;
  final String courseSlug;
  final bool isEnrolled;

  const _ModuleSection({
    required this.module,
    required this.moduleIndex,
    required this.courseSlug,
    required this.isEnrolled,
  });

  bool get _allLessonsCompleted => module.lessons.every((l) => l.isCompleted);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${moduleIndex + 1}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  module.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...module.lessons.map((lesson) => _LessonTile(
                lesson: lesson,
                courseSlug: courseSlug,
                isEnrolled: isEnrolled,
              )),
          if (module.quizCount > 0)
            _QuizTile(
              module: module,
              allLessonsCompleted: _allLessonsCompleted,
              isEnrolled: isEnrolled,
            ),
          const SizedBox(height: 4),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final LessonListItem lesson;
  final String courseSlug;
  final bool isEnrolled;

  const _LessonTile({
    required this.lesson,
    required this.courseSlug,
    required this.isEnrolled,
  });

  @override
  Widget build(BuildContext context) {
    final locked = lesson.isLocked || !isEnrolled;
    final completed = lesson.isCompleted;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      leading: locked
          ? const Icon(Icons.lock_outline, color: Color(0xFF9CA3AF))
          : completed
              ? const Icon(Icons.check_circle, color: Color(0xFF16A34A))
              : const Icon(Icons.play_circle_filled, color: Color(0xFF2563EB)),
      title: Text(
        lesson.title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: locked ? Colors.grey : Colors.black87,
        ),
      ),
      trailing: Text(
        '${lesson.durationMinutes} min',
        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
      ),
      onTap: () {
        if (locked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Complete previous lessons first.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LessonScreen(lessonId: lesson.id, courseSlug: courseSlug),
          ),
        ).then((_) {
          if (context.mounted) {
            context.read<CourseProvider>().loadCourseDetail(courseSlug);
          }
        });
      },
    );
  }
}

class _QuizTile extends StatelessWidget {
  final Module module;
  final bool allLessonsCompleted;
  final bool isEnrolled;

  const _QuizTile({
    required this.module,
    required this.allLessonsCompleted,
    required this.isEnrolled,
  });

  @override
  Widget build(BuildContext context) {
    final accessible = allLessonsCompleted && isEnrolled;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: accessible ? const Color(0xFFFEF3C7) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.quiz_outlined,
          size: 20,
          color: accessible ? const Color(0xFFD97706) : const Color(0xFF9CA3AF),
        ),
      ),
      title: Text(
        'Module Quiz',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: accessible ? Colors.black87 : Colors.grey,
        ),
      ),
      subtitle: Text(
        '${module.quizCount} questions',
        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
      ),
      trailing: accessible
          ? const Icon(Icons.chevron_right, color: Color(0xFF6B7280))
          : const Icon(Icons.lock_outline, color: Color(0xFF9CA3AF)),
      onTap: () {
        if (!accessible) {
          final msg = !isEnrolled
              ? 'Enroll in this course to take quizzes.'
              : 'Complete all lessons in this module first.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuizScreen(moduleId: module.id, moduleTitle: module.title),
          ),
        ).then((_) {
          if (context.mounted) {
            context.read<CourseProvider>().loadCourseDetail(
                  context.read<CourseProvider>().courseDetail?.slug ?? '',
                );
          }
        });
      },
    );
  }
}

class _CertificateBanner extends StatelessWidget {
  final Course course;

  const _CertificateBanner({required this.course});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    final hasCert = provider.certificates.any((c) => c.courseTitle == course.title);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium, color: Colors.white, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Course Complete! 🎉',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasCert
                        ? 'Your certificate is ready to download.'
                        : 'Claim your certificate now.',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF7C3AED),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: provider.claimingCertificate
                  ? null
                  : () async {
                      if (hasCert) {
                        final cert = provider.certificates
                            .firstWhere((c) => c.courseTitle == course.title);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CertificateScreen(
                              certificate: cert,
                              courseSlug: course.slug,
                            ),
                          ),
                        );
                        return;
                      }
                      final cert = await provider.claimCertificate(course.slug);
                      if (!context.mounted) return;
                      if (cert != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CertificateScreen(
                              certificate: cert,
                              courseSlug: course.slug,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(provider.error ?? 'Could not claim certificate.'),
                            backgroundColor: Colors.red[700],
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
              child: provider.claimingCertificate
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(hasCert ? 'View' : 'Claim'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnrollBar extends StatelessWidget {
  final String slug;
  final bool enrolling;

  const _EnrollBar({required this.slug, required this.enrolling});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            onPressed: enrolling
                ? null
                : () async {
                    final authProvider = context.read<AuthProvider>();
                    if (authProvider.user == null) {
                      Navigator.pushNamed(context, '/login');
                      return;
                    }
                    await context.read<CourseProvider>().enrollInCourse(slug);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Enrolled successfully! Start learning.'),
                          backgroundColor: Color(0xFF16A34A),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
            child: enrolling
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : const Text('Enroll Now'),
          ),
        ),
      ),
    );
  }
}
