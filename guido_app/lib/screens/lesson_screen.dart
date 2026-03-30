import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lesson_model.dart';
import '../providers/course_provider.dart';
import '../widgets/content_renderer.dart';
import 'quiz_screen.dart';

class LessonScreen extends StatefulWidget {
  final int lessonId;
  final String courseSlug;

  const LessonScreen({super.key, required this.lessonId, required this.courseSlug});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadLessonDetail(widget.lessonId);
    });
  }

  Future<void> _markComplete(CourseProvider provider) async {
    await provider.completeLesson(widget.lessonId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lesson completed! Keep going 🎉'),
        backgroundColor: Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    final lesson = provider.lessonDetail;
    final isLoading = provider.loadingLesson;
    final completing = provider.completingLesson;
    final course = provider.courseDetail;

    if (isLoading && lesson == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (lesson == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Lesson not found.')),
      );
    }

    final nextLesson = _findNextLesson(lesson, course?.modules ?? []);
    final nextModuleId = _findNextModuleIdForQuiz(lesson, course?.modules ?? []);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: Text(
          lesson.title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time_outlined, size: 14, color: Color(0xFF6B7280)),
                        const SizedBox(width: 4),
                        Text(
                          '${lesson.durationMinutes} min read',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                        if (lesson.isCompleted) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.check_circle, size: 14, color: Color(0xFF16A34A)),
                          const SizedBox(width: 4),
                          const Text('Completed',
                              style: TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),
                    ContentRenderer(content: lesson.content),
                    if (lesson.codeExample != null && lesson.codeExample!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: Color(0xFFD97706), size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Try this code',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ContentRenderer(content: '```python\n${lesson.codeExample}\n```'),
                    ],
                  ],
                ),
              ),
            ),
            _LessonBottomBar(
              lesson: lesson,
              completing: completing,
              nextLesson: nextLesson,
              nextModuleId: nextModuleId,
              courseSlug: widget.courseSlug,
              onComplete: () => _markComplete(provider),
            ),
          ],
        ),
      ),
    );
  }

  LessonDetail? _findNextLesson(LessonDetail lesson, List modules) {
    for (final module in modules) {
      for (var i = 0; i < module.lessons.length; i++) {
        if (module.lessons[i].id == lesson.id && i + 1 < module.lessons.length) {
          return null;
        }
      }
    }
    return null;
  }

  int? _findNextModuleIdForQuiz(LessonDetail lesson, List modules) {
    for (final module in modules) {
      if (module.lessons.isEmpty) continue;
      final lastLesson = module.lessons.last;
      if (lastLesson.id == lesson.id && module.quizCount > 0) {
        return module.id;
      }
    }
    return null;
  }
}

class _LessonBottomBar extends StatelessWidget {
  final LessonDetail lesson;
  final bool completing;
  final LessonDetail? nextLesson;
  final int? nextModuleId;
  final String courseSlug;
  final VoidCallback onComplete;

  const _LessonBottomBar({
    required this.lesson,
    required this.completing,
    required this.nextLesson,
    required this.nextModuleId,
    required this.courseSlug,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    final course = provider.courseDetail;

    if (lesson.isCompleted) {
      final nextModuleIdForQuiz = _resolveNextModuleId(lesson, course?.modules ?? []);
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Lesson Completed',
                      style: TextStyle(
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.w700,
                          fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
            if (nextModuleIdForQuiz != null) ...[
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.quiz_outlined, size: 18),
                    label: const Text('Take Quiz', style: TextStyle(fontWeight: FontWeight.w700)),
                    onPressed: () {
                      final module = (course?.modules ?? []).firstWhere(
                        (m) => m.id == nextModuleIdForQuiz,
                        orElse: () => course!.modules.first,
                      );
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(
                            moduleId: nextModuleIdForQuiz,
                            moduleTitle: module.title,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          onPressed: completing ? null : onComplete,
          child: completing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Mark as Complete'),
        ),
      ),
    );
  }

  int? _resolveNextModuleId(LessonDetail lesson, List modules) {
    for (final module in modules) {
      if (module.lessons.isEmpty) continue;
      final lastLesson = module.lessons.last;
      if (lastLesson.id == lesson.id && module.quizCount > 0) {
        return module.id;
      }
    }
    return null;
  }
}
