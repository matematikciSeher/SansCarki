import 'package:flutter/material.dart';
import '../models/task.dart';

enum BadgeType { zorluk, kategori, streak, cesitlilik, ozel }

enum BadgeTier { bronz, gumus, altin, elmas }

class Badge {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final Color color;
  final BadgeType type;
  final bool isSecret;
  final String? categoryId; // kategoriye özelse
  final int? requiredCount; // görev/gün sayısı
  final BadgeTier? tier; // zorluk rozetleri için seviye
  final TaskDifficulty? requiredDifficulty; // zorluk rozetleri için

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.color,
    required this.type,
    this.isSecret = false,
    this.categoryId,
    this.requiredCount,
    this.tier,
    this.requiredDifficulty,
  });
}

extension BadgeTierExtension on BadgeTier {
  String get emoji {
    switch (this) {
      case BadgeTier.bronz:
        return '🥉';
      case BadgeTier.gumus:
        return '🥈';
      case BadgeTier.altin:
        return '🥇';
      case BadgeTier.elmas:
        return '💎';
    }
  }

  String get displayName {
    switch (this) {
      case BadgeTier.bronz:
        return 'Bronz';
      case BadgeTier.gumus:
        return 'Gümüş';
      case BadgeTier.altin:
        return 'Altın';
      case BadgeTier.elmas:
        return 'Elmas';
    }
  }

  Color get color {
    switch (this) {
      case BadgeTier.bronz:
        return const Color(0xFFCD7F32);
      case BadgeTier.gumus:
        return const Color(0xFFC0C0C0);
      case BadgeTier.altin:
        return const Color(0xFFFFD700);
      case BadgeTier.elmas:
        return const Color(0xFFB9F2FF);
    }
  }

  int get upgradeRequirement {
    switch (this) {
      case BadgeTier.bronz:
        return 3; // 3 bronz = 1 gümüş
      case BadgeTier.gumus:
        return 3; // 3 gümüş = 1 altın
      case BadgeTier.altin:
        return 2; // 2 altın = 1 elmas
      case BadgeTier.elmas:
        return 2; // 2 elmas = 1 ustalık
    }
  }
}

class BadgeData {
  static List<Badge> getAllBadges() {
    return [
      // ⭐ Zorluk Tabanlı Rozetler
      Badge(
        id: 'bronz_zorluk',
        name: 'Bronz Görevci',
        description: '10 kolay görev tamamla.',
        emoji: '🥉',
        color: Colors.brown,
        type: BadgeType.zorluk,
        tier: BadgeTier.bronz,
        requiredCount: 10,
        requiredDifficulty: TaskDifficulty.easy,
      ),
      Badge(
        id: 'gumus_zorluk',
        name: 'Gümüş Görevci',
        description: '20 orta zorlukta görev tamamla.',
        emoji: '🥈',
        color: Colors.grey,
        type: BadgeType.zorluk,
        tier: BadgeTier.gumus,
        requiredCount: 20,
        requiredDifficulty: TaskDifficulty.medium,
      ),
      Badge(
        id: 'altin_zorluk',
        name: 'Altın Görevci',
        description: '30 zor görev tamamla.',
        emoji: '🥇',
        color: Colors.amber,
        type: BadgeType.zorluk,
        tier: BadgeTier.altin,
        requiredCount: 30,
        requiredDifficulty: TaskDifficulty.hard,
      ),
      Badge(
        id: 'elmas_zorluk',
        name: 'Elmas Görevci',
        description: 'Tüm zorluklardan toplam 100 görev tamamla.',
        emoji: '💎',
        color: Colors.blueAccent,
        type: BadgeType.zorluk,
        tier: BadgeTier.elmas,
        requiredCount: 100,
      ),
      // 🏆 Kategoriye Özel Rozetler (12 kategori)
      Badge(
        id: 'kitap_kurdu',
        name: 'Kitap Kurdu',
        description: 'Kitap kategorisinde 10 görev tamamla.',
        emoji: '📚',
        color: Colors.purple,
        type: BadgeType.kategori,
        categoryId: 'kitap',
        requiredCount: 10,
      ),
      Badge(
        id: 'yazma_usta',
        name: 'Yazı Ustası',
        description: 'Yazma kategorisinde 10 görev tamamla.',
        emoji: '✍️',
        color: Colors.teal,
        type: BadgeType.kategori,
        categoryId: 'yazma',
        requiredCount: 10,
      ),
      Badge(
        id: 'matematik_dahisi',
        name: 'Matematik Dahisi',
        description: 'Matematik kategorisinde 10 görev tamamla.',
        emoji: '🔢',
        color: Colors.yellow,
        type: BadgeType.kategori,
        categoryId: 'matematik',
        requiredCount: 10,
      ),
      Badge(
        id: 'fen_kaşifi',
        name: 'Fen Kaşifi',
        description: 'Fen kategorisinde 10 görev tamamla.',
        emoji: '🌍',
        color: Colors.lightBlue,
        type: BadgeType.kategori,
        categoryId: 'fen',
        requiredCount: 10,
      ),
      Badge(
        id: 'sporcu',
        name: 'Sporcu',
        description: 'Spor kategorisinde 10 görev tamamla.',
        emoji: '🏃‍♀️',
        color: Colors.orange,
        type: BadgeType.kategori,
        categoryId: 'spor',
        requiredCount: 10,
      ),
      Badge(
        id: 'sanatci',
        name: 'Sanatçı',
        description: 'Sanat kategorisinde 10 görev tamamla.',
        emoji: '🎨',
        color: Colors.deepPurple,
        type: BadgeType.kategori,
        categoryId: 'sanat',
        requiredCount: 10,
      ),
      Badge(
        id: 'muzik_usta',
        name: 'Müzik Ustası',
        description: 'Müzik kategorisinde 10 görev tamamla.',
        emoji: '🎵',
        color: Colors.indigo,
        type: BadgeType.kategori,
        categoryId: 'muzik',
        requiredCount: 10,
      ),
      Badge(
        id: 'teknoloji_usta',
        name: 'Teknoloji Ustası',
        description: 'Teknoloji kategorisinde 10 görev tamamla.',
        emoji: '💻',
        color: Colors.cyan,
        type: BadgeType.kategori,
        categoryId: 'teknoloji',
        requiredCount: 10,
      ),
      Badge(
        id: 'iyilik_melegi',
        name: 'İyilik Meleği',
        description: 'İyilik kategorisinde 10 görev tamamla.',
        emoji: '❤️',
        color: Colors.red,
        type: BadgeType.kategori,
        categoryId: 'iyilik',
        requiredCount: 10,
      ),
      Badge(
        id: 'ev_ustasi',
        name: 'Ev Ustası',
        description: 'Ev kategorisinde 10 görev tamamla.',
        emoji: '🏡',
        color: Colors.brown,
        type: BadgeType.kategori,
        categoryId: 'ev',
        requiredCount: 10,
      ),
      Badge(
        id: 'oyun_ustasi',
        name: 'Oyun Ustası',
        description: 'Oyun kategorisinde 10 görev tamamla.',
        emoji: '🎲',
        color: Colors.deepOrange,
        type: BadgeType.kategori,
        categoryId: 'oyun',
        requiredCount: 10,
      ),
      Badge(
        id: 'zihin_ustasi',
        name: 'Zihin Ustası',
        description: 'Zihin kategorisinde 10 görev tamamla.',
        emoji: '🧘',
        color: Colors.green,
        type: BadgeType.kategori,
        categoryId: 'zihin',
        requiredCount: 10,
      ),
      // ⏳ Süreklilik Rozetleri
      Badge(
        id: 'haftalik_kahraman',
        name: 'Haftalık Kahraman',
        description: '7 gün üst üste görev tamamla.',
        emoji: '🔥',
        color: Colors.red,
        type: BadgeType.streak,
        requiredCount: 7,
      ),
      Badge(
        id: 'gorev_ustasi',
        name: 'Görev Ustası',
        description: '30 gün üst üste görev tamamla.',
        emoji: '🏅',
        color: Colors.amber,
        type: BadgeType.streak,
        requiredCount: 30,
      ),
      Badge(
        id: 'efsane_gorevci',
        name: 'Efsane Görevci',
        description: '100 gün üst üste görev tamamla.',
        emoji: '👑',
        color: Colors.purple,
        type: BadgeType.streak,
        requiredCount: 100,
      ),
      // 🎲 Çeşitlilik Rozetleri
      Badge(
        id: 'renkli_kisilik',
        name: 'Renkli Kişilik',
        description: '12 kategoriden en az 1 görev yap.',
        emoji: '🌈',
        color: Colors.deepOrange,
        type: BadgeType.cesitlilik,
        requiredCount: 12,
      ),
      Badge(
        id: 'cok_yonlu',
        name: 'Çok Yönlü',
        description: '6 farklı kategoriden toplam 60 görev yap.',
        emoji: '🦸',
        color: Colors.blue,
        type: BadgeType.cesitlilik,
        requiredCount: 60,
      ),
      Badge(
        id: 'super_kahraman',
        name: 'Süper Kahraman',
        description: 'Tüm kategorilerden görev tamamla.',
        emoji: '🦸‍♂️',
        color: Colors.teal,
        type: BadgeType.cesitlilik,
        requiredCount: 12,
      ),
      // 🎯 Gizli/Özel Rozetler
      Badge(
        id: 'ilk_gorev',
        name: 'İlk Görevini Bitirdin',
        description: 'İlk görevini başarıyla tamamladın!',
        emoji: '🎉',
        color: Colors.blue,
        type: BadgeType.ozel,
        isSecret: true,
      ),
      Badge(
        id: 'gece_yarisi',
        name: 'Gece Yarısı Görevci',
        description: 'Gece 12’den sonra görev tamamla.',
        emoji: '🌙',
        color: Colors.indigo,
        type: BadgeType.ozel,
        isSecret: true,
      ),
      Badge(
        id: 'super_hizli',
        name: 'Süper Hızlı',
        description: 'Bir görevi 5 dakika içinde tamamla.',
        emoji: '⚡',
        color: Colors.yellow,
        type: BadgeType.ozel,
        isSecret: true,
      ),
      Badge(
        id: 'paylasimci',
        name: 'Paylaşımcı',
        description: 'Arkadaşına davet linki gönder.',
        emoji: '🤝',
        color: Colors.green,
        type: BadgeType.ozel,
        isSecret: true,
      ),
    ];
  }

  static List<Badge> getBadgesByCategory(String? categoryId) {
    if (categoryId == null) {
      return getAllBadges().where((badge) => badge.categoryId == null).toList();
    }
    return getAllBadges()
        .where((badge) => badge.categoryId == categoryId)
        .toList();
  }

  static List<Badge> getBadgesByTier(BadgeTier tier) {
    return getAllBadges().where((badge) => badge.tier == tier).toList();
  }
}
