import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import '../models/task.dart';
import '../models/user_profile.dart';
import '../models/category.dart';
import '../models/badge.dart' as app_badge;
import '../data/task_data.dart';
import '../widgets/category_wheel.dart';
import '../widgets/task_card.dart';
import '../widgets/profile_page.dart';
import 'quiz_arena_screen.dart';
import 'game_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _navIndex = 0;
  UserProfile _profile = UserProfile();
  List<Task> _completedTasks = [];
  Category? _selectedCategory;
  Task? _selectedTask;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadCompletedTasks();
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
    }
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', json.encode(_profile.toJson()));
  }

  Future<void> _loadCompletedTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList('completed_tasks') ?? [];
    setState(() {
      _completedTasks =
          tasksJson.map((json) => Task.fromJson(jsonDecode(json))).toList();
    });
  }

  Future<void> _saveCompletedTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson =
        _completedTasks.map((task) => jsonEncode(task.toJson())).toList();
    await prefs.setStringList('completed_tasks', tasksJson);
  }

  void _onCategorySelected(Category category) {
    // Kategori seçildiğinde o kategoriden rastgele bir görev seç
    List<Task> categoryTasks = [];
    // Kategori ID'sine göre uygun görevleri seç
    final allTasks = TaskData.getAllTasks();
    categoryTasks = allTasks
        .where(
            (task) => task.category.toString().split('.').last == category.id)
        .toList();
    // Tamamlanan görevleri hariç tut
    final completedIds = _completedTasks.map((t) => t.id).toSet();
    final availableTasks =
        categoryTasks.where((task) => !completedIds.contains(task.id)).toList();
    if (availableTasks.isNotEmpty) {
      final random = Random();
      final randomTask = availableTasks[random.nextInt(availableTasks.length)];
      setState(() {
        _selectedCategory = category;
        _selectedTask = randomTask;
      });
    } else {
      setState(() {
        _selectedCategory = category;
        _selectedTask = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bu kategoride yeni görev kalmadı!'),
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
      });
    }
  }

  void _spinAgain() {
    if (_selectedCategory != null) {
      _onCategorySelected(_selectedCategory!);
    }
  }

  void _checkAndAddBadges() {
    final newBadges = <String>[];
    final currentBadges = Set<String>.from(_profile.badges);
    final allBadges = app_badge.BadgeData.getAllBadges();

    // Kullanıcının görev geçmişi
    final completed = _completedTasks;
    final completedByCategory = <String, int>{};
    final completedByDifficulty = <app_badge.BadgeTier, int>{};
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

    if (newBadges.isNotEmpty) {
      setState(() {
        _profile = _profile.copyWith(
          badges: [..._profile.badges, ...newBadges],
        );
      });
      final allBadges = app_badge.BadgeData.getAllBadges();
      for (final badgeId in newBadges) {
        final badge = allBadges.firstWhere((b) => b.id == badgeId);
        _showBadgeEarnedMessage(badge);
      }
    }
  }

  int _getCategoryPoints(String categoryId) {
    // Kategori ID'sine göre puan hesapla
    switch (categoryId) {
      case 'kitap':
        return _getCategoryPointsByTaskCategory(TaskCategory.kitap);
      case 'yazma':
        return _getCategoryPointsByTaskCategory(TaskCategory.yazma);
      case 'matematik':
        return _getCategoryPointsByTaskCategory(TaskCategory.matematik);
      case 'fen':
        return _getCategoryPointsByTaskCategory(TaskCategory.fen);
      case 'spor':
        return _getCategoryPointsByTaskCategory(TaskCategory.spor);
      case 'sanat':
        return _getCategoryPointsByTaskCategory(TaskCategory.sanat);
      case 'muzik':
        return _getCategoryPointsByTaskCategory(TaskCategory.muzik);
      case 'teknoloji':
        return _getCategoryPointsByTaskCategory(TaskCategory.teknoloji);
      case 'iyilik':
        return _getCategoryPointsByTaskCategory(TaskCategory.iyilik);
      case 'ev':
        return _getCategoryPointsByTaskCategory(TaskCategory.ev);
      case 'oyun':
        return _getCategoryPointsByTaskCategory(TaskCategory.oyun);
      case 'zihin':
        return _getCategoryPointsByTaskCategory(TaskCategory.zihin);
      default:
        return 0;
    }
  }

  int _getCategoryPointsByTaskCategory(TaskCategory category) {
    int totalPoints = 0;
    for (final completedTask in _completedTasks) {
      if (completedTask.category == category) {
        totalPoints += completedTask.basePoints;
      }
    }
    return totalPoints;
  }

  void _showBadgeEarnedMessage(app_badge.Badge badge) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(badge.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Yeni Rozet!',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    badge.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: badge.color,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _checkBadgeUpgrades() {
    final currentBadges = Set<String>.from(_profile.badges);
    final allBadges = app_badge.BadgeData.getAllBadges();
    final upgradedBadges = <String>[];

    // Her rozet seviyesi için yükseltme kontrolü
    for (final tier in app_badge.BadgeTier.values) {
      // En üst seviye elmas, mastery yok
      if (tier == app_badge.BadgeTier.elmas) continue;

      final tierBadges = allBadges.where((b) => b.tier == tier).toList();
      final userTierBadges =
          tierBadges.where((b) => currentBadges.contains(b.id)).toList();

      if (userTierBadges.length >= tier.upgradeRequirement) {
        // Yükseltme rozetini bul
        final nextTier = _getNextTier(tier);
        if (nextTier != null) {
          final upgradeBadge = allBadges.firstWhere(
            (b) => b.tier == nextTier && b.categoryId == null,
            orElse: () => allBadges.first,
          );

          if (!currentBadges.contains(upgradeBadge.id)) {
            upgradedBadges.add(upgradeBadge.id);
          }
        }
      }
    }

    // Yükseltme rozetlerini ekle
    if (upgradedBadges.isNotEmpty) {
      setState(() {
        _profile = _profile.copyWith(
          badges: [..._profile.badges, ...upgradedBadges],
        );
      });

      // Yükseltme mesajı göster
      for (final badgeId in upgradedBadges) {
        final badge = allBadges.firstWhere((b) => b.id == badgeId);
        _showBadgeUpgradeMessage(badge);
      }
    }
  }

  app_badge.BadgeTier? _getNextTier(app_badge.BadgeTier currentTier) {
    switch (currentTier) {
      case app_badge.BadgeTier.bronz:
        return app_badge.BadgeTier.gumus;
      case app_badge.BadgeTier.gumus:
        return app_badge.BadgeTier.altin;
      case app_badge.BadgeTier.altin:
        return app_badge.BadgeTier.elmas;
      case app_badge.BadgeTier.elmas:
        return null;
    }
  }

  void _showBadgeUpgradeMessage(app_badge.Badge badge) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.trending_up, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Rozet Yükseltildi!',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${badge.tier?.displayName ?? ''} ${badge.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.purple,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🎯 Şans Çarkı',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.orange,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_selectedCategory != null)
            IconButton(
              icon: const Icon(Icons.arrow_back),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (index) {
          setState(() {
            _navIndex = index;
            if (index == 1) {
              _navigateToGameCenter();
            } else if (index == 2) {
              _navigateToQuizArena();
            } else if (index == 3) {
              _currentIndex = 1; // Profil sayfası
            } else {
              _currentIndex = 0; // Çark sayfası
            }
          });
        },
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.casino), label: 'Çark'),
          BottomNavigationBarItem(icon: Icon(Icons.games), label: 'Oyun'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Quiz'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildWheelPage() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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

            const SizedBox(height: 16),

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

            const SizedBox(height: 12),

            // Çark sistemi
            if (_selectedTask == null)
              Center(
                child: CategoryWheel(
                  onCategorySelected: _onCategorySelected,
                  canSpin: true,
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
                          onComplete: _completeTask,
                          showCompleteButton: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _spinAgain,
                    icon: const Icon(Icons.refresh,
                        color: Colors.white, size: 18),
                    label: const Text(
                      'Tekrar Çevir',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 4,
                    ),
                  ),
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
    } else {
      _loadProfile();
    }
  }

  void _navigateToGameCenter() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameSelectionScreen(
          profile: _profile,
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.25),
            color.withOpacity(0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.20),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.95),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
