import 'package:flutter/foundation.dart' show kIsWeb;
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
import 'performance_settings_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../data/task_repository.dart';
import '../services/user_service.dart';
import '../services/admob_service.dart';

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
  // Ekstra çark: oyun puanına bağlı günlük hak (30K=>1, 60K=>2)
  // DateTime? _extraSpinDate; // eski anahtar için geriye uyum (artık kullanılmıyor)
  String? _extraSpinUsedDay; // 'YYYY-M-D'
  int _extraSpinUsedCount = 0;
  static const int _extraSpinThreshold = 30000; // 30K oyun puanı
  // Günlük ana hak (24 saatte bir)
  String? _dailySpinUsedDay; // 'YYYY-M-D'
  // Ekstra spin arming kaldırıldı; tıklayınca kullanıcı çarkı kendi çevirir
  bool _pendingExtraSpin =
      false; // bir sonraki spin ekstra hak olarak sayılacak
  // Ödüllü reklam izleyerek kazanılan günlük 1 çark hakkı
  String? _rewardedAdSpinWatchDay; // 'YYYY-M-D'
  bool _rewardedAdSpinConsumed = false;

  bool get _isTaskActive => _selectedTask != null;

  bool get _rewardedAdSpinAvailable {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    return _rewardedAdSpinWatchDay == todayStr && !_rewardedAdSpinConsumed;
  }

  /// Bugün reklam izleyerek henüz hak kazanılmadı mı? (1 reklam/gün)
  bool get _canWatchRewardedAdForSpin {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    if (_rewardedAdSpinWatchDay != todayStr) return true;
    return _rewardedAdSpinConsumed; // bugün izledi ve kullandı, yarın tekrar
  }

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
    _loadExtraSpinDate();
    _loadExtraSpinUsage();
    _loadDailySpinUsedDay();
    _loadRewardedAdSpinState();
  }

  Future<void> _loadRewardedAdSpinState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _rewardedAdSpinWatchDay = prefs.getString('rewarded_ad_spin_day');
      _rewardedAdSpinConsumed =
          prefs.getBool('rewarded_ad_spin_consumed') ?? false;
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _saveRewardedAdSpinState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'rewarded_ad_spin_day', _rewardedAdSpinWatchDay ?? '');
      await prefs.setBool('rewarded_ad_spin_consumed', _rewardedAdSpinConsumed);
    } catch (_) {}
  }

  void _consumeRewardedAdSpin() {
    _rewardedAdSpinConsumed = true;
    _saveRewardedAdSpinState();
  }

  Future<void> _watchRewardedAdForSpin() async {
    if (!_canWatchRewardedAdForSpin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bugün zaten reklam izledin. Yarın tekrar deneyebilirsin.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ödüllü reklam web\'de desteklenmez.')),
      );
      return;
    }
    if (!AdMobService.instance.isRewardedAdReady(
      RewardedPlacement.homeExtraSpin,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reklam yükleniyor, lütfen biraz bekleyip tekrar deneyin.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    final success = await AdMobService.instance.showRewardedAd(
      placement: RewardedPlacement.homeExtraSpin,
      onRewarded: () {
        final now = DateTime.now();
        _rewardedAdSpinWatchDay = '${now.year}-${now.month}-${now.day}';
        _rewardedAdSpinConsumed = false;
        _saveRewardedAdSpinState();
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tebrikler! Reklam izleyerek çark çevirme hakkı kazandın.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
    );
    if (mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reklam gösterilemedi veya izlenmedi. Lütfen tekrar deneyin.'),
          duration: Duration(seconds: 2),
        ),
      );
    } else if (mounted) {
      setState(() {});
    }
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

  // _useExtraSpin kaldırıldı; artık ampül tıklanınca anında ek spin uygulanıyor

  void _consumeExtraSpin() {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    if (_extraSpinUsedDay != todayStr) {
      _extraSpinUsedDay = todayStr;
      _extraSpinUsedCount = 0;
    }
    _extraSpinUsedCount++;
    _saveExtraSpinUsage();
  }

  void _executeExtraSpin() {
    if (_extraSpinsRemaining <= 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tebrikler! Çarkı bir kez daha çevirme hakkı kazandın.'),
        duration: Duration(seconds: 2),
      ),
    );
    // Ekstra hakkı yükle: kullanıcı çarkı kendisi çevirecek
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    if (_extraSpinUsedDay != todayStr) {
      _extraSpinUsedDay = todayStr;
      _extraSpinUsedCount = 0;
    }
    // bir hak rezerve etmek yerine, canSpin'i etkin tutmak için internal bayrak gerekebilir.
    // Basit çözüm: bir sonraki kategori seçimini ekstra kabul edip hak düşelim.
    // Bunun için küçük bir bayrak set edelim:
    _pendingExtraSpin = true;
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // didChangeDependencies kaldırıldı - gereksiz yüklenmeleri önlemek için
    // Bunun yerine oyun/quiz'den döndüğünde manuel refresh yapılacak
  }

  Future<void> _loadAssetTasks() async {
    try {
      final combined = await TaskRepository.loadAllCombined();
      if (!mounted) return;
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
        if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _categoryCooldownDays = prefs.getInt('category_cooldown_days') ?? 12;
        _taskCooldownDays = prefs.getInt('task_cooldown_days') ?? 480;
      });
    } catch (_) {}
  }

  Future<void> _loadExtraSpinDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Eski anahtar okunur ama kullanılmaz; sadece temizlemek isterseniz buradan silebiliriz
      final raw = prefs.getString('extra_spin_date');
      if (raw != null) {
        await prefs.remove('extra_spin_date');
      }
    } catch (_) {}
  }

  // eski metodlar: kullanılmıyor
  // Future<void> _saveExtraSpinDate(DateTime dt) async {}
  // bool get _canUseExtraSpinToday => _extraSpinsRemaining > 0; // kullanılmıyor

  Future<void> _loadExtraSpinUsage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _extraSpinUsedDay = prefs.getString('extra_spin_used_day');
      _extraSpinUsedCount = prefs.getInt('extra_spin_used_count') ?? 0;
    } catch (_) {}
  }

  Future<void> _saveExtraSpinUsage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('extra_spin_used_day', _extraSpinUsedDay ?? '');
    await prefs.setInt('extra_spin_used_count', _extraSpinUsedCount);
  }

  int get _extraSpinQuota {
    final gp = _profile.totalAllPoints; // toplam puan esas alınsın
    final quota = gp ~/ _extraSpinThreshold; // her 30K için 1 hak
    if (quota >= 2) return 2; // üst sınır 2 (60K+)
    if (quota >= 1) return 1;
    return 0;
  }

  int get _extraSpinsRemaining {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    if (_extraSpinQuota == 0) return 0;
    if (_extraSpinUsedDay != todayStr) return _extraSpinQuota;
    final rem = _extraSpinQuota - _extraSpinUsedCount;
    return rem < 0 ? 0 : rem;
  }

  // Günlük ana spin kullanılabilir mi? (24 saatte bir)
  bool get _canUseDailySpin {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    return _dailySpinUsedDay != todayStr;
  }

  Future<void> _loadDailySpinUsedDay() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _dailySpinUsedDay = prefs.getString('daily_spin_used_day');
    } catch (_) {}
  }

  Future<void> _saveDailySpinUsedDay() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    _dailySpinUsedDay = todayStr;
    await prefs.setString('daily_spin_used_day', todayStr);
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
    try {
      // Kullanıcı mevcut değilse oluştur
      await UserService.ensureUserExists();

      // Firestore'dan profili çek
      final profile = await UserService.getCurrentUserProfile();
      if (profile != null) {
        print('✅ Firestore\'dan profil yüklendi:');
        print('   - Görev Puanı: ${profile.points}');
        print('   - Oyun Puanı: ${profile.totalGamePoints ?? 0}');
        print('   - Quiz Puanı: ${profile.totalQuizPoints ?? 0}');
        print('   - Toplam: ${profile.totalAllPoints}');

        if (!mounted) return;
        setState(() {
          _profile = profile;
        });
        // Oyun/quiz/görev toplam puanına göre rozetleri garanti et
        await _ensurePointBadges();
      } else {
        print('⚠️ Profil bulunamadı, yeni profil oluşturuluyor...');
        // Profil yoksa yeni bir tane oluştur
        if (!mounted) return;
        setState(() {
          _profile = UserProfile();
        });
        await _saveProfile();
      }
    } catch (e) {
      // Hata durumunda varsayılan profil kullan
      print('❌ Profil yükleme hatası: $e');
      if (!mounted) return;
      setState(() {
        _profile = UserProfile();
      });
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
      if (!mounted) return;
      setState(() {
        _profile =
            _profile.copyWith(badges: [..._profile.badges, ...newBadges]);
      });
      await _saveProfile();
    }

    // Oyun puanına özel rozet örneği: 30K+ oyun puanı
    final int gamePts = _profile.totalGamePoints ?? 0;
    if (gamePts >= _extraSpinThreshold && !current.contains('game_30k')) {
      if (!mounted) return;
      setState(() {
        _profile = _profile.copyWith(badges: [..._profile.badges, 'game_30k']);
      });
      await _saveProfile();
    }
  }

  Future<void> _saveProfile() async {
    try {
      // Firestore'a kaydet
      await UserService.updateCurrentUserProfile(_profile);
      print('✅ Profil Firestore\'a kaydedildi:');
      print('   - Görev Puanı: ${_profile.points}');
      print('   - Oyun Puanı: ${_profile.totalGamePoints ?? 0}');
      print('   - Quiz Puanı: ${_profile.totalQuizPoints ?? 0}');
    } catch (e) {
      print('❌ Profil kaydetme hatası: $e');
      // Hata durumunda da devam et
    }
  }

  Future<void> _logout() async {
    try {
      // Firebase Auth'dan çıkış yap
      await UserService.signOut();

      // Local verileri temizle (opsiyonel)
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_profile');
      await prefs.remove('completed_tasks');

      // AuthWrapper otomatik olarak LoginPage'e yönlendirecek
      // Navigator kullanmaya gerek yok
    } catch (e) {
      print('Çıkış hatası: $e');
      // Hata durumunda kullanıcıyı bilgilendir
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Çıkış yapılırken bir hata oluştu')),
        );
      }
    }
  }

  Future<void> _loadCompletedTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList('completed_tasks') ?? [];
    if (!mounted) return;
    setState(() {
      _completedTasks =
          tasksJson.map((json) => Task.fromJson(jsonDecode(json))).toList();
    });
  }

  Future<void> _ensureGradeSelected() async {
    // Sınıf seçimi ekranı kaldırıldı; hiçbir işlem yapma
  }

  Future<void> _saveCompletedTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson =
          _completedTasks.map((task) => jsonEncode(task.toJson())).toList();
      await prefs.setStringList('completed_tasks', tasksJson);

      // Firestore'a da kaydet (opsiyonel - detaylı görev geçmişi için)
      final uid = UserService.getCurrentUserId();
      if (uid != null && _completedTasks.isNotEmpty) {
        // Son tamamlanan görevi aktivite olarak logla
        final lastTask = _completedTasks.first;
        await UserService.logActivity(
          activityType: 'task_completed',
          data: {
            'taskId': lastTask.id,
            'taskTitle': lastTask.title,
            'category': lastTask.category.toString(),
            'points': lastTask.basePoints,
          },
        );
      }
    } catch (e) {
      print('Görev kaydetme hatası: $e');
    }
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

  void _completeTask([Task? specificTask]) async {
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

    await _saveProfile();
    await _saveCompletedTasks();

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
      if (!mounted) return;
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
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 8, 16, 88 + bottomInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 96),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Puan Kartı - Modern Glassmorphism Tasarım
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.deepPurple.shade400,
                    Colors.purple.shade600,
                    Colors.deepPurple.shade700,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Dekoratif daireler (arka plan efekti)
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    left: -30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  // İçerik
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        // Üst kısım - Seviye ve Toplam Puan
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Seviye
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.amber.shade400,
                                      Colors.orange.shade600,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Text(
                                      '🏆',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _profile.level,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black26,
                                            offset: Offset(0, 1),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Dikey ayırıcı
                              Container(
                                height: 20,
                                width: 1.5,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withOpacity(0.0),
                                      Colors.white.withOpacity(0.5),
                                      Colors.white.withOpacity(0.0),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Toplam Puan
                              Row(
                                children: [
                                  const Text(
                                    '💎',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_profile.totalAllPoints}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black26,
                                          offset: Offset(0, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'PUAN',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.8),
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Alt kısım - Puan Detayları
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildPointChip(
                                '⭐', 'Görev', _profile.points, Colors.blue),
                            _buildPointChip('🎮', 'Oyun',
                                _profile.totalGamePoints ?? 0, Colors.green),
                            _buildPointChip('🧠', 'Quiz',
                                _profile.totalQuizPoints ?? 0, Colors.orange),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

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

            const SizedBox(height: 6),

            // Çark sistemi
            if (_selectedTask == null)
              Center(
                child: Column(
                  children: [
                    CategoryWheel(
                      onCategorySelected: (c) {
                        if (_pendingExtraSpin) {
                          _onCategorySelected(c);
                          _consumeExtraSpin();
                          _pendingExtraSpin = false;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ekstra çark hakkını kullandın!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else if (_canUseDailySpin) {
                          _onCategorySelected(c);
                          _saveDailySpinUsedDay();
                        } else if (_rewardedAdSpinAvailable) {
                          _onCategorySelected(c);
                          _consumeRewardedAdSpin();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Reklam hakkını kullandın!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Günlük çark hakkın doldu. Ampül yanarsa ekstra hak kullanabilirsin.'),
                            ),
                          );
                        }
                      },
                      canSpin: _canUseDailySpin ||
                          _pendingExtraSpin ||
                          _rewardedAdSpinAvailable,
                      eligibleCategoryIds: _buildEligibleCategoryIds(),
                    ),
                    if (!(_canUseDailySpin ||
                            _pendingExtraSpin ||
                            _rewardedAdSpinAvailable) &&
                        _canWatchRewardedAdForSpin &&
                        !kIsWeb)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: OutlinedButton.icon(
                          onPressed: AdMobService.instance.isRewardedAdReady(
                                  RewardedPlacement.homeExtraSpin)
                              ? _watchRewardedAdForSpin
                              : null,
                          icon: const Icon(Icons.play_circle_outline, size: 20),
                          label: const Text('Reklam izle + ekstra çark'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                        ),
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
      ),
    );
  }

  Widget _buildPointChip(String emoji, String label, int value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.2),
              Colors.white.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji
            Text(
              emoji,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 3),
            // Değer
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.3,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 1),
            // Label
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: Colors.white.withOpacity(0.85),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToQuizArena() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizArenaScreen(
          profile: _profile,
        ),
      ),
    );
    // Quiz'den döndükten sonra Firestore'dan güncel profili çek
    await _refreshData();
  }

  void _navigateToGameCenter() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameSelectionScreen(
          profile: _profile,
        ),
      ),
    );
    // Oyundan döndükten sonra Firestore'dan güncel profili çek
    await _refreshData();
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
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'Performans Ayarları',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PerformanceSettingsScreen(),
                ),
              );
            },
          ),
          if (_extraSpinsRemaining > 0)
            Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  iconSize: 22,
                  icon: const Icon(Icons.lightbulb, color: Colors.amber),
                  tooltip: 'Ekstra Çark Hakkı',
                  onPressed: _executeExtraSpin,
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_extraSpinsRemaining',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
        ),
      ),
    );
  }
}
