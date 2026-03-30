import 'lesson_model.dart';

class Module {
  final int id;
  final String title;
  final int order;
  final String description;
  final List<LessonListItem> lessons;
  final int quizCount;

  const Module({
    required this.id,
    required this.title,
    required this.order,
    required this.description,
    required this.lessons,
    required this.quizCount,
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    final lessonsJson = (json['lessons'] as List?)?.cast<dynamic>() ?? const [];

    return Module(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '') as String,
      order: (json['order'] as num?)?.toInt() ?? 0,
      description: (json['description'] ?? '') as String,
      lessons: lessonsJson.map((l) => LessonListItem.fromJson(l as Map<String, dynamic>)).toList(),
      quizCount: (json['quiz_count'] as num?)?.toInt() ?? 0,
    );
  }
}

