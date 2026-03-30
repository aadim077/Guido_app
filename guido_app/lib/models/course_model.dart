import 'package:flutter/material.dart';

import 'module_model.dart';

class Course {
  final int id;
  final String title;
  final String slug;
  final String description;
  final String difficulty;
  final String colorHex;
  final String icon;
  final int estimatedHours;
  final int order;
  final int totalLessons;
  final int totalModules;
  final bool isEnrolled;
  final List<Module> modules;

  const Course({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
    required this.difficulty,
    required this.colorHex,
    required this.icon,
    required this.estimatedHours,
    required this.order,
    required this.totalLessons,
    required this.totalModules,
    required this.isEnrolled,
    this.modules = const [],
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    final modulesJson = (json['modules'] as List?)?.cast<dynamic>() ?? const [];

    return Course(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '') as String,
      slug: (json['slug'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      difficulty: (json['difficulty'] ?? 'beginner') as String,
      colorHex: (json['color_hex'] ?? '#2196F3') as String,
      icon: (json['icon'] ?? '') as String,
      estimatedHours: (json['estimated_hours'] as num?)?.toInt() ?? 0,
      order: (json['order'] as num?)?.toInt() ?? 0,
      totalLessons: (json['total_lessons'] as num?)?.toInt() ?? 0,
      totalModules: (json['total_modules'] as num?)?.toInt() ?? 0,
      isEnrolled: (json['is_enrolled'] as bool?) ?? false,
      modules: modulesJson.map((m) => Module.fromJson(m as Map<String, dynamic>)).toList(),
    );
  }

  Color get color {
    final hex = colorHex.trim().replaceFirst('#', '');
    final normalized = hex.length == 6 ? 'FF$hex' : hex;
    final value = int.tryParse(normalized, radix: 16) ?? 0xFF2196F3;
    return Color(value);
  }

  String get difficultyLabel {
    final d = difficulty.trim();
    if (d.isEmpty) return 'Beginner';
    return d[0].toUpperCase() + d.substring(1);
  }
}

