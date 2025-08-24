import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/task.dart';
import '../models/badge.dart' as app_badge;

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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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
                        color: profile.levelColor.withValues(alpha: 0.3),
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

          // İstatistikler
          _buildStatsSection(),

          const SizedBox(height: 24),

          // Rozetler
          _buildBadgesSection(),

          const SizedBox(height: 16),

          // Tüm Rozetler butonu
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BadgesPage(profile: profile),
                  ),
                );
              },
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
    );
  }

  Widget _buildStatsSection() {
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
              '📊 İstatistikler',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.task_alt,
                    title: 'Tamamlanan Görev',
                    value: '${profile.completedTasks}',
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.local_fire_department,
                    title: 'Seri Gün',
                    value: '${profile.streakDays}',
                    color: Colors.orange,
                  ),
                ),
              ],
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
              '🏆 Rozetler',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
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
    final allBadges = app_badge.BadgeData.getAllBadges();
    final userBadges = Set<String>.from(profile.badges);

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
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: userBadges.length / allBadges.length,
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
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getTypeColor(type),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${earnedBadges.length}/${typeBadges.length}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getTypeColor(type),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: typeBadges.isNotEmpty
                    ? earnedBadges.length / typeBadges.length
                    : 0,
                backgroundColor: _getTypeColor(type).withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(_getTypeColor(type)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Rozetler listesi
        ...sortedBadges.map((badge) => _buildBadgeCardWithProgress(
              context,
              badge,
              userBadges.contains(badge.id),
              type,
              typeBadges,
              userBadges,
            )),

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
                        isEarned ? Icons.check : Icons.lock,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Açıklama
                Text(
                  badge.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isEarned ? Colors.black87 : Colors.grey.shade600,
                  ),
                ),

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
                        Text(
                          '${nextTierInfo.requiredCount - nextTierInfo.currentCount} görev daha gerekli',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: nextTierInfo.currentCount /
                              nextTierInfo.requiredCount,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.trending_up, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Bir Üst Rozet: ${nextTierInfo.nextTier.displayName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'İlerleme: ${nextTierInfo.currentCount}/${nextTierInfo.requiredCount}',
                        style: const TextStyle(color: Colors.blue),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: nextTierInfo.currentCount /
                            nextTierInfo.requiredCount,
                        backgroundColor: Colors.blue.withValues(alpha: 0.2),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ],
                  ),
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
                    Text(
                      isEarned
                          ? 'Bu rozeti kazandın!'
                          : 'Bu rozeti henüz kazanamadın',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isEarned ? Colors.green : Colors.grey,
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
