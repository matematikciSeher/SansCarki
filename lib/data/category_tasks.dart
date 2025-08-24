import '../models/task.dart';
import '../models/category.dart';

class CategoryTasks {
  static List<Task> getTasksByCategory(String categoryId) {
    switch (categoryId) {
      case 'kitap':
        return [
          Task(
            id: 'kitap_1',
            title: 'Bugün 5 sayfa kitap oku.',
            description: 'Sevdiğin bir kitabı aç ve 5 sayfa oku.',
            category: TaskCategory.kitap,
            difficulty: TaskDifficulty.easy,
            basePoints: 8,
            emoji: '📚',
          ),
          Task(
            id: 'kitap_2',
            title: 'Okuduğun bir kitabın kahramanını resmini çiz.',
            description: 'Hayal gücünü kullanarak karakteri çiz.',
            category: TaskCategory.kitap,
            difficulty: TaskDifficulty.medium,
            basePoints: 18,
            emoji: '✏️',
          ),
        ];
      case 'yazma':
        return [
          Task(
            id: 'yazma_1',
            title: 'Bugünkü ruh halini 3 kelimeyle yaz.',
            description: 'Kendini ifade et!',
            category: TaskCategory.yazma,
            difficulty: TaskDifficulty.easy,
            basePoints: 7,
            emoji: '✍️',
          ),
        ];
      case 'matematik':
        return [
          Task(
            id: 'matematik_1',
            title: '10 tane toplama işlemi yap.',
            description: 'Küçük toplama işlemleriyle pratik yap.',
            category: TaskCategory.matematik,
            difficulty: TaskDifficulty.easy,
            basePoints: 8,
            emoji: '➕',
          ),
        ];
      case 'fen':
        return [
          Task(
            id: 'fen_1',
            title: 'Bugün gökyüzünü gözlemle, hava durumunu yaz.',
            description: 'Hava nasıl? Gözlemle ve yaz!',
            category: TaskCategory.fen,
            difficulty: TaskDifficulty.easy,
            basePoints: 7,
            emoji: '🌤️',
          ),
        ];
      case 'spor':
        return [
          Task(
            id: 'spor_1',
            title: '10 mekik çek.',
            description: 'Karın kaslarını çalıştır!',
            category: TaskCategory.spor,
            difficulty: TaskDifficulty.medium,
            basePoints: 18,
            emoji: '💪',
          ),
        ];
      case 'sanat':
        return [
          Task(
            id: 'sanat_1',
            title: 'En sevdiğin hayvanı çiz.',
            description: 'Hayal gücünü kullan!',
            category: TaskCategory.sanat,
            difficulty: TaskDifficulty.medium,
            basePoints: 18,
            emoji: '🐾',
          ),
        ];
      case 'muzik':
        return [
          Task(
            id: 'muzik_1',
            title: 'En sevdiğin şarkıyı söyle.',
            description: 'Şarkı söylemek ruhuna iyi gelir!',
            category: TaskCategory.muzik,
            difficulty: TaskDifficulty.easy,
            basePoints: 8,
            emoji: '🎤',
          ),
        ];
      case 'teknoloji':
        return [
          Task(
            id: 'teknoloji_1',
            title: 'Klavyeden 5 kısa cümle yaz.',
            description: 'Klavye ile yazı yazma pratiği yap!',
            category: TaskCategory.teknoloji,
            difficulty: TaskDifficulty.easy,
            basePoints: 8,
            emoji: '⌨️',
          ),
        ];
      case 'iyilik':
        return [
          Task(
            id: 'iyilik_1',
            title: 'Ailene teşekkür et.',
            description: 'Teşekkür etmek güzeldir!',
            category: TaskCategory.iyilik,
            difficulty: TaskDifficulty.easy,
            basePoints: 7,
            emoji: '🙏',
          ),
        ];
      case 'ev':
        return [
          Task(
            id: 'ev_1',
            title: 'Odandaki kitapları düzenle.',
            description: 'Düzenli bir oda, düzenli bir zihin!',
            category: TaskCategory.ev,
            difficulty: TaskDifficulty.easy,
            basePoints: 8,
            emoji: '🧹',
          ),
        ];
      case 'oyun':
        return [
          Task(
            id: 'oyun_1',
            title: 'Sessiz sinema oyna.',
            description: 'Ailenle veya arkadaşlarınla eğlen!',
            category: TaskCategory.oyun,
            difficulty: TaskDifficulty.medium,
            basePoints: 18,
            emoji: '🎬',
          ),
        ];
      case 'zihin':
        return [
          Task(
            id: 'zihin_1',
            title: '1 dakika boyunca gözlerini kapat.',
            description: 'Zihnini dinlendir!',
            category: TaskCategory.zihin,
            difficulty: TaskDifficulty.easy,
            basePoints: 6,
            emoji: '🧘',
          ),
        ];
      default:
        return [];
    }
  }
}
