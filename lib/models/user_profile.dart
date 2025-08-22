import 'package:flutter/material.dart';

class UserProfile {
  final int points;
  final int completedTasks;
  final int streakDays;
  final DateTime lastSpinDate;
  final List<String> badges;
  final Map<String, int> categoryStats;

  UserProfile({
    this.points = 0,
    this.completedTasks = 0,
    this.streakDays = 0,
    DateTime? lastSpinDate,
    List<String>? badges,
    Map<String, int>? categoryStats,
  })  : lastSpinDate = lastSpinDate ?? DateTime.now(),
        badges = badges ?? [],
        categoryStats = categoryStats ?? {};

  UserProfile copyWith({
    int? points,
    int? completedTasks,
    int? streakDays,
    DateTime? lastSpinDate,
    List<String>? badges,
    Map<String, int>? categoryStats,
  }) {
    return UserProfile(
      points: points ?? this.points,
      completedTasks: completedTasks ?? this.completedTasks,
      streakDays: streakDays ?? this.streakDays,
      lastSpinDate: lastSpinDate ?? this.lastSpinDate,
      badges: badges ?? this.badges,
      categoryStats: categoryStats ?? this.categoryStats,
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
    );
  }

  bool get canSpinToday {
    final now = DateTime.now();
    final lastSpin = DateTime(lastSpinDate.year, lastSpinDate.month, lastSpinDate.day);
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
