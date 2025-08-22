import 'package:flutter/material.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final TaskCategory category;
  final String emoji;
  final bool isCompleted;
  final DateTime? completedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.emoji,
    this.isCompleted = false,
    this.completedAt,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskCategory? category,
    String? emoji,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      emoji: emoji ?? this.emoji,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.toString(),
      'emoji': emoji,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: TaskCategory.values.firstWhere(
        (e) => e.toString() == json['category'],
        orElse: () => TaskCategory.other,
      ),
      emoji: json['emoji'],
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }
}

enum TaskCategory {
  shortAndFun,
  active,
  creative,
  social,
  challenge,
  motivation,
  other,
}

extension TaskCategoryExtension on TaskCategory {
  String get displayName {
    switch (this) {
      case TaskCategory.shortAndFun:
        return 'Kısa & Keyifli';
      case TaskCategory.active:
        return 'Hareketli';
      case TaskCategory.creative:
        return 'Yaratıcı & Eğlenceli';
      case TaskCategory.social:
        return 'Sosyal & İletişim';
      case TaskCategory.challenge:
        return 'Eğlenceli Mini Meydan Okumalar';
      case TaskCategory.motivation:
        return 'Keyif ve Motivasyon';
      case TaskCategory.other:
        return 'Diğer';
    }
  }

  Color get color {
    switch (this) {
      case TaskCategory.shortAndFun:
        return Colors.blue;
      case TaskCategory.active:
        return Colors.green;
      case TaskCategory.creative:
        return Colors.purple;
      case TaskCategory.social:
        return Colors.orange;
      case TaskCategory.challenge:
        return Colors.red;
      case TaskCategory.motivation:
        return Colors.pink;
      case TaskCategory.other:
        return Colors.grey;
    }
  }
}



