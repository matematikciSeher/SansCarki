import '../models/task.dart';

class TaskData {
  static List<Task> getAllTasks() {
    return [
      // 📚 Kitap & Okuma Görevleri
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
      Task(
        id: 'kitap_3',
        title: 'Kitap okurken geçen bir kelimenin anlamını araştır.',
        description: 'Yeni bir kelime öğren!',
        category: TaskCategory.kitap,
        difficulty: TaskDifficulty.easy,
        basePoints: 10,
        emoji: '🔍',
      ),
      // ✍️ Yazma & Günlük Görevleri
      Task(
        id: 'yazma_1',
        title: 'Bugünkü ruh halini 3 kelimeyle yaz.',
        description: 'Kendini ifade et!',
        category: TaskCategory.yazma,
        difficulty: TaskDifficulty.easy,
        basePoints: 7,
        emoji: '✍️',
      ),
      Task(
        id: 'yazma_2',
        title: 'Kendine bir teşekkür mektubu yaz.',
        description: 'Kendini takdir et!',
        category: TaskCategory.yazma,
        difficulty: TaskDifficulty.medium,
        basePoints: 16,
        emoji: '💌',
      ),
      Task(
        id: 'yazma_3',
        title: 'Gelecekteki haline bir mesaj bırak.',
        description: 'Hayallerini yaz!',
        category: TaskCategory.yazma,
        difficulty: TaskDifficulty.medium,
        basePoints: 15,
        emoji: '🕰️',
      ),
      // 🔢 Matematik Görevleri
      Task(
        id: 'matematik_1',
        title: '10 tane toplama işlemi yap.',
        description: 'Küçük toplama işlemleriyle pratik yap.',
        category: TaskCategory.matematik,
        difficulty: TaskDifficulty.easy,
        basePoints: 8,
        emoji: '➕',
      ),
      Task(
        id: 'matematik_2',
        title: '5 tane çarpma sorusu çöz.',
        description: 'Çarpım tablosunu tekrar et!',
        category: TaskCategory.matematik,
        difficulty: TaskDifficulty.easy,
        basePoints: 10,
        emoji: '✖️',
      ),
      Task(
        id: 'matematik_3',
        title: 'Günlük alışverişte harcadığını hesapla.',
        description: 'Paranı yönetmeyi öğren!',
        category: TaskCategory.matematik,
        difficulty: TaskDifficulty.medium,
        basePoints: 18,
        emoji: '💸',
      ),
      // 🌍 Fen Bilimleri Görevleri
      Task(
        id: 'fen_1',
        title: 'Bugün gökyüzünü gözlemle, hava durumunu yaz.',
        description: 'Hava nasıl? Gözlemle ve yaz!',
        category: TaskCategory.fen,
        difficulty: TaskDifficulty.easy,
        basePoints: 7,
        emoji: '🌤️',
      ),
      Task(
        id: 'fen_2',
        title: 'Bir bitkiyi incele ve özelliklerini yaz.',
        description: 'Doğayı keşfet!',
        category: TaskCategory.fen,
        difficulty: TaskDifficulty.medium,
        basePoints: 15,
        emoji: '🌱',
      ),
      Task(
        id: 'fen_3',
        title: 'Bir mıknatısla deney yap.',
        description: 'Bilimsel bir deney yap!',
        category: TaskCategory.fen,
        difficulty: TaskDifficulty.medium,
        basePoints: 20,
        emoji: '🧲',
      ),
      // 🏃‍♀️ Spor & Hareket Görevleri
      Task(
        id: 'spor_1',
        title: '10 mekik çek.',
        description: 'Karın kaslarını çalıştır!',
        category: TaskCategory.spor,
        difficulty: TaskDifficulty.medium,
        basePoints: 18,
        emoji: '💪',
      ),
      Task(
        id: 'spor_2',
        title: '15 kez ip atla.',
        description: 'Kondisyonunu artır!',
        category: TaskCategory.spor,
        difficulty: TaskDifficulty.medium,
        basePoints: 20,
        emoji: '🤸',
      ),
      Task(
        id: 'spor_3',
        title: '5 dakika yürüyüş yap.',
        description: 'Açık havada veya evde yürü!',
        category: TaskCategory.spor,
        difficulty: TaskDifficulty.easy,
        basePoints: 10,
        emoji: '🚶‍♂️',
      ),
      // 🎨 Sanat & Yaratıcılık Görevleri
      Task(
        id: 'sanat_1',
        title: 'En sevdiğin hayvanı çiz.',
        description: 'Hayal gücünü kullan!',
        category: TaskCategory.sanat,
        difficulty: TaskDifficulty.medium,
        basePoints: 18,
        emoji: '🐾',
      ),
      Task(
        id: 'sanat_2',
        title: 'Bir mandala boyala.',
        description: 'Renklerle rahatla!',
        category: TaskCategory.sanat,
        difficulty: TaskDifficulty.easy,
        basePoints: 10,
        emoji: '🎨',
      ),
      Task(
        id: 'sanat_3',
        title: 'Kendi karakterini tasarla.',
        description: 'Yaratıcı ol!',
        category: TaskCategory.sanat,
        difficulty: TaskDifficulty.medium,
        basePoints: 20,
        emoji: '👾',
      ),
      // 🎵 Müzik Görevleri
      Task(
        id: 'muzik_1',
        title: 'En sevdiğin şarkıyı söyle.',
        description: 'Şarkı söylemek ruhuna iyi gelir!',
        category: TaskCategory.muzik,
        difficulty: TaskDifficulty.easy,
        basePoints: 8,
        emoji: '🎤',
      ),
      Task(
        id: 'muzik_2',
        title: '2 dakika ritim tut.',
        description: 'Ritmi yakala!',
        category: TaskCategory.muzik,
        difficulty: TaskDifficulty.easy,
        basePoints: 7,
        emoji: '🥁',
      ),
      Task(
        id: 'muzik_3',
        title: 'Evin içinde müzikle dans et.',
        description: 'Müziği aç ve dans et!',
        category: TaskCategory.muzik,
        difficulty: TaskDifficulty.medium,
        basePoints: 15,
        emoji: '💃',
      ),
      // 💻 Teknoloji Görevleri
      Task(
        id: 'teknoloji_1',
        title: 'Klavyeden 5 kısa cümle yaz.',
        description: 'Klavye ile yazı yazma pratiği yap!',
        category: TaskCategory.teknoloji,
        difficulty: TaskDifficulty.easy,
        basePoints: 8,
        emoji: '⌨️',
      ),
      Task(
        id: 'teknoloji_2',
        title: 'Bilgisayarda yeni bir klasör aç.',
        description: 'Dosya yönetimini öğren!',
        category: TaskCategory.teknoloji,
        difficulty: TaskDifficulty.easy,
        basePoints: 7,
        emoji: '💻',
      ),
      Task(
        id: 'teknoloji_3',
        title: 'Paint ile resim yap.',
        description: 'Dijital ortamda çizim yap!',
        category: TaskCategory.teknoloji,
        difficulty: TaskDifficulty.medium,
        basePoints: 15,
        emoji: '🖌️',
      ),
      // ❤️ İyilik & Sosyal Sorumluluk Görevleri
      Task(
        id: 'iyilik_1',
        title: 'Ailene teşekkür et.',
        description: 'Teşekkür etmek güzeldir!',
        category: TaskCategory.iyilik,
        difficulty: TaskDifficulty.easy,
        basePoints: 7,
        emoji: '🙏',
      ),
      Task(
        id: 'iyilik_2',
        title: 'Birine yardım et.',
        description: 'Yardım etmek insanı mutlu eder!',
        category: TaskCategory.iyilik,
        difficulty: TaskDifficulty.medium,
        basePoints: 15,
        emoji: '🤝',
      ),
      Task(
        id: 'iyilik_3',
        title: 'Çöpleri topla.',
        description: 'Çevreni temiz tut!',
        category: TaskCategory.iyilik,
        difficulty: TaskDifficulty.medium,
        basePoints: 18,
        emoji: '🗑️',
      ),
      // 🏡 Ev & Günlük Yaşam Görevleri
      Task(
        id: 'ev_1',
        title: 'Odandaki kitapları düzenle.',
        description: 'Düzenli bir oda, düzenli bir zihin!',
        category: TaskCategory.ev,
        difficulty: TaskDifficulty.easy,
        basePoints: 8,
        emoji: '🧹',
      ),
      Task(
        id: 'ev_2',
        title: 'Masanı temizle.',
        description: 'Çalışma alanını temizle!',
        category: TaskCategory.ev,
        difficulty: TaskDifficulty.easy,
        basePoints: 7,
        emoji: '🧽',
      ),
      Task(
        id: 'ev_3',
        title: 'Çamaşırları ayırmaya yardım et.',
        description: 'Ev işlerine katkı sağla!',
        category: TaskCategory.ev,
        difficulty: TaskDifficulty.medium,
        basePoints: 15,
        emoji: '🧺',
      ),
      // 🎲 Eğlenceli Oyun Görevleri
      Task(
        id: 'oyun_1',
        title: 'Sessiz sinema oyna.',
        description: 'Ailenle veya arkadaşlarınla eğlen!',
        category: TaskCategory.oyun,
        difficulty: TaskDifficulty.medium,
        basePoints: 18,
        emoji: '🎬',
      ),
      Task(
        id: 'oyun_2',
        title: 'Saklambaç oyna.',
        description: 'Klasik oyunlarla eğlen!',
        category: TaskCategory.oyun,
        difficulty: TaskDifficulty.easy,
        basePoints: 8,
        emoji: '🙈',
      ),
      Task(
        id: 'oyun_3',
        title: 'Taş–kağıt–makas oyna.',
        description: 'Hızlı reflekslerini test et!',
        category: TaskCategory.oyun,
        difficulty: TaskDifficulty.easy,
        basePoints: 7,
        emoji: '✊',
      ),
      // 🧘 Düşünme & Zihin Egzersizi Görevleri
      Task(
        id: 'zihin_1',
        title: '1 dakika boyunca gözlerini kapat.',
        description: 'Zihnini dinlendir!',
        category: TaskCategory.zihin,
        difficulty: TaskDifficulty.easy,
        basePoints: 6,
        emoji: '🧘',
      ),
      Task(
        id: 'zihin_2',
        title: '10 derin nefes al.',
        description: 'Nefes egzersizi yap!',
        category: TaskCategory.zihin,
        difficulty: TaskDifficulty.easy,
        basePoints: 7,
        emoji: '💨',
      ),
      Task(
        id: 'zihin_3',
        title: 'Bugün 1 dileğini yaz.',
        description: 'Dileklerini yazmak iyi gelir!',
        category: TaskCategory.zihin,
        difficulty: TaskDifficulty.medium,
        basePoints: 15,
        emoji: '📝',
      ),
    ];
  }

  static Task getRandomTask() {
    final tasks = getAllTasks();
    final random = DateTime.now().millisecondsSinceEpoch % tasks.length;
    return tasks[random];
  }

  static List<Task> getTasksByCategory(TaskCategory category) {
    return getAllTasks().where((task) => task.category == category).toList();
  }

  static List<Task> getTasksByDifficulty(TaskDifficulty difficulty) {
    return getAllTasks()
        .where((task) => task.difficulty == difficulty)
        .toList();
  }

  static List<Task> getExpertTasks() {
    return getAllTasks()
        .where((task) => task.difficulty == TaskDifficulty.expert)
        .toList();
  }
}
