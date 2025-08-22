import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/task.dart';
import '../models/user_profile.dart';
import '../models/category.dart';
import '../data/task_data.dart';
import '../data/category_tasks.dart';
import '../widgets/fortune_wheel.dart';
import '../widgets/category_wheel.dart';
import '../widgets/task_card.dart';
import '../widgets/profile_page.dart';

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
  bool _showTaskWheel = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadCompletedTasks();
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
      _completedTasks = tasksJson
          .map((json) => Task.fromJson(jsonDecode(json)))
          .toList();
    });
  }

  Future<void> _saveCompletedTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = _completedTasks
        .map((task) => jsonEncode(task.toJson()))
        .toList();
    await prefs.setStringList('completed_tasks', tasksJson);
  }

  void _onCategorySelected(Category category) {
    setState(() {
      _selectedCategory = category;
      _showTaskWheel = true;
    });
  }

  void _onTaskSelected(Task task) {
    // Görev seçildiğinde direkt tamamla
    _completeTask(task);

    // Görev tamamlandıktan sonra kategori seçimine geri dön
    setState(() {
      _showTaskWheel = false;
      _selectedCategory = null;
    });
  }

  void _completeTask(Task task) {
    final completedTask = task.copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );

    setState(() {
      _completedTasks.insert(0, completedTask);
      _profile = _profile.copyWith(
        points: _profile.points + 10,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.white),
            const SizedBox(width: 8),
            Text('Görev tamamlandı! +10 puan kazandın! 🎉'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _checkAndAddBadges() {
    final newBadges = <String>[];
    final currentBadges = Set<String>.from(_profile.badges);

    // İlk görev rozeti
    if (_profile.completedTasks == 1) {
      newBadges.add('🎯 İlk Görev');
    }

    // Seri gün rozetleri
    if (_profile.streakDays == 7) {
      newBadges.add('🔥 7 Gün Seri');
    }
    if (_profile.streakDays == 30) {
      newBadges.add('🌟 30 Gün Seri');
    }

    // Puan rozetleri
    if (_profile.points >= 100 && !currentBadges.contains('💎 100 Puan')) {
      newBadges.add('💎 100 Puan');
    }
    if (_profile.points >= 500 && !currentBadges.contains('🏆 500 Puan')) {
      newBadges.add('🏆 500 Puan');
    }
    if (_profile.points >= 1000 && !currentBadges.contains('👑 1000 Puan')) {
      newBadges.add('👑 1000 Puan');
    }

    // Kategori rozetleri
    final categoryStats = _profile.categoryStats;
    if ((categoryStats[TaskCategory.creative.toString()] ?? 0) >= 5 &&
        !currentBadges.contains('🎨 Yaratıcı')) {
      newBadges.add('🎨 Yaratıcı');
    }
    if ((categoryStats[TaskCategory.active.toString()] ?? 0) >= 5 &&
        !currentBadges.contains('💪 Aktif')) {
      newBadges.add('💪 Aktif');
    }
    if ((categoryStats[TaskCategory.social.toString()] ?? 0) >= 5 &&
        !currentBadges.contains('🤝 Sosyal')) {
      newBadges.add('🤝 Sosyal');
    }
    if ((categoryStats[TaskCategory.challenge.toString()] ?? 0) >= 5 &&
        !currentBadges.contains('😄 Eğlenceli')) {
      newBadges.add('😄 Eğlenceli');
    }

    if (newBadges.isNotEmpty) {
      setState(() {
        _profile = _profile.copyWith(
          badges: [..._profile.badges, ...newBadges],
        );
      });

      // Rozet kazanma mesajı
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.white),
              const SizedBox(width: 8),
              Text('Yeni rozet kazandın: ${newBadges.first}! 🏆'),
            ],
          ),
          backgroundColor: Colors.amber,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
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
                  _showTaskWheel = false;
                  _selectedCategory = null;
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
          // Görevler sayfası
          _buildTasksPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.casino), label: 'Çark'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt),
            label: 'Görevler',
          ),
        ],
      ),
    );
  }

  Widget _buildWheelPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Hoş geldin mesajı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.orange, Colors.pink],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  '🎉 Hoş Geldin!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bugün ${_profile.level} seviyesindesin!',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_profile.points} puanın var',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Seçilen kategori bilgisi
          if (_selectedCategory != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _selectedCategory!.color,
                    _selectedCategory!.color.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _selectedCategory!.color.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _selectedCategory!.emoji,
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedCategory!.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedCategory!.description,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 32),

          // Çark sistemi
          if (!_showTaskWheel)
            CategoryWheel(
              onCategorySelected: _onCategorySelected,
              canSpin: true, // Test için her zaman çevirilebilir
            )
          else
            FortuneWheel(onTaskSelected: _onTaskSelected, canSpin: true),

          const SizedBox(height: 32),

          // Günlük motivasyon
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  '💭 Günlük Motivasyon',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _getDailyMotivation(),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksPage() {
    return Column(
      children: [
        // Başlık
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.green, Colors.blue],
            ),
          ),
          child: const Column(
            children: [
              Text(
                '📋 Tüm Görevler',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Kategorilere göre düzenlenmiş görevler!',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ],
          ),
        ),

        // Kategori seçimi
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: CategoryData.getAllCategories().length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildCategoryChip(null, 'Tümü', '🔍', Colors.grey);
              }
              final category = CategoryData.getAllCategories()[index - 1];
              return _buildCategoryChip(
                category.id,
                category.name,
                category.emoji,
                category.color,
              );
            },
          ),
        ),

        // Görev listesi
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: TaskData.getAllTasks().length,
            itemBuilder: (context, index) {
              final task = TaskData.getAllTasks()[index];
              final isCompleted = _completedTasks.any((t) => t.id == task.id);
              final completedTask = isCompleted
                  ? _completedTasks.firstWhere((t) => t.id == task.id)
                  : null;

              return TaskCard(
                task: completedTask ?? task,
                onComplete: isCompleted ? null : () => _completeTask(task),
                showCompleteButton: !isCompleted,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(
    String? categoryId,
    String name,
    String emoji,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: FilterChip(
        selected: false,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(name),
          ],
        ),
        onSelected: (selected) {
          // Kategori filtreleme işlemi burada yapılabilir
        },
        backgroundColor: color.withValues(alpha: 0.1),
        selectedColor: color.withValues(alpha: 0.3),
        checkmarkColor: color,
      ),
    );
  }

  String _getDailyMotivation() {
    final motivations = [
      'Her gün yeni bir başlangıç! 🌅',
      'Küçük adımlar büyük değişimler yaratır! 🚀',
      'Bugün harika bir gün olacak! ✨',
      'Kendine inan, her şey mümkün! 💪',
      'Gülümseme bulaşıcıdır, yay! 😊',
      'Her görev seni daha güçlü yapar! 🎯',
      'Şans seninle, sadece çarkı çevir! 🍀',
      'Bugün kendine bir iyilik yap! 💖',
    ];

    final today = DateTime.now();
    final index = today.day % motivations.length;
    return motivations[index];
  }

  @override
  void dispose() {
    super.dispose();
  }
}
