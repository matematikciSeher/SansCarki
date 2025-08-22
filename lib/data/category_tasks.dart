import '../models/task.dart';
import '../models/category.dart';

class CategoryTasks {
  static List<Task> getTasksByCategory(String categoryId) {
    switch (categoryId) {
      case 'beden_egitimi':
        return _getBedenEgitimiTasks();
      case 'muzik':
        return _getMuzikTasks();
      case 'eglence':
        return _getEglenceTasks();
      case 'yaraticilik':
        return _getYaraticilikTasks();
      case 'sosyal':
        return _getSosyalTasks();
      case 'bilim':
        return _getBilimTasks();
      default:
        return [];
    }
  }

  static List<Task> _getBedenEgitimiTasks() {
    return [
      Task(
        id: 'be_1',
        title: '7 tane mekik çek',
        description: 'Karnını güçlendir ve 7 mekik yap!',
        category: TaskCategory.active,
        emoji: '💪',
      ),
      Task(
        id: 'be_2',
        title: '10 şınav çek',
        description: 'Kollarını güçlendir ve 10 şınav yap!',
        category: TaskCategory.active,
        emoji: '🏋️',
      ),
      Task(
        id: 'be_3',
        title: '20 squat yap',
        description: 'Bacaklarını güçlendir ve 20 squat yap!',
        category: TaskCategory.active,
        emoji: '🦵',
      ),
      Task(
        id: 'be_4',
        title: '45 saniye tek ayakta dur',
        description: 'Dengeni test et ve tek ayakta dur!',
        category: TaskCategory.active,
        emoji: '🦶',
      ),
      Task(
        id: 'be_5',
        title: '45 saniye yerinde koş',
        description: 'Kalp atışını hızlandır ve yerinde koş!',
        category: TaskCategory.active,
        emoji: '🏃‍♂️',
      ),
      Task(
        id: 'be_6',
        title: '40 saniye plank yap',
        description: 'Karın kaslarını sık ve plank pozisyonunda dur!',
        category: TaskCategory.active,
        emoji: '🧘',
      ),
      Task(
        id: 'be_7',
        title: '15 jumping jack yap',
        description: 'Zıplayarak 15 jumping jack yap!',
        category: TaskCategory.active,
        emoji: '🦘',
      ),
      Task(
        id: 'be_8',
        title: '30 saniye burpee yap',
        description: 'Tam vücut egzersizi için burpee yap!',
        category: TaskCategory.active,
        emoji: '🔄',
      ),
      Task(
        id: 'be_9',
        title: 'En sevdiğin sporu yap',
        description: 'Sevdiğin spor aktivitesini yap!',
        category: TaskCategory.active,
        emoji: '⚽',
      ),
      Task(
        id: 'be_10',
        title: '10 kere alkışla',
        description: 'Ellerini çırparak 10 kere alkışla!',
        category: TaskCategory.active,
        emoji: '👏',
      ),
    ];
  }

  static List<Task> _getMuzikTasks() {
    return [
      Task(
        id: 'm_1',
        title: '5 çalgı ismi say',
        description: 'Bildiğin 5 farklı çalgı ismini söyle!',
        category: TaskCategory.creative,
        emoji: '🎸',
      ),
      Task(
        id: 'm_2',
        title: 'Robot dansı yap',
        description: 'Robot gibi hareket ederek dans et!',
        category: TaskCategory.creative,
        emoji: '🤖',
      ),
      Task(
        id: 'm_3',
        title: '3 çocuk şarkısı ismi söyle',
        description: 'Bildiğin 3 çocuk şarkısının adını söyle!',
        category: TaskCategory.creative,
        emoji: '🎵',
      ),
      Task(
        id: 'm_4',
        title: 'Çığlık at!',
        description: 'Yüksek sesle çığlık at!',
        category: TaskCategory.challenge,
        emoji: '😱',
      ),
      Task(
        id: 'm_5',
        title: 'Islık çal',
        description: 'En güzel ıslığını çal!',
        category: TaskCategory.creative,
        emoji: '🎶',
      ),
      Task(
        id: 'm_6',
        title: 'Bir ritim oluştur',
        description: 'Ellerini kullanarak bir ritim oluştur!',
        category: TaskCategory.creative,
        emoji: '🥁',
      ),
      Task(
        id: 'm_7',
        title: 'Bir şarkı söyle',
        description: 'En sevdiğin şarkıyı söyle!',
        category: TaskCategory.creative,
        emoji: '🎤',
      ),
      Task(
        id: 'm_8',
        title: 'Ailende birini taklit ederek şarkı söyle',
        description: 'Ailenden birini taklit ederek şarkı söyle!',
        category: TaskCategory.creative,
        emoji: '👨‍👩‍👧‍👦',
      ),
      Task(
        id: 'm_9',
        title: '10 saniye boyunca gülümse :)',
        description: '10 saniye boyunca gülümse!',
        category: TaskCategory.motivation,
        emoji: '😊',
      ),
      Task(
        id: 'm_10',
        title: 'Bonus: Dersten 1 dakika erken çık',
        description: 'Özel bonus: Dersten 1 dakika erken çık!',
        category: TaskCategory.motivation,
        emoji: '🎁',
      ),
    ];
  }

  static List<Task> _getEglenceTasks() {
    return [
      Task(
        id: 'e_1',
        title: 'Horoz taklidi yap 😊',
        description: 'Horoz gibi ses çıkar ve taklit yap!',
        category: TaskCategory.challenge,
        emoji: '🐓',
      ),
      Task(
        id: 'e_2',
        title: 'Tek ayağının üzerinde 3 kere zıpla',
        description: 'Tek ayakla 3 kere zıpla!',
        category: TaskCategory.challenge,
        emoji: '🦘',
      ),
      Task(
        id: 'e_3',
        title: '3 renkli şey söyle',
        description: '3 farklı renkteki şeyi söyle!',
        category: TaskCategory.creative,
        emoji: '🌈',
      ),
      Task(
        id: 'e_4',
        title: '2 tane iyilik davranışı söyle',
        description: '2 farklı iyilik davranışı söyle!',
        category: TaskCategory.motivation,
        emoji: '💖',
      ),
      Task(
        id: 'e_5',
        title: 'Dört ayaklı varlıkların yiyecekleri nedir?',
        description: 'Dört ayaklı hayvanların ne yediğini söyle!',
        category: TaskCategory.creative,
        emoji: '🐕',
      ),
      Task(
        id: 'e_6',
        title: 'Sinirli kuş taklidi yap',
        description: 'Sinirli bir kuş gibi taklit yap!',
        category: TaskCategory.challenge,
        emoji: '😠',
      ),
      Task(
        id: 'e_7',
        title: '3 meyve söyle',
        description: '3 farklı meyve ismi söyle!',
        category: TaskCategory.creative,
        emoji: '🍎',
      ),
      Task(
        id: 'e_8',
        title: 'Mutlu Penguen taklidi yap',
        description: 'Mutlu bir penguen gibi taklit yap!',
        category: TaskCategory.challenge,
        emoji: '🐧',
      ),
      Task(
        id: 'e_9',
        title: 'Kediler ne yemek yer?',
        description: 'Kedilerin ne yediğini söyle!',
        category: TaskCategory.creative,
        emoji: '🐱',
      ),
      Task(
        id: 'e_10',
        title: '1 dakika boyunca saçma sesler çıkar',
        description: '1 dakika boyunca saçma sesler çıkar!',
        category: TaskCategory.challenge,
        emoji: '🎭',
      ),
    ];
  }

  static List<Task> _getYaraticilikTasks() {
    return [
      Task(
        id: 'y_1',
        title: 'Kâğıda komik bir doodle karala',
        description: 'Yaratıcılığını serbest bırak ve doodle yap!',
        category: TaskCategory.creative,
        emoji: '✏️',
      ),
      Task(
        id: 'y_2',
        title: 'Telefona komik bir selfie çek',
        description: 'Komik yüz yap ve selfie çek!',
        category: TaskCategory.creative,
        emoji: '📸',
      ),
      Task(
        id: 'y_3',
        title: 'İsmini tersten yazmayı dene',
        description: 'İsmini tersten yazmayı dene!',
        category: TaskCategory.creative,
        emoji: '🔄',
      ),
      Task(
        id: 'y_4',
        title: 'En sevdiğin hayvanı çiz',
        description: 'En sevdiğin hayvanı çiz!',
        category: TaskCategory.creative,
        emoji: '🎨',
      ),
      Task(
        id: 'y_5',
        title: 'Bugün harika olacak yazısını renkli yaz',
        description: 'Renkli kalemlerle güzel bir not yaz!',
        category: TaskCategory.creative,
        emoji: '🌈',
      ),
      Task(
        id: 'y_6',
        title: 'Bir şiir yaz',
        description: 'Kısa bir şiir yaz!',
        category: TaskCategory.creative,
        emoji: '📝',
      ),
      Task(
        id: 'y_7',
        title: 'Origami yap',
        description: 'Kâğıttan bir origami yap!',
        category: TaskCategory.creative,
        emoji: '🦋',
      ),
      Task(
        id: 'y_8',
        title: 'Bir hikaye uydur',
        description: 'Kısa bir hikaye uydur!',
        category: TaskCategory.creative,
        emoji: '📚',
      ),
      Task(
        id: 'y_9',
        title: 'Bir resim yap',
        description: 'Hayalindeki resmi çiz!',
        category: TaskCategory.creative,
        emoji: '🖼️',
      ),
      Task(
        id: 'y_10',
        title: 'Bir şarkı beste yap',
        description: 'Kendi şarkını beste yap!',
        category: TaskCategory.creative,
        emoji: '🎼',
      ),
    ];
  }

  static List<Task> _getSosyalTasks() {
    return [
      Task(
        id: 's_1',
        title: 'Bir arkadaşına beklenmedik selam mesajı at',
        description: 'Beklenmedik bir selam mesajı gönder!',
        category: TaskCategory.social,
        emoji: '👋',
      ),
      Task(
        id: 's_2',
        title: 'Sevdiğin birine güzel bir iltifat et',
        description: 'Güzel sözler söyle ve mutlu et!',
        category: TaskCategory.social,
        emoji: '💝',
      ),
      Task(
        id: 's_3',
        title: 'Ailenden birine sarıl',
        description: 'Sıcak bir sarılma ver!',
        category: TaskCategory.social,
        emoji: '🤗',
      ),
      Task(
        id: 's_4',
        title: '1 kişiye teşekkür et',
        description: 'Teşekkür etmeyi unutma!',
        category: TaskCategory.social,
        emoji: '🙏',
      ),
      Task(
        id: 's_5',
        title: 'En son konuşmadığın birine mesaj at',
        description: 'Uzun zamandır konuşmadığın birine mesaj at!',
        category: TaskCategory.social,
        emoji: '💬',
      ),
      Task(
        id: 's_6',
        title: 'Birine yardım et',
        description: 'Bugün birine yardım et!',
        category: TaskCategory.social,
        emoji: '🤝',
      ),
      Task(
        id: 's_7',
        title: 'Birine gülümse',
        description: 'Birine gülümse ve mutlu et!',
        category: TaskCategory.social,
        emoji: '😊',
      ),
      Task(
        id: 's_8',
        title: 'Birine teşekkür et',
        description: 'Bugün birine teşekkür et!',
        category: TaskCategory.social,
        emoji: '🙏',
      ),
      Task(
        id: 's_9',
        title: 'Birine iltifat et',
        description: 'Birine güzel bir iltifat et!',
        category: TaskCategory.social,
        emoji: '💖',
      ),
      Task(
        id: 's_10',
        title: 'Birine yardım et',
        description: 'Bugün birine yardım et!',
        category: TaskCategory.social,
        emoji: '🤝',
      ),
    ];
  }

  static List<Task> _getBilimTasks() {
    return [
      Task(
        id: 'b_1',
        title: 'Bir deney yap',
        description: 'Basit bir bilim deneyi yap!',
        category: TaskCategory.creative,
        emoji: '🔬',
      ),
      Task(
        id: 'b_2',
        title: 'Bir bitki yetiştir',
        description: 'Bir tohum ek ve bitki yetiştir!',
        category: TaskCategory.creative,
        emoji: '🌱',
      ),
      Task(
        id: 'b_3',
        title: 'Gökyüzünü gözlemle',
        description: 'Gökyüzünü gözlemle ve not al!',
        category: TaskCategory.creative,
        emoji: '🌌',
      ),
      Task(
        id: 'b_4',
        title: 'Bir hayvanı incele',
        description: 'Bir hayvanı dikkatlice incele!',
        category: TaskCategory.creative,
        emoji: '🔍',
      ),
      Task(
        id: 'b_5',
        title: 'Bir bulut şekli bul',
        description: 'Bulutlarda bir şekil bul!',
        category: TaskCategory.creative,
        emoji: '☁️',
      ),
      Task(
        id: 'b_6',
        title: 'Bir deney yap',
        description: 'Basit bir bilim deneyi yap!',
        category: TaskCategory.creative,
        emoji: '🧪',
      ),
      Task(
        id: 'b_7',
        title: 'Bir bitki yetiştir',
        description: 'Bir tohum ek ve bitki yetiştir!',
        category: TaskCategory.creative,
        emoji: '🌿',
      ),
      Task(
        id: 'b_8',
        title: 'Gökyüzünü gözlemle',
        description: 'Gökyüzünü gözlemle ve not al!',
        category: TaskCategory.creative,
        emoji: '⭐',
      ),
      Task(
        id: 'b_9',
        title: 'Bir hayvanı incele',
        description: 'Bir hayvanı dikkatlice incele!',
        category: TaskCategory.creative,
        emoji: '🐾',
      ),
      Task(
        id: 'b_10',
        title: 'Bir bulut şekli bul',
        description: 'Bulutlarda bir şekil bul!',
        category: TaskCategory.creative,
        emoji: '☁️',
      ),
    ];
  }
}
