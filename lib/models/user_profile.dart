import 'package:flutter/material.dart';

enum SchoolStage { ilkokul, ortaokul, lise }

class UserProfile {
  final int points;
  final int completedTasks;
  final int streakDays;
  final DateTime lastSpinDate;
  final List<String> badges;
  final Map<String, int> categoryStats;
  // Son seçildiği tarih (ISO string) per kategori; 12 günlük cooldown için
  final Map<String, String> categoryLastPicked;

  // Quiz sistemi için yeni alanlar
  final int? highestQuizScore;
  final int? fastestQuizTime;
  final double? quizAccuracy;
  final int? totalQuizzes;
  final int? correctQuizAnswers;
  final int? averageQuizTime;
  final int? totalQuizPoints;
  final int? totalGamePoints;

  // Avatar sistemi için yeni alanlar
  final int avatarLevel;
  final int intelligencePoints; // Zeka puanı (Matematik)
  final int strengthPoints; // Güç puanı (Spor)
  final int wisdomPoints; // Bilgelik puanı (Okuma)
  final int creativityPoints; // Yaratıcılık puanı (Sanat)
  final int socialPoints; // Sosyal puanı (İyilik)
  final int techPoints; // Teknoloji puanı
  final List<String> unlockedItems; // Açılan kıyafet/aksesuarlar
  final List<String> unlockedAbilities; // Açılan yetenekler
  final List<String> solvedQuestionIds;

  // Yeni: Sınıf (1-12)
  final int? grade;

  UserProfile({
    this.points = 0,
    this.completedTasks = 0,
    this.streakDays = 0,
    DateTime? lastSpinDate,
    List<String>? badges,
    Map<String, int>? categoryStats,
    Map<String, String>? categoryLastPicked,
    this.highestQuizScore,
    this.fastestQuizTime,
    this.quizAccuracy,
    this.totalQuizzes,
    this.correctQuizAnswers,
    this.averageQuizTime,
    this.totalQuizPoints,
    this.totalGamePoints,
    this.avatarLevel = 1,
    this.intelligencePoints = 0,
    this.strengthPoints = 0,
    this.wisdomPoints = 0,
    this.creativityPoints = 0,
    this.socialPoints = 0,
    this.techPoints = 0,
    List<String>? unlockedItems,
    List<String>? unlockedAbilities,
    List<String>? solvedQuestionIds,
    this.grade,
  })  : lastSpinDate = lastSpinDate ?? DateTime.now(),
        badges = badges ?? [],
        categoryStats = categoryStats ?? {},
        categoryLastPicked = categoryLastPicked ?? {},
        unlockedItems = unlockedItems ?? [],
        unlockedAbilities = unlockedAbilities ?? [],
        solvedQuestionIds = solvedQuestionIds ?? [];

  // Toplam puanları hesapla
  int get totalAllPoints =>
      points + (totalQuizPoints ?? 0) + (totalGamePoints ?? 0);

  // Avatar için toplam deneyim puanı
  int get totalAvatarExperience =>
      intelligencePoints +
      strengthPoints +
      wisdomPoints +
      creativityPoints +
      socialPoints +
      techPoints;

  // Sınıfa göre kademe
  SchoolStage? get stage {
    if (grade == null) return null;
    if (grade! >= 1 && grade! <= 4) return SchoolStage.ilkokul;
    if (grade! >= 5 && grade! <= 8) return SchoolStage.ortaokul;
    if (grade! >= 9 && grade! <= 12) return SchoolStage.lise;
    return null;
  }

  UserProfile copyWith({
    int? points,
    int? completedTasks,
    int? streakDays,
    DateTime? lastSpinDate,
    List<String>? badges,
    Map<String, int>? categoryStats,
    Map<String, String>? categoryLastPicked,
    int? highestQuizScore,
    int? fastestQuizTime,
    double? quizAccuracy,
    int? totalQuizzes,
    int? correctQuizAnswers,
    int? averageQuizTime,
    int? totalQuizPoints,
    int? avatarLevel,
    int? intelligencePoints,
    int? strengthPoints,
    int? wisdomPoints,
    int? creativityPoints,
    int? socialPoints,
    int? techPoints,
    List<String>? unlockedItems,
    List<String>? unlockedAbilities,
    List<String>? solvedQuestionIds,
    int? totalGamePoints,
    int? grade,
  }) {
    return UserProfile(
      points: points ?? this.points,
      completedTasks: completedTasks ?? this.completedTasks,
      streakDays: streakDays ?? this.streakDays,
      lastSpinDate: lastSpinDate ?? this.lastSpinDate,
      badges: badges ?? this.badges,
      categoryStats: categoryStats ?? this.categoryStats,
      categoryLastPicked: categoryLastPicked ?? this.categoryLastPicked,
      highestQuizScore: highestQuizScore ?? this.highestQuizScore,
      fastestQuizTime: fastestQuizTime ?? this.fastestQuizTime,
      quizAccuracy: quizAccuracy ?? this.quizAccuracy,
      totalQuizzes: totalQuizzes ?? this.totalQuizzes,
      correctQuizAnswers: correctQuizAnswers ?? this.correctQuizAnswers,
      averageQuizTime: averageQuizTime ?? this.averageQuizTime,
      totalQuizPoints: totalQuizPoints ?? this.totalQuizPoints,
      totalGamePoints: totalGamePoints ?? this.totalGamePoints,
      avatarLevel: avatarLevel ?? this.avatarLevel,
      intelligencePoints: intelligencePoints ?? this.intelligencePoints,
      strengthPoints: strengthPoints ?? this.strengthPoints,
      wisdomPoints: wisdomPoints ?? this.wisdomPoints,
      creativityPoints: creativityPoints ?? this.creativityPoints,
      socialPoints: socialPoints ?? this.socialPoints,
      techPoints: techPoints ?? this.techPoints,
      unlockedItems: unlockedItems ?? this.unlockedItems,
      unlockedAbilities: unlockedAbilities ?? this.unlockedAbilities,
      solvedQuestionIds: solvedQuestionIds ?? this.solvedQuestionIds,
      grade: grade ?? this.grade,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'points': points,
      'completedTasks': completedTasks,
      'streakDays': streakDays,
      'lastSpinDate': lastSpinDate.toIso8601String(),
      'badges': badges,
      'categoryStats': categoryStats,
      'categoryLastPicked': categoryLastPicked,
      'highestQuizScore': highestQuizScore,
      'fastestQuizTime': fastestQuizTime,
      'quizAccuracy': quizAccuracy,
      'totalQuizzes': totalQuizzes,
      'correctQuizAnswers': correctQuizAnswers,
      'averageQuizTime': averageQuizTime,
      'totalQuizPoints': totalQuizPoints,
      'totalGamePoints': totalGamePoints,
      'avatarLevel': avatarLevel,
      'intelligencePoints': intelligencePoints,
      'strengthPoints': strengthPoints,
      'wisdomPoints': wisdomPoints,
      'creativityPoints': creativityPoints,
      'socialPoints': socialPoints,
      'techPoints': techPoints,
      'unlockedItems': unlockedItems,
      'unlockedAbilities': unlockedAbilities,
      'solvedQuestionIds': solvedQuestionIds,
      'grade': grade,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      points: json['points'] ?? 0,
      completedTasks: json['completedTasks'] ?? 0,
      streakDays: json['streakDays'] ?? 0,
      lastSpinDate: json['lastSpinDate'] != null
          ? DateTime.parse(json['lastSpinDate'])
          : DateTime.now(),
      badges: List<String>.from(json['badges'] ?? []),
      categoryStats: Map<String, int>.from(json['categoryStats'] ?? {}),
      categoryLastPicked:
          Map<String, String>.from(json['categoryLastPicked'] ?? {}),
      highestQuizScore: json['highestQuizScore'],
      fastestQuizTime: json['fastestQuizTime'],
      quizAccuracy: json['quizAccuracy']?.toDouble(),
      totalQuizzes: json['totalQuizzes'],
      correctQuizAnswers: json['correctQuizAnswers'],
      averageQuizTime: json['averageQuizTime'],
      totalQuizPoints: json['totalQuizPoints'],
      totalGamePoints: json['totalGamePoints'],
      avatarLevel: json['avatarLevel'] ?? 1,
      intelligencePoints: json['intelligencePoints'] ?? 0,
      strengthPoints: json['strengthPoints'] ?? 0,
      wisdomPoints: json['wisdomPoints'] ?? 0,
      creativityPoints: json['creativityPoints'] ?? 0,
      socialPoints: json['socialPoints'] ?? 0,
      techPoints: json['techPoints'] ?? 0,
      unlockedItems: List<String>.from(json['unlockedItems'] ?? []),
      unlockedAbilities: List<String>.from(json['unlockedAbilities'] ?? []),
      solvedQuestionIds: List<String>.from(json['solvedQuestionIds'] ?? []),
      grade: json['grade'],
    );
  }

  bool get canSpinToday {
    final now = DateTime.now();
    final lastSpin =
        DateTime(lastSpinDate.year, lastSpinDate.month, lastSpinDate.day);
    final today = DateTime(now.year, now.month, now.day);
    return lastSpin.isBefore(today);
  }

  String get level {
    if (points >= 1000) return 'Şans Ustası 🏆';
    if (points >= 500) return 'Şans Şampiyonu 🥇';
    if (points >= 200) return 'Şans Avcısı 🥈';
    if (points >= 100) return 'Şans Adayı 🥉';
    if (points >= 50) return 'Şans Öğrencisi 📚';
    return 'Şans Yeni Başlayan 🌱';
  }

  Color get levelColor {
    if (points >= 1000) return Colors.purple;
    if (points >= 500) return Colors.amber;
    if (points >= 200) return Colors.orange;
    if (points >= 100) return Colors.blue;
    if (points >= 50) return Colors.green;
    return Colors.grey;
  }
}
