import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/task.dart';
import 'task_data.dart';

class TaskRepository {
  TaskRepository._();

  static Future<List<Task>> loadFromAssets() async {
    final jsonStr = await rootBundle.loadString('assets/tasks.json');
    final List<dynamic> list = json.decode(jsonStr) as List<dynamic>;
    return list
        .map((e) => _taskFromJsonLoose(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Task>> loadFromRawText() async {
    final raw = await rootBundle.loadString('assets/tasks_raw.txt');
    return _parseRawTasks(raw);
  }

  static Future<List<Task>> loadAllCombined() async {
    final List<Task> combinedBase = [];
    // Try JSON list
    try {
      combinedBase.addAll(await loadFromAssets());
    } catch (_) {}
    // Try RAW parsed list
    try {
      combinedBase.addAll(await loadFromRawText());
    } catch (_) {}
    // Include built-in code-defined tasks (genel havuz)
    try {
      combinedBase.addAll(TaskData.getAllTasks());
    } catch (_) {}

    // Sınıf seviyesine göre (ilkokul/ortaokul/lise) görevlerini de dahil et
    // Not: ID çakışmalarını önlemek için benzersizleştirip kategori bazlı serpiştiriyoruz
    List<Task> gradeAware = [];
    try {
      gradeAware = TaskData.getGradeAwareTasks();
    } catch (_) {}

    // 1) Mevcut ID'leri topla ve gradeAware ID'lerini benzersizleştir
    final Set<String> existingIds = {
      for (final t in combinedBase) t.id,
    };
    final List<Task> gradeAwareUnique = gradeAware.map((t) {
      String newId = t.id;
      int attempt = 0;
      while (existingIds.contains(newId)) {
        newId = '${t.id}_ga_${attempt++}';
      }
      existingIds.add(newId);
      return t.copyWith(id: newId, allowedGrades: null);
    }).toList();

    // 2) Kategori bazlı serpiştir (base ve gradeAwareUnique)
    final List<Task> interleaved =
        _interleaveByCategory(combinedBase, gradeAwareUnique);

    // 3) Son kez ID bazlı deduplikasyon (güvenlik)
    final Map<String, Task> byId = {for (final t in interleaved) t.id: t};
    return byId.values.toList();
  }

  // Base ve ek listeleri kategori bazlı sırayla karıştırır (A,B,A,B ...)
  static List<Task> _interleaveByCategory(List<Task> base, List<Task> extra) {
    final Map<TaskCategory, List<Task>> baseByCat = {};
    final Map<TaskCategory, List<Task>> extraByCat = {};

    for (final t in base) {
      (baseByCat[t.category] ??= <Task>[]).add(t);
    }
    for (final t in extra) {
      (extraByCat[t.category] ??= <Task>[]).add(t);
    }

    final List<Task> result = [];
    // Kategorileri enum sırasıyla dolaş
    for (final cat in TaskCategory.values) {
      final List<Task> a = baseByCat[cat] ?? const <Task>[];
      final List<Task> b = extraByCat[cat] ?? const <Task>[];

      final int maxLen = a.length > b.length ? a.length : b.length;
      for (int i = 0; i < maxLen; i++) {
        if (i < a.length) result.add(a[i]);
        if (i < b.length) result.add(b[i]);
      }
    }

    // Base'de olup kategorisi enum'a eklenmemiş (theoretical) ya da other kalanlar
    final Set<Task> already = result.toSet();
    for (final t in base) {
      if (!already.contains(t)) result.add(t);
    }
    for (final t in extra) {
      if (!already.contains(t)) result.add(t);
    }
    return result;
  }

  static Task _taskFromJsonLoose(Map<String, dynamic> jsonMap) {
    // categoryId -> TaskCategory
    final String categoryId = (jsonMap['categoryId'] ?? 'other') as String;
    final TaskCategory category = TaskCategory.values.firstWhere(
      (c) => c.toString().split('.').last == categoryId,
      orElse: () => TaskCategory.other,
    );

    // difficulty string -> TaskDifficulty
    final String diffStr = (jsonMap['difficulty'] ?? 'easy') as String;
    final TaskDifficulty difficulty = TaskDifficulty.values.firstWhere(
      (d) => d.toString().split('.').last == diffStr,
      orElse: () => TaskDifficulty.easy,
    );

    // Sınıf bilgisi uygulamada kullanılmıyor
    final List<int>? allowedGrades = null;

    return Task(
      id: jsonMap['id'] as String,
      title: jsonMap['title'] as String,
      description: (jsonMap['description'] ?? '') as String,
      category: category,
      difficulty: difficulty,
      basePoints: (jsonMap['basePoints'] ?? difficulty.minPoints) as int,
      specialBadge: jsonMap['specialBadge'] as String?,
      emoji: (jsonMap['emoji'] ?? '⭐') as String,
      isCompleted: false,
      completedAt: null,
      allowedGrades: allowedGrades,
    );
  }

  static List<Task> _parseRawTasks(String raw) {
    final lines = const LineSplitter().convert(raw);
    String? currentCategoryId;
    List<int>? currentGrades;
    int idxIlk = 0, idxOrt = 0, idxLis = 0;
    final List<Task> tasks = [];

    TaskCategory _mapCategory(String? header) {
      final text = (header ?? '').toLowerCase();
      if (text.contains('zihin')) return TaskCategory.zihin;
      if (text.contains('spor')) return TaskCategory.spor;
      if (text.contains('sanat')) return TaskCategory.sanat;
      if (text.contains('müzik') || text.contains('muzik'))
        return TaskCategory.muzik;
      if (text.contains('teknoloji')) return TaskCategory.teknoloji;
      if (text.contains('iyilik')) return TaskCategory.iyilik;
      if (text.contains('matematik')) return TaskCategory.matematik;
      if (text.contains('fen')) return TaskCategory.fen;
      if (text.contains('oyun') ||
          text.contains('eğlenceli') ||
          text.contains('eglenceli')) return TaskCategory.oyun;
      // Ev & Günlük Yaşam
      if (text.contains('günlük yaşam') ||
          text.contains('gunluk yasam') ||
          text.contains('ev')) return TaskCategory.ev;
      // Kitap & Okuma
      if (text.contains('kitap') || text.contains('okuma'))
        return TaskCategory.kitap;
      // Yazma & Günlük (tek başına "günlük" yazma kategorisine alınır)
      if (text.contains('yazma') ||
          text.contains('günlük') ||
          text.contains('gunluk')) return TaskCategory.yazma;
      return TaskCategory.other;
    }

    List<int> _gradesFor(String header) {
      final h = header.toLowerCase();
      if (h.contains('ilkokul') || h.contains('1–4') || h.contains('1-4')) {
        return [1, 2, 3, 4];
      }
      if (h.contains('ortaokul') || h.contains('5–8') || h.contains('5-8')) {
        return [5, 6, 7, 8];
      }
      if (h.contains('lise') || h.contains('9–12') || h.contains('9-12')) {
        return [9, 10, 11, 12];
      }
      return [];
    }

    String _gradeKey(List<int>? grades) {
      if (grades == null || grades.isEmpty) return 'gen';
      if (grades.first <= 4) return 'ilk';
      if (grades.first <= 8) return 'ort';
      return 'lis';
    }

    TaskDifficulty _difficultyFor(List<int>? grades) {
      if (grades == null || grades.isEmpty) return TaskDifficulty.medium;
      if (grades.first <= 4) return TaskDifficulty.easy;
      if (grades.first <= 8) return TaskDifficulty.medium;
      return TaskDifficulty.hard;
    }

    int _pointsFor(TaskDifficulty d) {
      switch (d) {
        case TaskDifficulty.easy:
          return 10;
        case TaskDifficulty.medium:
          return 18;
        case TaskDifficulty.hard:
          return 24;
        case TaskDifficulty.expert:
          return 36;
      }
    }

    String _emojiFor(TaskCategory c) {
      switch (c) {
        case TaskCategory.kitap:
          return '📚';
        case TaskCategory.yazma:
          return '✍️';
        case TaskCategory.matematik:
          return '🔢';
        case TaskCategory.fen:
          return '🌍';
        case TaskCategory.spor:
          return '🏃';
        case TaskCategory.sanat:
          return '🎨';
        case TaskCategory.muzik:
          return '🎵';
        case TaskCategory.teknoloji:
          return '💻';
        case TaskCategory.iyilik:
          return '❤️';
        case TaskCategory.ev:
          return '🏡';
        case TaskCategory.oyun:
          return '🎲';
        case TaskCategory.zihin:
          return '🧠';
        case TaskCategory.other:
          return '⭐';
      }
    }

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      // Category header
      if (line.contains('Görevleri') || line.contains('Görevler')) {
        final cat = _mapCategory(line);
        currentCategoryId = cat.toString().split('.').last;
        // reset counters per category
        idxIlk = 0;
        idxOrt = 0;
        idxLis = 0;
        continue;
      }

      // Grade header
      if (line.startsWith('📘') ||
          line.startsWith('📗') ||
          line.startsWith('📙') ||
          line.startsWith('📕')) {
        currentGrades = _gradesFor(line);
        continue;
      }

      // Treat any other non-empty line as task title
      if (currentCategoryId == null || currentGrades == null) {
        // skip loose lines until both set
        continue;
      }

      final TaskCategory category = TaskCategory.values.firstWhere(
        (c) => c.toString().split('.').last == currentCategoryId,
        orElse: () => TaskCategory.other,
      );
      final diff = _difficultyFor(currentGrades);
      final points = _pointsFor(diff);
      final gradeKey = _gradeKey(currentGrades);
      int index;
      if (gradeKey == 'ilk') {
        idxIlk += 1;
        index = idxIlk;
      } else if (gradeKey == 'ort') {
        idxOrt += 1;
        index = idxOrt;
      } else {
        idxLis += 1;
        index = idxLis;
      }

      final id =
          '${currentCategoryId}_${gradeKey}_${index.toString().padLeft(3, '0')}';
      final title =
          line.endsWith('.') ? line.substring(0, line.length - 1) : line;
      tasks.add(Task(
        id: id,
        title: title,
        description: title,
        category: category,
        difficulty: diff,
        basePoints: points,
        emoji: _emojiFor(category),
        allowedGrades: null,
      ));
    }

    return tasks;
  }
}

// Basit fallback görev havuzu (assets yüklenmezse)
class TaskRepositoryFallback {
  static final List<Task> sampleTasks = <Task>[
    Task(
      id: 'oyun_ilk_001',
      title: 'Eğlenceli bir oyun oyna',
      description: 'Bugün sevdiğin bir oyunu 10 dakika oyna.',
      category: TaskCategory.oyun,
      difficulty: TaskDifficulty.easy,
      basePoints: 10,
      emoji: '🎲',
    ),
    Task(
      id: 'oyun_ort_001',
      title: 'Arkadaşınla bir oyun paylaş',
      description: 'Bir arkadaşınla kısa bir oyun oynayın.',
      category: TaskCategory.oyun,
      difficulty: TaskDifficulty.medium,
      basePoints: 18,
      emoji: '🎯',
    ),
    Task(
      id: 'oyun_lis_001',
      title: 'Zihin açıcı mini oyun dene',
      description: '5 dakikalık bir zihin egzersizi oyunu oyna.',
      category: TaskCategory.oyun,
      difficulty: TaskDifficulty.hard,
      basePoints: 24,
      emoji: '🧠',
    ),
  ];
}
