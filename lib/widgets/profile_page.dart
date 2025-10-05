import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/task.dart';
import '../models/badge.dart' as app_badge;
import '../screens/proof_gallery_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';

class ProfilePage extends StatelessWidget {
  final UserProfile profile;
  final List<Task> completedTasks;

  const ProfilePage({
    super.key,
    required this.profile,
    required this.completedTasks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // X kapatma butonu
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 24,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profil başlığı
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                profile.levelColor,
                                profile.levelColor.withValues(alpha: 0.7),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    profile.levelColor.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          profile.level,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: profile.levelColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (profile.grade != null)
                          Text(
                            '${profile.grade}. Sınıf',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          '${profile.points} Puan',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Puan istatistikleri
                  _buildPointsStatsCard(),

                  const SizedBox(height: 24),

                  // Kanıt Galerisi butonu
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProofGalleryScreen()),
                      ),
                      icon:
                          const Icon(Icons.photo_library, color: Colors.white),
                      label: const Text(
                        'Kanıt Galerisi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tüm Rozetleri Gör butonu (Kanıt galerisinin altında)
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => BadgesPage(profile: profile)),
                      ),
                      icon: const Icon(Icons.emoji_events, color: Colors.white),
                      label: const Text(
                        'Tüm Rozetleri Gör',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 8,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Kategori istatistikleri
                  _buildCategoryStatsSection(),

                  const SizedBox(height: 24),

                  // Son tamamlanan görevler
                  _buildRecentTasksSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsStatsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎯 Puan İstatistikleri',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.task_alt,
                  title: 'Görev Puanı',
                  value: '${profile.points}',
                  color: Colors.blue,
                ),
                _buildStatItem(
                  icon: Icons.gamepad,
                  title: 'Oyun Puanı',
                  value: '${profile.totalGamePoints ?? 0}',
                  color: Colors.purple,
                ),
                _buildStatItem(
                  icon: Icons.quiz,
                  title: 'Quiz Puanı',
                  value: '${profile.totalQuizPoints ?? 0}',
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.amber.shade400,
                    Colors.orange.shade400,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      const Text(
                        'Toplam Puan',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${profile.totalAllPoints}',
                        style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 32,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBadgesSection() {
    final allBadges = [
      '🎯 İlk Görev',
      '🔥 7 Gün Seri',
      '🌟 30 Gün Seri',
      '💎 100 Puan',
      '🏆 500 Puan',
      '👑 1000 Puan',
      '🎨 Yaratıcı',
      '💪 Aktif',
      '🤝 Sosyal',
      '😄 Eğlenceli',
    ];

    final earnedBadges = profile.badges.isNotEmpty
        ? profile.badges
        : ['🎯 İlk Görev']; // En az bir rozet

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🏆 Rozetler',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 2,
              runSpacing: 2,
              children: allBadges.map((badge) {
                final isEarned = earnedBadges.contains(badge);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isEarned
                        ? Colors.amber.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isEarned ? Colors.amber : Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 16,
                      color: isEarned ? Colors.amber.shade800 : Colors.grey,
                      fontWeight:
                          isEarned ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryStatsSection() {
    final categories = TaskCategory.values;
    final stats = profile.categoryStats;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📈 Kategori İstatistikleri',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...categories.map((category) {
              final count = stats[category.toString()] ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: category.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        category.displayName,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: category.color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTasksSection() {
    final recentTasks = completedTasks.take(5).toList();

    if (recentTasks.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.task_alt,
                  size: 48,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Henüz görev tamamlamadın!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Çarkı çevir ve görevleri tamamla!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '✅ Son Tamamlanan Görevler',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...recentTasks.map((task) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        task.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          task.title,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (task.completedAt != null)
                        Text(
                          _formatDate(task.completedAt!),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildProofGallerySection() {
    // Artık Profil içinde galeri render etmiyoruz; ayrı sayfaya taşındı
    return const SizedBox.shrink();
  }

  Future<List<File>> _loadProofImages() async {
    final prefs = await SharedPreferences.getInstance();
    final files = <File>[];
    final seen = <String>{};

    // Öncelik: global proof_log
    final log = prefs.getStringList('proof_log') ?? [];
    if (log.isNotEmpty) {
      for (final item in log) {
        try {
          final data = jsonDecode(item) as Map<String, dynamic>;
          final path = data['imagePath'] as String?;
          if (path != null && path.isNotEmpty && !seen.contains(path)) {
            final f = File(path);
            if (await f.exists()) {
              files.add(f);
              seen.add(path);
            }
          }
        } catch (_) {}
      }
      return files;
    }

    // Geriye dönük uyumluluk: tekil proof_* anahtarlarını tara
    final keys = prefs.getKeys();
    final proofKeys = keys.where((k) => k.startsWith('proof_'));
    for (final key in proofKeys) {
      final jsonStr = prefs.getString(key);
      if (jsonStr == null) continue;
      try {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        final path = data['imagePath'] as String?;
        if (path != null && path.isNotEmpty && !seen.contains(path)) {
          final f = File(path);
          if (await f.exists()) {
            files.add(f);
            seen.add(path);
          }
        }
      } catch (_) {}
    }
    return files;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Bugün';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}g';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}

class BadgesPage extends StatelessWidget {
  final UserProfile profile;

  const BadgesPage({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final allBadges =
        List<app_badge.Badge>.from(app_badge.BadgeData.getAllBadges());
    final userBadges = Set<String>.from(profile.badges);

    // Dinamik: puan tabanlı rozetleri kullanıcı rozetlerinden üret
    final List<app_badge.Badge> pointBadges = [];
    for (final id in userBadges) {
      if (!id.startsWith('points_')) continue;
      late app_badge.BadgeTier tier;
      String name;
      String emoji;
      if (id == 'points_bronz') {
        tier = app_badge.BadgeTier.bronz;
        name = 'Bronz Puan Rozeti (≥5000)';
        emoji = tier.emoji;
      } else if (id == 'points_gumus') {
        tier = app_badge.BadgeTier.gumus;
        name = 'Gümüş Puan Rozeti (≥20000)';
        emoji = tier.emoji;
      } else if (id == 'points_altin') {
        tier = app_badge.BadgeTier.altin;
        name = 'Altın Puan Rozeti (≥50000)';
        emoji = tier.emoji;
      } else if (id == 'points_elmas') {
        tier = app_badge.BadgeTier.elmas;
        name = 'Elmas Puan Rozeti (≥100000)';
        emoji = tier.emoji;
      } else {
        continue;
      }
      pointBadges.add(
        app_badge.Badge(
          id: id,
          name: name,
          description: 'Toplam puan eşiği ile kazanıldı',
          emoji: emoji,
          color: tier.color,
          type: app_badge.BadgeType.ozel,
          tier: tier,
        ),
      );
    }
    // Puan rozetlerini en sona ekle ki listede görünsün
    if (pointBadges.isNotEmpty) {
      allBadges.addAll(pointBadges);
    }

    // Rozetleri tipe göre grupla
    final Map<app_badge.BadgeType, List<app_badge.Badge>> groupedBadges = {};
    for (final badge in allBadges) {
      groupedBadges.putIfAbsent(badge.type, () => []).add(badge);
    }

    final typeTitles = {
      app_badge.BadgeType.zorluk: '🎯 Zorluk Rozetleri',
      app_badge.BadgeType.kategori: '🏷️ Kategori Rozetleri',
      app_badge.BadgeType.streak: '🔥 Süreklilik Rozetleri',
      app_badge.BadgeType.cesitlilik: '🌈 Çeşitlilik Rozetleri',
      app_badge.BadgeType.ozel: '⭐ Özel Rozetler',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🏆 Rozet Koleksiyonu',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.purple,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Özet bilgi
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.purple, Colors.blue],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Rozet Koleksiyonun',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${userBadges.length}/${allBadges.length} rozet kazandın',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value:
                        (userBadges.length / allBadges.length).clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Rozet kategorileri
            ...app_badge.BadgeType.values.map((type) {
              final typeBadges = groupedBadges[type] ?? [];
              if (typeBadges.isEmpty) return const SizedBox.shrink();

              return _buildTypeSection(
                context,
                type,
                typeTitles[type]!,
                typeBadges,
                userBadges,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSection(
    BuildContext context,
    app_badge.BadgeType type,
    String title,
    List<app_badge.Badge> typeBadges,
    Set<String> userBadges,
  ) {
    // Rozetleri tier'a göre sırala
    final sortedBadges = List<app_badge.Badge>.from(typeBadges)
      ..sort((a, b) => (a.tier?.index ?? 0).compareTo(b.tier?.index ?? 0));

    final earnedBadges =
        sortedBadges.where((b) => userBadges.contains(b.id)).toList();
    final unearnedBadges =
        sortedBadges.where((b) => !userBadges.contains(b.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kategori başlığı
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getTypeColor(type).withValues(alpha: 0.1),
                _getTypeColor(type).withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getTypeColor(type).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getTypeColor(type),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTypeColor(type).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _getTypeColor(type).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${earnedBadges.length}/${typeBadges.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getTypeColor(type),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: typeBadges.isNotEmpty
                    ? (earnedBadges.length / typeBadges.length).clamp(0.0, 1.0)
                    : 0,
                backgroundColor: _getTypeColor(type).withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(_getTypeColor(type)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Rozetler listesi
        ...sortedBadges.map(
          (badge) => _buildBadgeCardWithProgress(
            context,
            badge,
            userBadges.contains(badge.id),
            type,
            typeBadges,
            userBadges,
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBadgeCardWithProgress(
    BuildContext context,
    app_badge.Badge badge,
    bool isEarned,
    app_badge.BadgeType type,
    List<app_badge.Badge> allTypeBadges,
    Set<String> userBadges,
  ) {
    // Bir üst rozet için gereken bilgileri hesapla
    final nextTierInfo = _getNextTierInfo(badge, allTypeBadges, userBadges);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isEarned
            ? badge.color.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEarned ? badge.color : Colors.grey.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: isEarned
            ? [
                BoxShadow(
                  color: badge.color.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              _showBadgeDetails(context, badge, isEarned, nextTierInfo),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rozet başlığı
                Row(
                  children: [
                    Text(
                      badge.emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            badge.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color:
                                  isEarned ? badge.color : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                badge.tier?.emoji ?? '',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                badge.tier?.displayName ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: badge.tier?.color ?? Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Durum ikonu
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isEarned ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isEarned ? Icons.lock_open : Icons.lock,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Açıklama ve kazanım etiketi
                Text(
                  badge.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isEarned ? Colors.black87 : Colors.grey.shade600,
                  ),
                ),
                if (badge.id.startsWith('points_')) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.orange, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Puanla kazanıldı',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // İlerleme bilgisi
                if (nextTierInfo != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.trending_up,
                                color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Bir Üst Rozete Doğru',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Builder(builder: (context) {
                          final remaining = (nextTierInfo.requiredCount -
                                  nextTierInfo.currentCount)
                              .clamp(0, nextTierInfo.requiredCount);
                          final text = remaining == 0
                              ? 'Hazır! Şartlar tamamlandı'
                              : '$remaining görev kaldı';
                          return Text(
                            text,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade600,
                            ),
                          );
                        }),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: (nextTierInfo.currentCount /
                                  nextTierInfo.requiredCount)
                              .clamp(0.0, 1.0),
                          backgroundColor: Colors.blue.withValues(alpha: 0.2),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ],

                // Gereksinim bilgisi
                if (badge.requiredCount != null &&
                    badge.requiredCount! > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.task_alt,
                        size: 16,
                        color: isEarned ? badge.color : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Gerekli: ${badge.requiredCount} görev',
                        style: TextStyle(
                          fontSize: 12,
                          color: isEarned ? badge.color : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  NextTierInfo? _getNextTierInfo(
    app_badge.Badge badge,
    List<app_badge.Badge> allTypeBadges,
    Set<String> userBadges,
  ) {
    if (badge.tier == null || badge.tier == app_badge.BadgeTier.elmas) {
      return null; // En üst seviye
    }

    // Bir üst tier'ı bul
    app_badge.BadgeTier? nextTier;
    switch (badge.tier!) {
      case app_badge.BadgeTier.bronz:
        nextTier = app_badge.BadgeTier.gumus;
        break;
      case app_badge.BadgeTier.gumus:
        nextTier = app_badge.BadgeTier.altin;
        break;
      case app_badge.BadgeTier.altin:
        nextTier = app_badge.BadgeTier.elmas;
        break;
      default:
        return null;
    }

    // Bir üst tier'daki rozetleri bul
    final nextTierBadges = allTypeBadges
        .where((b) => b.tier == nextTier && b.type == badge.type)
        .toList();

    if (nextTierBadges.isEmpty) return null;

    // Mevcut ilerlemeyi hesapla
    int currentCount = 0;
    int requiredCount = 0;

    for (final nextBadge in nextTierBadges) {
      if (nextBadge.requiredCount != null) {
        requiredCount += nextBadge.requiredCount!;
      }
      // Kullanıcının bu rozet için yaptığı görevleri say
      if (nextBadge.type == app_badge.BadgeType.zorluk) {
        // Zorluk rozetleri için mevcut görev sayısını hesapla
        currentCount =
            _getCompletedTasksByDifficulty(nextBadge.requiredDifficulty);
      } else if (nextBadge.type == app_badge.BadgeType.kategori) {
        // Kategori rozetleri için mevcut görev sayısını hesapla
        currentCount = _getCompletedTasksByCategory(nextBadge.categoryId);
      } else if (nextBadge.type == app_badge.BadgeType.streak) {
        // Streak rozetleri için mevcut gün sayısını hesapla
        currentCount = profile.streakDays;
      }
    }

    return NextTierInfo(
      nextTier: nextTier!,
      currentCount: currentCount,
      requiredCount: requiredCount,
    );
  }

  int _getCompletedTasksByDifficulty(TaskDifficulty? difficulty) {
    if (difficulty == null) return 0;
    // Bu fonksiyon profile'dan tamamlanan görevleri saymalı
    // Şimdilik basit bir hesaplama
    return profile.completedTasks;
  }

  int _getCompletedTasksByCategory(String? categoryId) {
    if (categoryId == null) return 0;
    return profile.categoryStats[categoryId] ?? 0;
  }

  Color _getTypeColor(app_badge.BadgeType type) {
    switch (type) {
      case app_badge.BadgeType.zorluk:
        return Colors.orange;
      case app_badge.BadgeType.kategori:
        return Colors.green;
      case app_badge.BadgeType.streak:
        return Colors.red;
      case app_badge.BadgeType.cesitlilik:
        return Colors.purple;
      case app_badge.BadgeType.ozel:
        return Colors.blue;
    }
  }

  void _showBadgeDetails(
    BuildContext context,
    app_badge.Badge badge,
    bool isEarned,
    NextTierInfo? nextTierInfo,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(badge.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                badge.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                badge.description,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),

              // Tier bilgisi
              Row(
                children: [
                  Text(
                    badge.tier?.emoji ?? '',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    badge.tier?.displayName ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: badge.tier?.color ?? Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Gereksinim bilgileri
              if (badge.requiredCount != null && badge.requiredCount! > 0) ...[
                _buildRequirementInfo(
                    'Gerekli Görev', '${badge.requiredCount} görev'),
                const SizedBox(height: 8),
              ],

              if (badge.categoryId != null) ...[
                _buildRequirementInfo(
                    'Kategori', _getCategoryName(badge.categoryId!)),
                const SizedBox(height: 8),
              ],

              if (badge.requiredDifficulty != null) ...[
                _buildRequirementInfo(
                    'Zorluk', _getDifficultyName(badge.requiredDifficulty!)),
                const SizedBox(height: 8),
              ],

              // Bir üst rozet bilgisi
              if (nextTierInfo != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Builder(builder: (context) {
                    final total = nextTierInfo.requiredCount;
                    final current = nextTierInfo.currentCount;
                    final safeTotal = total <= 0 ? 1 : total;
                    final progress = (current / safeTotal).clamp(0.0, 1.0);
                    final remaining = (safeTotal - current).clamp(0, safeTotal);
                    final remainText = remaining == 0
                        ? 'Hazır! Şartlar tamamlandı'
                        : '$remaining görev kaldı';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.trending_up, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Bir Üst Rozet: ${nextTierInfo.nextTier.displayName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'İlerleme: $current/$total',
                          style: const TextStyle(color: Colors.blue),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          remainText,
                          style: TextStyle(
                              color: Colors.blue.shade600, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.blue.withValues(alpha: 0.2),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ],
                    );
                  }),
                ),
              ],

              const SizedBox(height: 16),

              // Durum bilgisi
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isEarned
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isEarned ? Colors.green : Colors.grey,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isEarned ? Icons.check_circle : Icons.lock,
                      color: isEarned ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        isEarned
                            ? 'Hazır — Kazanıldı'
                            : 'Bu rozeti henüz kazanamadın',
                        style: TextStyle(
                          fontSize: isEarned ? 14 : 12,
                          fontWeight: FontWeight.bold,
                          color: isEarned ? Colors.green : Colors.grey.shade400,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementInfo(String title, String value) {
    return Row(
      children: [
        Text(
          '$title: ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  String _getDifficultyName(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return 'Kolay';
      case TaskDifficulty.medium:
        return 'Orta';
      case TaskDifficulty.hard:
        return 'Zor';
      case TaskDifficulty.expert:
        return 'Uzman';
    }
  }

  String _getCategoryName(String categoryId) {
    switch (categoryId) {
      case 'kitap':
        return 'Kitap & Okuma';
      case 'yazma':
        return 'Yazma & Günlük';
      case 'matematik':
        return 'Matematik';
      case 'fen':
        return 'Fen Bilimleri';
      case 'spor':
        return 'Spor & Hareket';
      case 'sanat':
        return 'Sanat & Yaratıcılık';
      case 'muzik':
        return 'Müzik';
      case 'teknoloji':
        return 'Teknoloji';
      case 'iyilik':
        return 'İyilik & Sosyal';
      case 'ev':
        return 'Ev & Günlük Yaşam';
      case 'oyun':
        return 'Eğlenceli Oyun';
      case 'zihin':
        return 'Zihin Egzersizi';
      default:
        return 'Genel';
    }
  }
}

class NextTierInfo {
  final app_badge.BadgeTier nextTier;
  final int currentCount;
  final int requiredCount;

  NextTierInfo({
    required this.nextTier,
    required this.currentCount,
    required this.requiredCount,
  });
}

// Top-level helpers for proof gallery
Future<void> _openFullscreen(BuildContext context, File file) async {
  return showDialog(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          InteractiveViewer(
            child: Image.file(file, fit: BoxFit.contain),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _confirmDelete(BuildContext context, File file) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Fotoğrafı sil?'),
      content: const Text('Bu fotoğrafı galeriden kaldırmak istiyor musun?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Sil'),
        ),
      ],
    ),
  );
  if (ok == true) {
    await _deleteProof(file);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fotoğraf silindi.')),
      );
    }
  }
}

Future<void> _deleteProof(File file) async {
  final prefs = await SharedPreferences.getInstance();
  final keys = prefs.getKeys().where((k) => k.startsWith('proof_'));
  for (final key in keys) {
    final jsonStr = prefs.getString(key);
    if (jsonStr == null) continue;
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (data['imagePath'] == file.path) {
        data['imagePath'] = '';
        await prefs.setString(key, jsonEncode(data));
        break;
      }
    } catch (_) {}
  }
  if (await file.exists()) {
    try {
      await file.delete();
    } catch (_) {}
  }
}

Widget _buildProofsByTaskSection() {
  return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
    future: _loadProofsGroupedByTask(),
    builder: (context, snapshot) {
      final grouped = snapshot.data ?? {};
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (grouped.isEmpty) {
        return const SizedBox.shrink();
      }
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📑 Görevlere Göre Kanıtlar',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...grouped.entries.map((entry) {
                final taskTitle = entry.key;
                final proofs = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        taskTitle,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      ...proofs.map((p) {
                        final imagePath = p['imagePath'] as String?;
                        final docPath = p['docPath'] as String?;
                        final note = p['note'] as String?;
                        final createdAt =
                            DateTime.tryParse(p['createdAt'] ?? '') ??
                                DateTime.now();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.orange.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.event_note, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${createdAt.day}.${createdAt.month}.${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              if (note != null && note.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(note,
                                    style: const TextStyle(fontSize: 13)),
                              ],
                              if (imagePath != null &&
                                  imagePath.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () =>
                                      _openFullscreen(context, File(imagePath)),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(imagePath),
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      filterQuality: FilterQuality.high,
                                    ),
                                  ),
                                ),
                              ],
                              if (docPath != null && docPath.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.description, size: 16),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        docPath.split('/').last,
                                        style: const TextStyle(fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}

Future<Map<String, List<Map<String, dynamic>>>>
    _loadProofsGroupedByTask() async {
  final prefs = await SharedPreferences.getInstance();
  final log = prefs.getStringList('proof_log') ?? [];
  final map = <String, List<Map<String, dynamic>>>{};
  for (final item in log) {
    try {
      final p = jsonDecode(item) as Map<String, dynamic>;
      final title = (p['taskTitle'] as String?)?.trim();
      if (title == null || title.isEmpty) continue;
      map.putIfAbsent(title, () => []).add(p);
    } catch (_) {}
  }
  return map;
}
