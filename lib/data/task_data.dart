import '../models/task.dart';

class TaskData {
  static List<Task> getAllTasks() {
    return [
      // 🧘 Kısa & Keyifli Görevler
      Task(
        id: '1',
        title: '1 dakika gözlerini kapatıp derin nefes al',
        description: 'Gözlerini kapat, derin nefes al ve rahatla',
        category: TaskCategory.shortAndFun,
        emoji: '🧘',
      ),
      Task(
        id: '2',
        title: 'Bugün 3 farklı kişiye gülümse',
        description: 'Gülümsemenin gücünü keşfet!',
        category: TaskCategory.shortAndFun,
        emoji: '😊',
      ),
      Task(
        id: '3',
        title: 'Bir bardak fazladan su iç',
        description: 'Vücudunu sev, su iç!',
        category: TaskCategory.shortAndFun,
        emoji: '💧',
      ),
      Task(
        id: '4',
        title: 'Kendi kendine yüksek sesle "Ben harikayım!" de',
        description: 'Kendine güven, sen gerçekten harikasın!',
        category: TaskCategory.shortAndFun,
        emoji: '✨',
      ),
      Task(
        id: '5',
        title: '10 tane minik esneme hareketi yap',
        description: 'Vücudunu esnet ve rahatla',
        category: TaskCategory.shortAndFun,
        emoji: '🤸',
      ),

      // 💃 Hareketli Görevler
      Task(
        id: '6',
        title: '5 dakika dans et',
        description: 'Müziği aç ve dans et!',
        category: TaskCategory.active,
        emoji: '💃',
      ),
      Task(
        id: '7',
        title: '10 squat yap (yapamazsan gülümse, yeter 😅)',
        description: 'Bacaklarını güçlendir veya sadece gülümse!',
        category: TaskCategory.active,
        emoji: '🏋️',
      ),
      Task(
        id: '8',
        title: 'Bugün yürürken 1 şarkı boyunca hızlı yürü',
        description: 'Tempolu yürüyüş yap!',
        category: TaskCategory.active,
        emoji: '🚶',
      ),
      Task(
        id: '9',
        title: '5 dakika odanda müzik açıp ritme uydur',
        description: 'Ritmi yakala ve hareket et!',
        category: TaskCategory.active,
        emoji: '🎵',
      ),
      Task(
        id: '10',
        title: '10 adım geriye doğru yürü (dikkatli ol)',
        description: 'Geriye doğru yürü, ama dikkatli ol!',
        category: TaskCategory.active,
        emoji: '👣',
      ),

      // 🎨 Yaratıcı & Eğlenceli Görevler
      Task(
        id: '11',
        title: 'Kâğıda komik bir doodle karala',
        description: 'Yaratıcılığını serbest bırak!',
        category: TaskCategory.creative,
        emoji: '✏️',
      ),
      Task(
        id: '12',
        title: 'Telefona komik bir selfie çek',
        description: 'Komik yüz yap ve fotoğraf çek!',
        category: TaskCategory.creative,
        emoji: '📸',
      ),
      Task(
        id: '13',
        title: 'İsmini tersten yazmayı dene',
        description: 'İsmini tersten yazmayı dene, eğlenceli olabilir!',
        category: TaskCategory.creative,
        emoji: '🔄',
      ),
      Task(
        id: '14',
        title: 'En sevdiğin hayvanı çiz',
        description: 'Hayal gücünü kullan ve çiz!',
        category: TaskCategory.creative,
        emoji: '🎨',
      ),
      Task(
        id: '15',
        title: '"Bugün harika olacak" yazısını renkli bir şekilde not al',
        description: 'Renkli kalemlerle güzel bir not yaz!',
        category: TaskCategory.creative,
        emoji: '🌈',
      ),

      // 🌟 Sosyal & İletişim Görevleri
      Task(
        id: '16',
        title: 'Bir arkadaşına beklenmedik bir "Selam!" mesajı at',
        description: 'Beklenmedik bir selam mesajı gönder!',
        category: TaskCategory.social,
        emoji: '👋',
      ),
      Task(
        id: '17',
        title: 'Sevdiğin birine güzel bir iltifat et',
        description: 'Güzel sözler söyle ve mutlu et!',
        category: TaskCategory.social,
        emoji: '💝',
      ),
      Task(
        id: '18',
        title: 'Ailenden birine sarıl (yakında değilse "sanal sarılma 🤗" gönder)',
        description: 'Sıcak bir sarılma veya sanal sarılma!',
        category: TaskCategory.social,
        emoji: '🤗',
      ),
      Task(
        id: '19',
        title: '1 kişiye teşekkür et',
        description: 'Teşekkür etmeyi unutma!',
        category: TaskCategory.social,
        emoji: '🙏',
      ),
      Task(
        id: '20',
        title: 'En son konuşmadığın birine kısa bir mesaj gönder',
        description: 'Uzun zamandır konuşmadığın birine mesaj at!',
        category: TaskCategory.social,
        emoji: '💬',
      ),

      // 😂 Eğlenceli Mini Meydan Okumalar
      Task(
        id: '21',
        title: '1 dakika boyunca saçma sapan sesler çıkar',
        description: 'Saçma sesler çıkar ve eğlen!',
        category: TaskCategory.challenge,
        emoji: '🎭',
      ),
      Task(
        id: '22',
        title: 'Bugün en az 5 kere kahkaha at (gerçek ya da sahte)',
        description: 'Kahkaha at, mutluluk bulaşıcıdır!',
        category: TaskCategory.challenge,
        emoji: '😂',
      ),
      Task(
        id: '23',
        title: 'Bir yiyeceği farklı şekilde ye (örneğin çatal yerine elle)',
        description: 'Farklı bir şekilde yemek ye!',
        category: TaskCategory.challenge,
        emoji: '🍽️',
      ),
      Task(
        id: '24',
        title: 'Bir şarkıyı yanlış sözlerle söyle',
        description: 'Şarkıyı yanlış sözlerle söyle, eğlenceli olacak!',
        category: TaskCategory.challenge,
        emoji: '🎤',
      ),
      Task(
        id: '25',
        title: 'Aynada komik yüz yap ve kendine bak',
        description: 'Aynada komik yüz yap ve kendine gül!',
        category: TaskCategory.challenge,
        emoji: '🤪',
      ),

      // 🌈 Keyif ve Motivasyon Görevleri
      Task(
        id: '26',
        title: 'Gün sonunda seni mutlu eden 3 şey yaz',
        description: 'Günün güzel yanlarını hatırla!',
        category: TaskCategory.motivation,
        emoji: '📝',
      ),
      Task(
        id: '27',
        title: 'Bugün 1 tane küçük iyilik yap',
        description: 'Küçük bir iyilik yap ve mutlu ol!',
        category: TaskCategory.motivation,
        emoji: '💖',
      ),
      Task(
        id: '28',
        title: 'En sevdiğin şarkıyı dinle',
        description: 'Favori şarkını aç ve keyfini çıkar!',
        category: TaskCategory.motivation,
        emoji: '🎶',
      ),
      Task(
        id: '29',
        title: 'Bir günlüğüne kendi süper kahraman adını uydur',
        description: 'Kendine süper kahraman adı ver!',
        category: TaskCategory.motivation,
        emoji: '🦸',
      ),
      Task(
        id: '30',
        title: '"Bugün benim şanslı günüm 🍀" diye kendine not düş',
        description: 'Kendine şanslı olduğunu hatırlat!',
        category: TaskCategory.motivation,
        emoji: '🍀',
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
}
