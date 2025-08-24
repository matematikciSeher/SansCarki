import 'package:flutter/material.dart';

enum QuizCategory {
  matematik,
  fen,
  genelKultur,
  turkce,
  spor,
  sanat,
}

enum QuizDifficulty {
  kolay,
  orta,
  zor,
}

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final QuizCategory category;
  final QuizDifficulty difficulty;
  final String? explanation;
  final int basePoints;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.category,
    required this.difficulty,
    this.explanation,
    required this.basePoints,
  });

  String get correctAnswer => options[correctAnswerIndex];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'category': category.toString(),
      'difficulty': difficulty.toString(),
      'explanation': explanation,
      'basePoints': basePoints,
    };
  }

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'],
      question: json['question'],
      options: List<String>.from(json['options']),
      correctAnswerIndex: json['correctAnswerIndex'],
      category: QuizCategory.values.firstWhere(
        (e) => e.toString() == json['category'],
        orElse: () => QuizCategory.genelKultur,
      ),
      difficulty: QuizDifficulty.values.firstWhere(
        (e) => e.toString() == json['difficulty'],
        orElse: () => QuizDifficulty.orta,
      ),
      explanation: json['explanation'],
      basePoints: json['basePoints'] ?? 10,
    );
  }
}

class QuizResult {
  final String questionId;
  final int selectedAnswerIndex;
  final bool isCorrect;
  final int timeSpent; // milisaniye
  final int earnedPoints;
  final DateTime answeredAt;

  const QuizResult({
    required this.questionId,
    required this.selectedAnswerIndex,
    required this.isCorrect,
    required this.timeSpent,
    required this.earnedPoints,
    required this.answeredAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'selectedAnswerIndex': selectedAnswerIndex,
      'isCorrect': isCorrect,
      'timeSpent': timeSpent,
      'earnedPoints': earnedPoints,
      'answeredAt': answeredAt.toIso8601String(),
    };
  }

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      questionId: json['questionId'],
      selectedAnswerIndex: json['selectedAnswerIndex'],
      isCorrect: json['isCorrect'],
      timeSpent: json['timeSpent'],
      earnedPoints: json['earnedPoints'],
      answeredAt: DateTime.parse(json['answeredAt']),
    );
  }
}

class QuizSession {
  final String id;
  final QuizCategory category;
  final List<QuizQuestion> questions;
  final List<QuizResult> results;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int totalPoints;
  final int correctAnswers;
  final int totalTime;

  const QuizSession({
    required this.id,
    required this.category,
    required this.questions,
    required this.results,
    required this.startedAt,
    this.completedAt,
    required this.totalPoints,
    required this.correctAnswers,
    required this.totalTime,
  });

  double get accuracy =>
      questions.isNotEmpty ? correctAnswers / questions.length : 0.0;
  bool get isCompleted => completedAt != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category.toString(),
      'questions': questions.map((q) => q.toJson()).toList(),
      'results': results.map((r) => r.toJson()).toList(),
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'totalPoints': totalPoints,
      'correctAnswers': correctAnswers,
      'totalTime': totalTime,
    };
  }

  factory QuizSession.fromJson(Map<String, dynamic> json) {
    return QuizSession(
      id: json['id'],
      category: QuizCategory.values.firstWhere(
        (e) => e.toString() == json['category'],
        orElse: () => QuizCategory.genelKultur,
      ),
      questions: (json['questions'] as List)
          .map((q) => QuizQuestion.fromJson(q))
          .toList(),
      results:
          (json['results'] as List).map((r) => QuizResult.fromJson(r)).toList(),
      startedAt: DateTime.parse(json['startedAt']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      totalPoints: json['totalPoints'],
      correctAnswers: json['correctAnswers'],
      totalTime: json['totalTime'],
    );
  }
}

extension QuizCategoryExtension on QuizCategory {
  String get displayName {
    switch (this) {
      case QuizCategory.matematik:
        return 'Matematik';
      case QuizCategory.fen:
        return 'Fen Bilimleri';
      case QuizCategory.genelKultur:
        return 'Genel Kültür';
      case QuizCategory.turkce:
        return 'Türkçe';
      case QuizCategory.spor:
        return 'Spor';
      case QuizCategory.sanat:
        return 'Sanat';
    }
  }

  String get emoji {
    switch (this) {
      case QuizCategory.matematik:
        return '🔢';
      case QuizCategory.fen:
        return '🔬';
      case QuizCategory.genelKultur:
        return '🌍';
      case QuizCategory.turkce:
        return '📚';
      case QuizCategory.spor:
        return '⚽';
      case QuizCategory.sanat:
        return '🎨';
    }
  }

  Color get color {
    switch (this) {
      case QuizCategory.matematik:
        return Colors.blue;
      case QuizCategory.fen:
        return Colors.green;
      case QuizCategory.genelKultur:
        return Colors.purple;
      case QuizCategory.turkce:
        return Colors.orange;
      case QuizCategory.spor:
        return Colors.red;
      case QuizCategory.sanat:
        return Colors.pink;
    }
  }
}

extension QuizDifficultyExtension on QuizDifficulty {
  String get displayName {
    switch (this) {
      case QuizDifficulty.kolay:
        return 'Kolay';
      case QuizDifficulty.orta:
        return 'Orta';
      case QuizDifficulty.zor:
        return 'Zor';
    }
  }

  Color get color {
    switch (this) {
      case QuizDifficulty.kolay:
        return Colors.green;
      case QuizDifficulty.orta:
        return Colors.orange;
      case QuizDifficulty.zor:
        return Colors.red;
    }
  }

  int get timeLimit {
    switch (this) {
      case QuizDifficulty.kolay:
        return 45; // 45 saniye
      case QuizDifficulty.orta:
        return 30; // 30 saniye
      case QuizDifficulty.zor:
        return 20; // 20 saniye
    }
  }
}
