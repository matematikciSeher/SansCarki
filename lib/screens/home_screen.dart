import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/task.dart';
import '../models/user_profile.dart';
import '../models/category.dart';
import '../models/badge.dart' as app_badge;
import '../widgets/category_wheel.dart';
import '../widgets/task_card.dart';
import '../widgets/profile_page.dart';
import 'quiz_arena_screen.dart';
import 'game_selection_screen.dart';
import '../widgets/app_header.dart';
import '../widgets/fancy_bottom_buttons.dart';
import 'feedback_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../data/task_repository.dart';
import 'carkigo_splash_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  UserProfile _profile = UserProfile();
  List<Task> _completedTasks = [];
  Category? _selectedCategory;
  Task? _selectedTask;
  List<Task>? _assetTasks;
  Map<String, DateTime> _categoryLastSpin = {};
  int _categoryCooldownDays = 12; // varsayilan
  int _taskCooldownDays = 480; // varsayilan

  bool get _isTaskActive => _selectedTask != null;

  @override
  void initState() {
    super.initState();
    _loadProfile().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _ensureGradeSelected();
      });
    });
    _loadCompletedTasks();
    _loadAssetTasks();
    _loadCategorySpinDates();
    _loadCooldowns();
  }

  Set<String> _buildEligibleCategoryIds() {
    final categories = CategoryData.getAllCategories();
    final eligible = <String>{
      for (final c in categories)
        if (_isCategoryEligible(c.id)) c.id,
    };
    // Hepsi cooldown'daysa tümünü serbest bırak (wheel birini seçecek)
    return eligible.isEmpty ? {for (final c in categories) c.id} : eligible;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Oyunlardan döndüğünde profili yenile
    _loadProfile();
  }

  Future<void> _loadAssetTasks() async {
    try {
      final combined = await TaskRepository.loadAllCombined();
      setState(() {
        _assetTasks = combined;
      });
    } catch (e) {
      // yut - assets yoksa boş kalır
    }
  }

  Future<void> _loadCategorySpinDates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('category_last_spin_dates');
      if (raw != null) {
        final Map<String, dynamic> map =
            json.decode(raw) as Map<String, dynamic>;
        setState(() {
          _categoryLastSpin = map.map(
              (key, value) => MapEntry(key, DateTime.parse(value as String)));
        });
      }
    } catch (_) {}
  }

  Future<void> _loadCooldowns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _categoryCooldownDays = prefs.getInt('category_cooldown_days') ?? 12;
        _taskCooldownDays = prefs.getInt('task_cooldown_days') ?? 480;
      });
    } catch (_) {}
  }

  Future<void> _saveCategorySpinDates() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonMap = _categoryLastSpin
        .map((key, value) => MapEntry(key, value.toIso8601String()));
    await prefs.setString('category_last_spin_dates', json.encode(jsonMap));
  }

  bool _isCategoryEligible(String categoryId) {
    final last = _categoryLastSpin[categoryId];
    if (last == null) return true;
    return DateTime.now().difference(last).inDays >= _categoryCooldownDays;
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString('user_profile');
    if (profileJson != null) {
      setState(() {
        _profile = UserProfile.fromJson(json.decode(profileJson));
      });
      // Oyun/quiz/görev toplam puanına göre rozetleri garanti et
      await _ensurePointBadges();
    }
  }

  Future<void> _refreshData() async {
    await _loadProfile();
    await _loadCompletedTasks();
  }

  Future<void> _ensurePointBadges() async {
    final current = Set<String>.from(_profile.badges);
    final newBadges = <String>[];

    void addIfNotHas(String id) {
      if (!current.contains(id) && !newBadges.contains(id)) {
        newBadges.add(id);
      }
    }

    final total = _profile.totalAllPoints;
    if (total >= 5000) {
      final count = total ~/ 5000;
      for (int i = 1; i <= count; i++) {
        addIfNotHas('points_bronz_$i');
      }
    }
    if (total >= 20000) {
      final count = total ~/ 20000;
      for (int i = 1; i <= count; i++) {
        addIfNotHas('points_gumus_$i');
      }
    }
    if (total >= 50000) {
      final count = total ~/ 50000;
      for (int i = 1; i <= count; i++) {
        addIfNotHas('points_altin_$i');
      }
    }
    if (total >= 100000) {
      final count = total ~/ 100000;
      for (int i = 1; i <= count; i++) {
        addIfNotHas('points_elmas_$i');
      }
    }

    if (newBadges.isNotEmpty) {
      setState(() {
        _profile =
            _profile.copyWith(badges: [..._profile.badges, ...newBadges]);
      });
      await _saveProfile();
    }
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', json.encode(_profile.toJson()));
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_profile');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const CarkiGoSplashScreen()),
      (route) => false,
    );
  }

  Future<void> _loadCompletedTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList('completed_tasks') ?? [];
    setState(() {
      _completedTasks =
          tasksJson.map((json) => Task.fromJson(jsonDecode(json))).toList();
    });
  }

  Future<void> _ensureGradeSelected() async {
    // Sınıf seçimi ekranı kaldırıldı; hiçbir işlem yapma
  }

  Future<void> _saveCompletedTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson =
        _completedTasks.map((task) => jsonEncode(task.toJson())).toList();
    await prefs.setStringList('completed_tasks', tasksJson);
  }

  Future<void> _saveTaskProof(
    String taskId, {
    required String? note,
    required String? imagePath,
    String? docPath,
    required String taskTitle,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final proof = {
      'id': id,
      'taskId': taskId,
      'taskTitle': taskTitle,
      'note': note?.trim(),
      'imagePath': imagePath?.trim(),
      'docPath': docPath?.trim(),
      'createdAt': DateTime.now().toIso8601String(),
    };
    // Tekil anahtar (galeri için)
    await prefs.setString('proof_$id', jsonEncode(proof));
    // Global log listesi
    final existingLog = prefs.getStringList('proof_log') ?? [];
    existingLog.add(jsonEncode(proof));
    await prefs.setStringList('proof_log', existingLog);
    // Göreve özel liste
    final taskListKey = 'proofs_task_$taskId';
    final existingTask = prefs.getStringList(taskListKey) ?? [];
    existingTask.add(jsonEncode(proof));
    await prefs.setStringList(taskListKey, existingTask);
  }

  Future<void> _showProofDialogAndComplete(Task task) async {
    final noteController = TextEditingController();
    String? pickedImagePath;
    String? pickedDocPath;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Kanıt Ekle (Opsiyonel)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Not / Açıklama',
                    hintText: 'Kısa bir not yazabilirsin',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                StatefulBuilder(
                  builder: (context, setInnerState) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (pickedImagePath != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.file(
                                File(pickedImagePath!),
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final picker = ImagePicker();
                              final picked = await picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 2000,
                                imageQuality: 90,
                              );
                              if (picked != null) {
                                setInnerState(() {
                                  pickedImagePath = picked.path;
                                });
                              }
                            },
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Galeriden Seç'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final picker = ImagePicker();
                              final picked = await picker.pickImage(
                                source: ImageSource.camera,
                                maxWidth: 2000,
                                imageQuality: 90,
                              );
                              if (picked != null) {
                                setInnerState(() {
                                  pickedImagePath = picked.path;
                                });
                              }
                            },
                            icon: const Icon(Icons.photo_camera),
                            label: const Text('Kamerayla Çek'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final result =
                                  await FilePicker.platform.pickFiles(
                                allowMultiple: false,
                                type: FileType.any,
                              );
                              if (result != null &&
                                  result.files.single.path != null) {
                                setInnerState(() {
                                  pickedDocPath = result.files.single.path;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Belge seçildi.')),
                                );
                              }
                            },
                            icon: const Icon(Icons.description),
                            label: const Text('Belge Ekle (PDF/DOC vb.)'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'save'),
              child: const Text('Kaydet ve Tamamla'),
            ),
          ],
        );
      },
    );

    if (result == 'save') {
      final note = noteController.text.trim();
      String? finalSavedPath;
      if (pickedImagePath != null) {
        // Görseli uygulama belgeler klasörüne kopyala
        final dir = await getApplicationDocumentsDirectory();
        final proofsDir = Directory('${dir.path}/proofs');
        if (!await proofsDir.exists()) {
          await proofsDir.create(recursive: true);
        }
        final fileName =
            'proof_${task.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final destPath = '${proofsDir.path}/$fileName';
        await File(pickedImagePath!).copy(destPath);
        finalSavedPath = destPath;
      }
      String? savedDocPath;
      if (pickedDocPath != null) {
        final dir = await getApplicationDocumentsDirectory();
        final proofsDir = Directory('${dir.path}/proofs');
        if (!await proofsDir.exists()) {
          await proofsDir.create(recursive: true);
        }
        final extension = pickedDocPath!.split('.').last;
        final docName =
            'proof_${task.id}_${DateTime.now().millisecondsSinceEpoch}.$extension';
        final docDest = '${proofsDir.path}/$docName';
        await File(pickedDocPath!).copy(docDest);
        savedDocPath = docDest;
      }
      await _saveTaskProof(
        task.id,
        note: note,
        imagePath: finalSavedPath,
        docPath: savedDocPath,
        taskTitle: task.title,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kanıt kaydedildi ✅'),
          duration: Duration(seconds: 2),
        ),
      );
      _completeTask();
      // Anasayfaya dön (çark ekranına): üst üste navigation varsa ana sayfaya kadar pop
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (result == 'cancel') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Görev tamamlanmadı, puan alamadınız.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _onCategorySelected(Category category) {
    // 12 gün kategori cooldown ve 480 gün görev cooldown bilgisi korunur
    final now = DateTime.now();

    // Çarktan gelen kategori aynen kullanılacak
    final Category finalCategory = category;

    // Görev havuzu (assets + fallback)
    final List<Task> allTasks = [
      ...(_assetTasks ?? const <Task>[]),
      if ((_assetTasks == null || _assetTasks!.isEmpty))
        ...TaskRepositoryFallback.sampleTasks,
    ];
    final List<Task> categoryTasks = allTasks
        .where((task) =>
            task.category.toString().split('.').last == finalCategory.id)
        .toList();

    // 480 gün görev cooldown (sınıf filtresi kaldırıldı)
    final Map<String, DateTime?> lastDone = {
      for (final t in _completedTasks) t.id: t.completedAt
    };
    List<Task> availableTasks = categoryTasks.where((task) {
      final last = lastDone[task.id];
      if (last != null && now.difference(last).inDays < _taskCooldownDays)
        return false;
      return true;
    }).toList();

    if (availableTasks.isNotEmpty) {
      availableTasks.shuffle();
      final randomTask = availableTasks.first;
      setState(() {
        _selectedCategory = finalCategory;
        _selectedTask = randomTask;
      });
      _categoryLastSpin[finalCategory.id] = now;
      _saveCategorySpinDates();
    } else {
      setState(() {
        _selectedCategory = finalCategory;
        _selectedTask = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Bu kategoride uygun görev bulunamadı (cooldown/sınıf filtresi).'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _completeTask([Task? specificTask]) {
    final task = specificTask ?? _selectedTask;
    if (task == null) return;

    final completedTask = task.copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );

    // Görev zorluğuna göre puan hesapla
    int earnedPoints = task.basePoints;
    String? specialBadge = task.specialBadge;

    setState(() {
      _completedTasks.insert(0, completedTask);
      _profile = _profile.copyWith(
        points: _profile.points + earnedPoints,
        completedTasks: _profile.completedTasks + 1,
        streakDays: _profile.streakDays + 1,
        lastSpinDate: DateTime.now(),
      );

      // Kategori istatistiklerini güncelle
      final categoryKey = task.category.toString();
      final currentCount = _profile.categoryStats[categoryKey] ?? 0;
      final newStats = Map<String, int>.from(_profile.categoryStats);
      newStats[categoryKey] = currentCount + 1;
      _profile = _profile.copyWith(categoryStats: newStats);

      // Rozet kontrolü
      _checkAndAddBadges();
    });

    _saveProfile();
    _saveCompletedTasks();

    // Başarı mesajı göster
    String message = 'Görev tamamlandı! +$earnedPoints puan kazandın! 🎉';
    if (specialBadge != null) {
      message += '\nÖzel rozet kazandın! 🏆';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    // Sadece çark sayfasından tamamlanan görevler için kategori seçimine geri dön
    if (specificTask == null) {
      setState(() {
        _selectedCategory = null;
        _selectedTask = null;
        _currentIndex = 0; // Çark sayfasına dön
      });
    }
  }

  // Tekrar çevir kaldırıldı (günlük tek hak)

  void _checkAndAddBadges() {
    final newBadges = <String>[];
    final currentBadges = Set<String>.from(_profile.badges);
    final allBadges = app_badge.BadgeData.getAllBadges();

    // Kullanıcının görev geçmişi
    final completed = _completedTasks;
    final completedByCategory = <String, int>{};
    final completedByDifficultyCount = <TaskDifficulty, int>{};
    final completedCategories = <String>{};

    for (final task in completed) {
      // Kategoriye göre say
      final cat = task.category.toString().split('.').last;
      completedByCategory[cat] = (completedByCategory[cat] ?? 0) + 1;
      completedCategories.add(cat);
      // Zorluk sayımı
      completedByDifficultyCount[task.difficulty] =
          (completedByDifficultyCount[task.difficulty] ?? 0) + 1;
    }

    // Rozet koşullarını kontrol et
    for (final badge in allBadges) {
      if (currentBadges.contains(badge.id)) continue;
      bool earned = false;
      switch (badge.type) {
        case app_badge.BadgeType.zorluk:
          if (badge.requiredDifficulty != null && badge.requiredCount != null) {
            final count =
                completedByDifficultyCount[badge.requiredDifficulty!] ?? 0;
            if (count >= badge.requiredCount!) earned = true;
          }
          break;
        case app_badge.BadgeType.kategori:
          if (badge.categoryId != null && badge.requiredCount != null) {
            final count = completedByCategory[badge.categoryId!] ?? 0;
            if (count >= badge.requiredCount!) earned = true;
          }
          break;
        case app_badge.BadgeType.streak:
          if (badge.requiredCount != null &&
              _profile.streakDays >= badge.requiredCount!) earned = true;
          break;
        case app_badge.BadgeType.cesitlilik:
          if (badge.requiredCount != null &&
              completedCategories.length >= badge.requiredCount!) earned = true;
          break;
        case app_badge.BadgeType.ozel:
          if (badge.id == 'ilk_gorev' && _profile.completedTasks == 1)
            earned = true;
          // Diğer özel rozetler için ek koşullar eklenebilir
          break;
      }
      if (earned) newBadges.add(badge.id);
    }

    // Puan tabanlı rozetler (tek rozet, seviye yükseltmeli):
    // 5000+ → Bronz; 20000+ → Gümüş; 50000+ → Altın; 100000+ → Elmas
    final total = _profile.totalAllPoints;
    String? highestId;
    if (total >= 100000)
      highestId = 'points_elmas';
    else if (total >= 50000)
      highestId = 'points_altin';
    else if (total >= 20000)
      highestId = 'points_gumus';
    else if (total >= 5000) highestId = 'points_bronz';

    if (highestId != null) {
      final pointIds = {
        'points_bronz',
        'points_gumus',
        'points_altin',
        'points_elmas'
      };
      final cleaned =
          _profile.badges.where((b) => !pointIds.contains(b)).toList();
      if (!cleaned.contains(highestId)) cleaned.add(highestId);
      setState(() {
        _profile = _profile.copyWith(badges: cleaned);
      });
    }

    if (newBadges.isNotEmpty) {
      setState(() {
        _profile = _profile.copyWith(
          badges: [..._profile.badges, ...newBadges],
        );
      });
      final allBadges = app_badge.BadgeData.getAllBadges();
      for (final badgeId in newBadges) {
        final badge = allBadges.firstWhere((b) => b.id == badgeId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(badge.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Yeni Rozet: ${badge.name}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: badge.color,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildWheelPage() {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Düz metin olarak puan/başlıklar (alt alta)
            Text('🏆 ${_profile.level}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('⭐ Görev Puanı: ${_profile.points}',
                style: const TextStyle(fontSize: 14)),
            Text('🎮 Oyun Puanı: ${_profile.totalGamePoints ?? 0}',
                style: const TextStyle(fontSize: 14)),
            Text('🧠 Quiz Puanı: ${_profile.totalQuizPoints ?? 0}',
                style: const TextStyle(fontSize: 14)),
            Text('💎 Toplam Puan: ${_profile.totalAllPoints}',
                style: const TextStyle(fontSize: 14)),

            const SizedBox(height: 8),

            // Seçilen kategori bilgisi
            if (_selectedCategory != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _selectedCategory!.color,
                      _selectedCategory!.color.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _selectedCategory!.color.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      _selectedCategory!.emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedCategory!.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedCategory!.description,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 6),

            // Çark sistemi
            if (_selectedTask == null)
              Center(
                child: Column(
                  children: [
                    CategoryWheel(
                      onCategorySelected: (c) {
                        _onCategorySelected(c);
                      },
                      canSpin: true,
                      eligibleCategoryIds: _buildEligibleCategoryIds(),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  // Seçilen görev
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.green,
                          Colors.green.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '🎯 Seçilen Görev',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TaskCard(
                          task: _selectedTask!,
                          onComplete: () =>
                              _showProofDialogAndComplete(_selectedTask!),
                          showCompleteButton: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToQuizArena() async {
    final updatedProfile = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizArenaScreen(
          profile: _profile,
        ),
      ),
    );
    if (updatedProfile != null && updatedProfile is UserProfile) {
      setState(() {
        _profile = updatedProfile;
      });
      // Güncellenmiş profili kaydet ve yenile
      await _saveProfile();
      await _refreshData(); // Profili yenile
    } else {
      await _refreshData(); // Profili yenile
    }
  }

  void _navigateToGameCenter() async {
    final updatedProfile = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameSelectionScreen(
          profile: _profile,
        ),
      ),
    );
    if (updatedProfile != null && updatedProfile is UserProfile) {
      setState(() {
        _profile = updatedProfile;
      });
      // Güncellenmiş profili kaydet ve yenile
      await _saveProfile();
      await _refreshData(); // Profili yenile
    } else {
      await _refreshData(); // Profili yenile
    }
  }

  void _navigateToFeedback() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FeedbackScreen()),
    );
  }

  void _openProfileSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ProfilePage(
        profile: _profile,
        completedTasks: _completedTasks,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppHeaderBar(
        title: '🎯 ÇARKIGO!',
        subtitle: 'Öğren, oyna, keşfet',
        actions: [
          IconButton(
            iconSize: 22,
            icon: const Icon(Icons.person, color: Colors.white),
            tooltip: 'Profil',
            onPressed: _openProfileSheet,
          ),
          IconButton(
            iconSize: 22,
            icon: const Icon(Icons.feedback_outlined, color: Colors.white),
            onPressed: _navigateToFeedback,
            tooltip: 'Görüş ve Öneriler',
          ),
          IconButton(
            iconSize: 22,
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Çıkış',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Çıkış yap?'),
                  content: const Text(
                      'Hesaptan çıkış yapıp giriş ekranına dönülecek.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('İptal'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Evet'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await _logout();
              }
            },
          ),
          if (_selectedCategory != null && _selectedTask == null)
            IconButton(
              iconSize: 22,
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedCategory = null;
                  _selectedTask = null;
                });
              },
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Ana sayfa - Çark
          _buildWheelPage(),
          // Profil sayfası
          ProfilePage(profile: _profile, completedTasks: _completedTasks),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        child: FancyBottomButtons(
          isTaskActive: _isTaskActive,
          onWheelTap: () {
            setState(() {
              _currentIndex = 0;
            });
          },
          onGamesTap: _navigateToGameCenter,
          onQuizTap: _navigateToQuizArena,
          onProfileTap: _openProfileSheet,
        ),
      ),
    );
  }
}
