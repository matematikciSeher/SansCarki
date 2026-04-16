import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../services/audio_service.dart';
import '../services/admob_service.dart';
import '../services/ad_manager.dart';
import '../services/user_service.dart';
import '../services/performance_service.dart';
import '../widgets/banner_ad_widget.dart';

class GameLogic {
  final List<String> players;
  final String secretWord; // Uppercase, Turkish supported
  final List<int> scores;
  final Set<String> revealed; // set of revealed uppercase letters
  int currentPlayerIndex;
  String? lastSpin; // e.g. '+100', 'İflas', 'Pas'
  late final List<bool> jokerUsed;

  GameLogic({
    required this.players,
    required this.secretWord,
  })  : scores = List<int>.filled(players.length, 0),
        revealed = {},
        currentPlayerIndex = 0 {
    jokerUsed = List<bool>.filled(players.length, false);
  }

  bool get isSolved {
    for (final ch in secretWord.characters) {
      if (_isLetter(ch) && !revealed.contains(_normalize(ch))) return false;
    }
    return true;
  }

  static bool _isLetter(String ch) {
    final code = ch.codeUnitAt(0);
    return (code >= 65 && code <= 90) ||
        (code >= 97 && code <= 122) ||
        'ÇĞİÖŞÜçğıöşü'.contains(ch);
  }

  static String _normalize(String ch) {
    if (ch == 'i') return 'İ';
    if (ch == 'ı') return 'I';
    return ch.toUpperCase();
  }

  static const Set<String> vowels = {'A', 'E', 'I', 'İ', 'O', 'Ö', 'U', 'Ü'};
  static bool isVowel(String ch) => vowels.contains(_normalize(ch));

  int revealLetter(String letter) {
    final up = _normalize(letter);
    int count = 0;
    for (final ch in secretWord.characters) {
      if (_isLetter(ch) && _normalize(ch) == up) {
        if (!revealed.contains(up)) {
          // count all occurrences; reveal stays by letter set
        }
        count++;
      }
    }
    if (count > 0) revealed.add(up);
    return count;
  }

  void applySpinResult(String result) {
    lastSpin = result;
    if (result == 'İflas') {
      scores[currentPlayerIndex] = 0;
      _nextPlayer();
    } else if (result == 'Pas') {
      _nextPlayer();
    }
  }

  void rewardForGuess(int perLetterPoints, int count) {
    scores[currentPlayerIndex] += perLetterPoints * count;
  }

  void _nextPlayer() {
    if (players.length <= 1) return; // Tek oyuncuda sıra değişmez
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
  }

  void switchTurn() => _nextPlayer();

  int buyVowel(String letter) {
    final up = _normalize(letter);
    if (!isVowel(up)) return 0;
    if (scores[currentPlayerIndex] < 200) return -1;
    scores[currentPlayerIndex] -= 200;
    final count = revealLetter(up);
    return count;
  }

  String? useJoker(Random random) {
    if (jokerUsed[currentPlayerIndex]) return null;
    final allLetters = <String>{};
    for (final ch in secretWord.characters) {
      if (_isLetter(ch)) allLetters.add(_normalize(ch));
    }
    final hidden = allLetters.difference(revealed);
    if (hidden.isEmpty) return null;
    final consonants = hidden.where((c) => !isVowel(c)).toList();
    final pool = consonants.isNotEmpty ? consonants : hidden.toList();
    final pick = pool[random.nextInt(pool.length)];
    revealLetter(pick);
    jokerUsed[currentPlayerIndex] = true;
    return pick;
  }
}

class WheelOfFortuneScreen extends StatefulWidget {
  final UserProfile profile;
  const WheelOfFortuneScreen({super.key, required this.profile});

  @override
  State<WheelOfFortuneScreen> createState() => _WheelOfFortuneScreenState();
}

class _WheelOfFortuneScreenState extends State<WheelOfFortuneScreen>
    with SingleTickerProviderStateMixin {
  late GameLogic _logic;
  String? _hintCategory;
  String? _hintText;
  late AnimationController _controller;
  late Animation<double> _rotation;
  final Random _random = Random();
  bool _spinning = false;
  List<Map<String, String>> _singleItems = [];
  bool _loading = true;
  final Set<String> _usedWords = {};
  int _lastTickIndex = -1;
  bool _showIntro = true;
  int? _pendingTargetIndex; // Seçilen dilim indeksi
  bool _sessionSaved = false;
  int _rewardedHintWatchCount = 0;

  static const int _maxRewardedHintWatchCountPerItem = 3;

  final List<String> _segments = const [
    '+100',
    '+200',
    '+300',
    '+400',
    '+500',
    '+700',
    '+900',
    '+1200',
    '+1500',
    '+2000',
    'Pas',
    'İflas'
  ];

  String _normalizeTr(String input) {
    final buffer = StringBuffer();
    for (final ch in input.trim().characters) {
      if (ch == 'i')
        buffer.write('İ');
      else if (ch == 'ı')
        buffer.write('I');
      else
        buffer.write(ch.toUpperCase());
    }
    return buffer.toString();
  }

  String _lettersOnlyUpper(String input) {
    final buffer = StringBuffer();
    for (final ch in input.characters) {
      if (GameLogic._isLetter(ch)) {
        buffer.write(GameLogic._normalize(ch));
      }
    }
    return buffer.toString();
  }

  String _normalizeDifficulty(String? input) {
    var s = (input ?? '').trim();
    if (s.isEmpty) return 'medium';
    // Turkish lowercase nuances
    s = s.replaceAll('İ', 'i').replaceAll('ı', 'i').toLowerCase();
    if (s == 'easy' || s == 'kolay' || s == 'ilkokul' || s == '1-4') {
      return 'easy';
    }
    if (s == 'medium' || s == 'orta' || s == 'ortaokul' || s == '5-8') {
      return 'medium';
    }
    if (s == 'hard' || s == 'zor' || s == 'lise' || s == '9-12') {
      return 'hard';
    }
    return 'medium';
  }

  static const Map<String, String> _semanticHintMap = {
    'KİTAP': 'Sayfaları çevrilerek okunan bir yayındır.',
    'KALEM': 'Defterin yanında sık kullanılan bir okul aracıdır.',
    'DEFTER': 'Derslerde yazı yazmak için kullanılan sayfalı eşyadır.',
    'OKUL': 'Öğrencilerin ders gördüğü eğitim kurumudur.',
    'ÖĞRETMEN': 'Öğrencilere bilgi aktaran eğitimcidir.',
    'ARKADAŞ': 'Birlikte vakit geçirilen yakın dosttur.',
    'OYUN': 'Kurallı ya da serbest şekilde eğlenmek için yapılır.',
    'TOP': 'Futbol ve basketbol gibi sporlarda kullanılır.',
    'EV': 'Ailenle birlikte yaşadığın yerdir.',
    'AĞAÇ': 'Gövdesi olan, meyve ya da gölge verebilen bitkidir.',
    'GÜNEŞ': 'Gündüzü aydınlatan gök cismidir.',
    'AY': 'Dünya\'nın çevresinde dolanan gök cismidir.',
    'YILDIZ': 'Gece gökyüzünde parlak nokta gibi görünür.',
    'KUŞ': 'Kanatlarıyla uçabilen canlıdır.',
    'BALIK': 'Deniz, göl ya da akarsuda yaşar.',
    'ARABA': 'İnsanları bir yerden başka yere taşır.',
    'BİSİKLET': 'İki tekerleği ve gidonu vardır.',
    'ELMA': 'Dalında yetişen ve ısırılarak yenilen bir meyvedir.',
    'MUZ': 'Kabuğu soyularak yenir.',
    'PORTAKAL': 'Suyu sıkılarak da tüketilen bir meyvedir.',
    'SEBZE': 'Yemeklerde sık kullanılan bitkisel besindir.',
    'MEYVE': 'Genelde tatlı olarak tüketilen bitki ürünüdür.',
    'ÇİÇEK': 'Renkli yapraklarıyla bilinir ve hoş koku verebilir.',
    'KEDİ': 'Miyavlayan evcil bir hayvandır.',
    'KÖPEK': 'Havlamasıyla bilinen evcil hayvandır.',
    'TAVŞAN': 'Hızlı koşar ve havuçla anılır.',
    'AYAKKABI': 'Dışarı çıkarken ayağa giyilir.',
    'ÇORAP': 'Ayakkabının içinde ayağı korur.',
    'PANTOLON': 'Bacakları örten bir kıyafettir.',
    'ELBİSE': 'Genelde tek parça olarak giyilen kıyafettir.',
    'ŞAPKA': 'Güneşten korunmak ya da süs için başa takılır.',
    'SU': 'Yaşam için en temel içecektir.',
    'SÜT': 'Kahvaltıda ve tatlılarda sık kullanılır.',
    'PEYNİR': 'Kahvaltı sofralarında sıkça bulunur.',
    'EKMEK': 'Öğünlerde yemeğin yanında sık yenir.',
    'TATLI': 'Yemekten sonra da yenebilen şekerli yiyecektir.',
    'TUZ': 'Yemeğin tadını artırmak için az miktarda kullanılır.',
    'ŞEKER': 'Çaya ya da tatlılara tat verir.',
    'ÇİKOLATA': 'Kakao ile yapılan sevilen bir atıştırmalıktır.',
    'SAÇ': 'Kesilebilir, taranabilir ve uzar.',
    'GÖZ': 'Bakmak ve görmek için kullanılır.',
    'KULAK': 'Sesleri algılar ve duymayı sağlar.',
    'BURUN': 'Yüzde bulunur ve kokuları algılar.',
    'AĞIZ': 'Konuşurken ve yemek yerken kullanılır.',
    'DİŞ': 'Ağız içinde bulunur ve besinleri parçalar.',
    'EL': 'Yazı yazarken, tutarken ve taşırken kullanılır.',
    'AYAK': 'Vücudu taşır ve yürümeye yardım eder.',
    'KOL': 'Omuzdan ele uzanan uzuvdur.',
    'BACAK': 'Koşarken ve zıplarken büyük görev yapar.',
    'YÜZ': 'Göz, burun ve ağız bu bölgede bulunur.',
    'BAŞ': 'Düşünme ve duyularla ilgili organları taşır.',
    'KALP': 'Kan dolaşımında önemli görev yapar.',
    'BEYİN': 'Karar verme, öğrenme ve düşünmede görev alır.',
    'OKUMAK': 'Kitap, dergi ya da yazılardaki bilgiyi anlamayı sağlar.',
    'YAZMAK': 'Düşünceleri harflerle ifade etmektir.',
    'ÇİZMEK': 'Kalemle şekil ya da resim oluşturmaktır.',
    'DİNLEMEK': 'Söyleneni dikkatle işitmektir.',
    'KONUŞMAK': 'Duygu ve düşünceleri sözle anlatmaktır.',
    'KOŞMAK': 'Yürümekten daha hızlı hareket etmektir.',
    'ZIPLAMAK': 'Ayaklarla yerden yükselmektir.',
    'YÜZMEK': 'Suda batmadan ilerlemeyi sağlar.',
    'UYUMAK': 'Gece dinlenmek için yapılan eylemdir.',
    'GÜLMEK': 'Sevinç ve neşe belirtisidir.',
    'AĞLAMAK': 'Üzüntü ya da acı sırasında olabilir.',
    'SEVİNMEK': 'İyi bir olay karşısında mutlu olmaktır.',
    'ÜZÜLMEK': 'Kötü bir durumda mutsuz hissetmektir.',
    'YARDIM ETMEK': 'Birine işini kolaylaştıracak destek vermektir.',
    'PAYLAŞMAK': 'Sahip olunan şeyi başkasıyla bölüşmektir.',
    'BEKLEMEK': 'Bir şeyin olacağı zamana kadar sabretmektir.',
    'TEMİZLEMEK': 'Kirli bir şeyi düzenli ve temiz hale getirmektir.',
    'YEMEK YAPMAK': 'Mutfakta malzemeleri hazırlayıp pişirmektir.',
    'ALIŞVERİŞ': 'Mağaza ya da marketten ihtiyaç almaktır.',
    'OYNAMAK': 'Eğlenmek için hareket etmek ya da vakit geçirmektir.',
    'KOŞU': 'Hızlı hareket edilen bir spor dalıdır.',
    'DANS': 'Ritme uyularak yapılan vücut hareketleridir.',
    'ŞARKI': 'Söz ve melodiyle söylenen müzik eseridir.',
    'RESİM': 'Boyalar ya da kalemle oluşturulan görseldir.',
    'FİLM': 'Ekranda izlenen kurmaca ya da gerçek hikayedir.',
    'HİKAYE': 'Başlangıcı ve sonu olan kısa anlatımdır.',
    'BİLGİSAYAR': 'Bilgiye ulaşmak, yazı yazmak ve oyun oynamak için de kullanılır.',
    'TABLET': 'Ekranına dokunularak kullanılan taşınabilir cihazdır.',
    'TELEFON': 'Mesajlaşma ve arama yapmaya yarar.',
    'İNTERNET': 'Dünyadaki bilgilere çevrim içi ulaşmayı sağlar.',
    'ROBOT': 'Bazı işleri insan yerine otomatik yapabilir.',
    'YAZILIM': 'Bir cihazın ne yapacağını belirleyen komutlardır.',
    'DONANIM': 'Ekran, klavye ve işlemci gibi somut parçalardan oluşur.',
    'KODLAMA': 'Bilgisayara ne yapacağını adım adım anlatmaktır.',
    'MATEMATİK': 'Problemler, sayılar ve işlemlerle ilgilenir.',
    'FİZİK': 'Hareket, kuvvet, ışık ve enerji gibi konuları inceler.',
    'KİMYA': 'Maddelerin değişimini ve tepkimelerini araştırır.',
    'BİYOLOJİ': 'İnsan, hayvan ve bitki yaşamını inceler.',
    'GEOMETRİ': 'Üçgen, kare ve çember gibi şekillerle ilgilenir.',
    'TARİH': 'Geçmişte yaşanan olayları zaman sırasıyla ele alır.',
    'COĞRAFYA': 'Haritalar, iklim ve yeryüzü şekilleriyle ilgilenir.',
    'SANAT': 'Duygu ve düşünceleri estetik biçimde anlatma yoludur.',
    'MÜZİK': 'Nota, ritim ve melodiyle ilgilidir.',
    'DRAMA': 'Rol yapma ve canlandırma etkinliklerini içerir.',
    'SPOR': 'Bedeni güçlendiren ve kurallı yapılan etkinlikler bütünüdür.',
    'FUTBOL': 'Ayakla oynanan ve kaleye gol atılan spordur.',
    'BASKETBOL': 'Topun potadan geçirilmesi amaçlanır.',
    'VOLEYBOL': 'Top file üzerinden karşı sahaya gönderilir.',
    'TENİS': 'Rakiple file üzerinden raketle oynanır.',
    'ATLETİZM': 'Koşu, atlama ve atma branşlarını kapsar.',
    'FOTOĞRAF': 'Bir anı ya da görüntüyü kalıcı hale getirir.',
    'TİYATRO': 'Seyirci önünde sahnede canlı olarak oynanır.',
    'ROMAN': 'Kişi ve olayları ayrıntılı anlatan uzun edebi türdür.',
    'ŞİİR': 'Uyum, imge ve duygu yönü güçlü edebi türdür.',
    'GAZETE': 'Günlük haber, köşe yazısı ve ilanlar içerebilir.',
    'DERGİ': 'Belirli aralıklarla yayımlanan süreli yayındır.',
    'BİLGİ': 'Öğrenme, deneyim ya da araştırma sonucunda elde edilir.',
    'ARAŞTIRMA': 'Bir konuyu derinlemesine öğrenmek için yapılır.',
    'DENEY': 'Bir sonucu gözlemlemek için kontrollü koşullarda yapılır.',
    'GÖZLEM': 'Bir olayı dikkatle izleyip bilgi toplamaktır.',
    'HİPOTEZ': 'Doğrulanması beklenen bilimsel tahmindir.',
    'TEORİ': 'Birçok kanıtla desteklenen açıklamadır.',
    'PROBLEM': 'Çözüm bekleyen güçlük ya da sorundur.',
    'ÇÖZÜM': 'Bir sorunu ortadan kaldıran cevap ya da yöntemdir.',
    'STRATEJİ': 'Hedefe ulaşmak için önceden belirlenen yoldur.',
    'TARTIŞMA': 'Farklı görüşlerin konuşularak değerlendirildiği ortamdır.',
    'SUNUM': 'Bir konuyu dinleyicilere düzenli biçimde anlatmadır.',
    'SÖZLÜK': 'Kelimelerin anlamını ve bazen yazımını gösterir.',
    'ANSİKLOPEDİ': 'Birçok konuda sistemli bilgi sunar.',
    'MAKALE': 'Bir düşünceyi ya da araştırmayı açıklayan yazı türüdür.',
    'BİLİM': 'Doğru ve kanıtlanabilir bilgi üretmeyi amaçlar.',
    'TEKNOLOJİ': 'Günlük yaşamı kolaylaştıran araç ve sistemler üretir.',
    'SANAYİ': 'Fabrikalar ve üretim süreçleriyle ilişkilidir.',
    'TRAFİK': 'Araç ve yayaların yoldaki hareket düzenidir.',
    'ÇEVRE': 'İnsan, doğa ve yaşam alanlarıyla ilgilidir.',
    'DOĞA': 'İnsan eli değmeden var olan canlı ve cansız çevredir.',
    'HAYVAN': 'Hareket edebilen ve beslenen canlı grubudur.',
    'BİTKİ': 'Büyüyen, fotosentez yapan canlı grubudur.',
    'DERS': 'Okulda belli bir konuda işlenen öğretim saatidir.',
    'SINAV': 'Bilgi düzeyini ölçmek için uygulanır.',
    'ÖDEV': 'Ders sonrası öğrenciden yapması beklenen çalışmadır.',
    'PROJELER': 'Planlama, araştırma ve üretim içeren çalışmalardır.',
    'TAKIM': 'Ortak amaç için birlikte hareket eden gruptur.',
    'LİDER': 'Gruba yön veren ve karar almada etkili olan kişidir.',
    'GÜVEN': 'İnsanın birine ya da bir şeye içten inanmasıdır.',
    'SORUMLULUK': 'Yapılması gereken görevi üstlenme durumudur.',
    'MOTİVASYON': 'İnsanı harekete geçiren iç güçtür.',
    'PLANLAMA': 'Bir işi yapmadan önce adımları belirlemektir.',
    'DİSİPLİN': 'Kurallı ve düzenli davranma alışkanlığıdır.',
    'ARKADAŞLIK': 'İki kişi arasında sevgi ve güvene dayanan bağdır.',
    'İLETİŞİM': 'Duygu, düşünce ve bilgiyi karşı tarafa aktarmaktır.',
    'PAYLAŞIM': 'Bir şeyi tek başına tutmayıp başkalarıyla da kullanmaktır.',
    'BİLİNÇ': 'Kişinin kendisinin ve çevresinin farkında olmasıdır.',
    'KARAR': 'Seçenekler arasından birini seçme sonucudur.',
    'BAŞARI': 'Emek vererek istenen sonuca ulaşmaktır.',
    'HEDEF': 'Ulaşılmak istenen sonuç ya da noktadır.',
    'DENEME': 'Sonucu görmek için yapılan girişimdir.',
    'BAŞLAMAK': 'Bir işe ilk adımı atmak demektir.',
    'BİTİRMEK': 'Bir işi sona erdirip tamamlamak demektir.',
    'YENİLİK': 'Daha önce olmayan yeni bir durum ya da fikir demektir.',
    'FİKİR': 'Aklında oluşan düşünce ya da görüştür.',
    'KOMŞU KOMŞUNUN KÜLÜNE MUHTAÇTIR.':
        'İnsanların birbirine destek olması gerektiğini anlatır.',
    'DAMLAYA DAMLAYA GÖL OLUR.':
        'Az görünen kazançların zamanla büyümesini anlatır.',
    'İYİLİK EDEN, İYİLİK BULUR.':
        'Başkalarına iyi davranmanın karşılıksız kalmayacağını söyler.',
    'SABRIN SONU SELAMETTİR.':
        'Zor zamanlarda pes etmemeyi öğütler.',
    'BİR ELİN NESİ VAR, İKİ ELİN SESİ VAR.':
        'İş birliği ve yardımlaşmanın önemini vurgular.',
    'ACELE İŞE ŞEYTAN KARIŞIR.':
        'Düşünmeden yapılan işlerin bozulabileceğini anlatır.',
    'TAŞ YERİNDE AĞIRDIR.':
        'Bir insanın kendi çevresinde daha değerli görüldüğünü anlatır.',
    'AZICIK AŞIM KAYGISIZ BAŞIM.':
        'Azla yetinmenin huzur getirdiğini söyler.',
    'SÖZ GÜMÜŞSE, SÜKÛT ALTINDIR.':
        'Bazen susmanın konuşmaktan daha doğru olduğunu anlatır.',
    'SAKINAN GÖZE ÇÖP BATAR.':
        'Aşırı titizliğin beklenmedik zararlara yol açabileceğini söyler.',
    'KOMŞU HAKKI, ALLAH HAKKIDIR.':
        'Yakın çevreye saygı göstermenin büyük önemini vurgular.',
    'NE EKERSEN, ONU BİÇERSİN.':
        'Yapılan davranışların sonucunun yine kişiye döneceğini anlatır.',
    'GÜZELE BAKMAK SEVAPTIR.':
        'Güzelliğin insana iyi geldiğini ifade eder.',
    'HER İŞİN BAŞI SAĞLIK.':
        'Hayattaki her şey için önce iyi olmanın gerektiğini söyler.',
    'İYİLİK EDEN, KÖTÜLÜK GÖRMEZ.':
        'İyi kalpli insanların sonunda kazançlı çıkacağını anlatır.',
    'AYAĞINI YORGANINA GÖRE UZAT.':
        'Harcamalarda elindeki imkanları aşmaman gerektiğini söyler.',
    'GÜVENME VARLIĞA, DÜŞERSİN DARLIĞA.':
        'Maddi imkanların her zaman sürmeyeceğini hatırlatır.',
    'ÇALIŞAN KAZANIR, TEMBEL YANILIR.':
        'Başarı için çaba göstermek gerektiğini anlatır.',
    'TAŞIN ÜSTÜNE TAŞ KOYMAK GEREKİR.':
        'Gelişmek için emek verip üzerine koymak gerektiğini söyler.',
    'İKİ GÖNÜL BİR OLUNCA SAMANLIK SEYRAN OLUR.':
        'Sevginin zor şartları bile güzelleştirebileceğini anlatır.',
    'KOMŞU KOMŞUYA, DOST DOSTUNA MUHTAÇTIR.':
        'İnsanların hem dosta hem komşuya ihtiyaç duyduğunu anlatır.',
    'SABREDEN DERVİŞ MURADINA ERMİŞ.':
        'İstenen sonuca sabırla ulaşılabileceğini söyler.',
    'AZICIK KANAATKÂR, BOLCA MUTLU.':
        'Kanaat etmenin huzur verdiğini anlatır.',
    'ÖNCE İŞ, SONRA EĞLENCE.':
        'Sorumlulukların keyiften önce gelmesi gerektiğini söyler.',
    'HERKES KENDİ EVİNDE KRALDIR.':
        'İnsanın kendi alanında daha rahat ve etkili olduğunu anlatır.',
    'EL ELDEN ÜSTÜNDÜR.':
        'Her zaman daha bilgili ya da daha güçlü birinin olabileceğini hatırlatır.',
    'İYİLİK EDEN, GÖNÜL ALIR.':
        'Nazik davranışların insanların kalbini kazandığını anlatır.',
    'SÖZ UÇAR, YAZI KALIR.':
        'Yazılı bilginin daha kalıcı olduğunu vurgular.',
    'İYİLİK EDEN, GÖNÜL KAZANIR.':
        'İyi davranışların sevgi ve dostluk getirdiğini söyler.',
    'KOMŞU KOMŞUYA MİHMANDIR.':
        'Yakın çevrenin zor zamanda destek olacağını anlatır.',
    'SABIR ACIDIR, MEYVESİ TATLIDIR.':
        'Zorluklara katlanan kişinin sonunda ödül alacağını söyler.',
  };

  String _buildSemanticTypeHint(
    String seedText, {
    required bool isProverb,
  }) {
    final seed = seedText.toLowerCase();
    if (isProverb) {
      return 'Bu atasözü günlük yaşam için yol gösteren bir öğüt içerir.';
    }
    if (seed.contains('hayvan') || seed.contains('canlı')) {
      return 'Bu kelime canlılar dünyasıyla ilgilidir.';
    }
    if (seed.contains('meyve') ||
        seed.contains('sebze') ||
        seed.contains('yiyecek') ||
        seed.contains('içecek') ||
        seed.contains('besin') ||
        seed.contains('süt ürünü')) {
      return 'Bu kelime beslenme ve mutfakla ilişkilidir.';
    }
    if (seed.contains('organ') ||
        seed.contains('uzuv') ||
        seed.contains('vücud') ||
        seed.contains('başımızda')) {
      return 'Bu kelime insan vücuduyla ilgili bir bölümü anlatır.';
    }
    if (seed.contains('giysi') ||
        seed.contains('giyilen') ||
        seed.contains('ayağa') ||
        seed.contains('baş için')) {
      return 'Bu kelime giyimle ilgili bir parçayı anlatır.';
    }
    if (seed.contains('okul') ||
        seed.contains('ders') ||
        seed.contains('öğren') ||
        seed.contains('kitap') ||
        seed.contains('yazı') ||
        seed.contains('ödev') ||
        seed.contains('sınav') ||
        seed.contains('öğrenci')) {
      return 'Bu kelime eğitim hayatında sık karşılaşılan bir kavramdır.';
    }
    if (seed.contains('cihaz') ||
        seed.contains('elektronik') ||
        seed.contains('program') ||
        seed.contains('bilgisayar') ||
        seed.contains('dokunmatik')) {
      return 'Bu kelime teknolojiyle ilişkili bir kavramdır.';
    }
    if (seed.contains('bilim') ||
        seed.contains('matematik') ||
        seed.contains('fizik') ||
        seed.contains('kimya') ||
        seed.contains('biyoloji') ||
        seed.contains('geometri') ||
        seed.contains('tarih') ||
        seed.contains('coğrafya')) {
      return 'Bu kelime bilgi ve öğrenme alanında kullanılan bir kavramdır.';
    }
    if (seed.contains('oyun') ||
        seed.contains('spor') ||
        seed.contains('top') ||
        seed.contains('yarış') ||
        seed.contains('raket') ||
        seed.contains('file')) {
      return 'Bu kelime hareket ve etkinlik içeren bir alanla ilgilidir.';
    }
    if (seed.contains('mutlu') ||
        seed.contains('mutsuz') ||
        seed.contains('duygu') ||
        seed.contains('sevinç') ||
        seed.contains('üzüntü')) {
      return 'Bu kelime insanın iç dünyasıyla ilgili bir durumu anlatır.';
    }
    if (seed.contains('yer') ||
        seed.contains('kurum') ||
        seed.contains('alan') ||
        seed.contains('yaşanılan')) {
      return 'Bu kelime bir mekan ya da yaşam alanıyla ilgilidir.';
    }
    if (seed.contains('sanat') ||
        seed.contains('müzik') ||
        seed.contains('şiir') ||
        seed.contains('hikaye') ||
        seed.contains('görsel')) {
      return 'Bu kelime sanat ve anlatımla ilgili bir kavramdır.';
    }
    return 'Bu kelime günlük yaşamda kullanılan temel bir kavramdır.';
  }

  String _buildSemanticContextHint(
    String subject,
    String seedText, {
    required bool isProverb,
  }) {
    final normalizedSubject = _normalizeTr(subject);
    final seed = seedText.toLowerCase();
    if (isProverb) {
      if (seed.contains('sabır')) {
        return 'Mesajı, zorluklara dayanmanın sonunda iyi bir sonuç gelebileceğidir.';
      }
      if (seed.contains('iyilik')) {
        return 'Ana fikri, iyi davranışların olumlu karşılık bulmasıdır.';
      }
      if (seed.contains('komşu') || seed.contains('dost')) {
        return 'İnsan ilişkileri ve dayanışma üzerine kuruludur.';
      }
      if (seed.contains('çalış') || seed.contains('emek')) {
        return 'Emek vermenin ve çaba göstermenin önemini anlatır.';
      }
      if (seed.contains('harca') || seed.contains('gelir') || seed.contains('varlık')) {
        return 'Maddi imkanları dikkatli kullanmak gerektiğini hatırlatır.';
      }
      return 'Anlamı, davranışlara yön veren bir hayat dersi vermesidir.';
    }
    if (normalizedSubject.endsWith('MAK') || normalizedSubject.endsWith('MEK')) {
      return 'Bu cevap yapılabilen bir eylem ya da davranışı anlatır.';
    }
    if (seed.contains('hayvan') || seed.contains('canlı')) {
      return 'Doğada ya da günlük yaşamda karşılaşabileceğin bir canlıdır.';
    }
    if (seed.contains('meyve') ||
        seed.contains('sebze') ||
        seed.contains('yiyecek') ||
        seed.contains('içecek') ||
        seed.contains('besin')) {
      return 'Sofrada, mutfakta ya da markette karşına çıkabilir.';
    }
    if (seed.contains('organ') || seed.contains('uzuv') || seed.contains('vücud')) {
      return 'İnsan bedeninin bir parçası olarak görev yapar.';
    }
    if (seed.contains('giysi') || seed.contains('giyilen') || seed.contains('ayağa')) {
      return 'Günlük kıyafetlerle birlikte kullanılan bir parçadır.';
    }
    if (seed.contains('okul') || seed.contains('ders') || seed.contains('öğren')) {
      return 'Öğrencilik hayatında sıkça duyulan ya da kullanılan bir kavramdır.';
    }
    if (seed.contains('cihaz') || seed.contains('elektronik') || seed.contains('program')) {
      return 'Günümüzde dijital dünyada sık karşılaşılan bir kavramdır.';
    }
    if (seed.contains('sanat') || seed.contains('müzik') || seed.contains('görsel')) {
      return 'Üretim, ifade ve yaratıcılıkla bağlantılıdır.';
    }
    if (seed.contains('spor') || seed.contains('oyun') || seed.contains('yarış')) {
      return 'Hareket, eğlence ya da rekabet içeren durumlarda öne çıkar.';
    }
    return 'Anlamı, günlük hayatta sık karşılaşılan bir durum veya nesneye dayanır.';
  }

  List<String> _buildGeneratedExtraHints(
    String subject, {
    required String seedText,
    required bool isProverb,
  }) {
    final normalizedSubject = _normalizeTr(subject);
    final semanticHint = _semanticHintMap[normalizedSubject];
    final hints = <String>[
      if (semanticHint != null && semanticHint.isNotEmpty) semanticHint,
      _buildSemanticTypeHint(
        semanticHint ?? seedText,
        isProverb: isProverb,
      ),
      _buildSemanticContextHint(
        subject,
        semanticHint ?? seedText,
        isProverb: isProverb,
      ),
    ];

    final uniqueHints = <String>[];
    for (final hint in hints) {
      final trimmed = hint.trim();
      if (trimmed.isEmpty || uniqueHints.contains(trimmed)) continue;
      uniqueHints.add(trimmed);
    }
    return uniqueHints;
  }

  List<Map<String, String>> _normalizeHints(
    List<dynamic>? rawHints, {
    required String fallbackCategory,
    required String fallbackText,
    required String subject,
    required bool isProverb,
  }) {
    final hints = <Map<String, String>>[];

    if (rawHints != null) {
      for (final item in rawHints) {
        if (item is! Map) continue;
        final text = (item['text'] ?? item['hint'] ?? item['ipucu'] ?? '')
            .toString()
            .trim();
        if (text.isEmpty || text == 'Atasözü') continue;
        final category = (item['category'] ?? fallbackCategory).toString().trim();
        hints.add({
          'category': category.isEmpty ? fallbackCategory : category,
          'text': text,
        });
      }
    }

    if (hints.isEmpty) {
      hints.add({
        'category': fallbackCategory,
        'text': fallbackText,
      });
    }

    final extraHints = _buildGeneratedExtraHints(
      subject,
      seedText: hints.first['text'] ?? fallbackText,
      isProverb: isProverb,
    );
    for (final extraHint in extraHints) {
      if (hints.any((hint) => hint['text'] == extraHint)) continue;
      hints.add({
        'category': 'Ekstra İpucu',
        'text': extraHint,
      });
    }

    return hints.take(4).toList();
  }

  Map<String, String>? _findCurrentItem() {
    for (final item in _singleItems) {
      if (item['word'] == _logic.secretWord) return item;
    }
    return null;
  }

  List<Map<String, String>> _currentHints() {
    final current = _findCurrentItem();
    final encoded = current?['hints'];
    if (encoded == null || encoded.isEmpty) {
      return const [
        {'category': 'İpucu', 'text': 'İpucu yok.'}
      ];
    }

    final decoded = json.decode(encoded);
    if (decoded is! List) {
      return const [
        {'category': 'İpucu', 'text': 'İpucu yok.'}
      ];
    }

    return decoded
        .whereType<Map>()
        .map((hint) => {
              'category': '${hint['category'] ?? 'İpucu'}',
              'text': '${hint['text'] ?? 'İpucu yok.'}',
            })
        .toList();
  }

  int _currentHintIndex(List<Map<String, String>> hints) {
    if (hints.isEmpty) return -1;
    final index = hints.indexWhere(
      (hint) =>
          hint['category'] == _hintCategory && hint['text'] == _hintText,
    );
    return index >= 0 ? index : 0;
  }

  bool _hasMoreHints() {
    final hints = _currentHints();
    if (hints.isEmpty) return false;
    return _currentHintIndex(hints) < hints.length - 1;
  }

  bool _canWatchMoreHintAds() {
    return _rewardedHintWatchCount < _maxRewardedHintWatchCountPerItem;
  }

  int _remainingHintAdCount() {
    return _maxRewardedHintWatchCountPerItem - _rewardedHintWatchCount;
  }

  Map<String, String>? _unlockNextHint() {
    final hints = _currentHints();
    if (hints.isEmpty) return null;

    final nextIndex = _currentHintIndex(hints) + 1;
    if (nextIndex >= hints.length) return null;

    final next = hints[nextIndex];
    setState(() {
      _hintCategory = next['category'];
      _hintText = next['text'];
    });
    return next;
  }

  @override
  void initState() {
    super.initState();
    WheelAdManager.instance.preloadAll();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadWords();
      final initial = _pickFromAssets();
      setState(() {
        final hints = (json.decode(initial['hints']!) as List).cast<Map>();
        _hintCategory = '${hints.first['category']}';
        _hintText = '${hints.first['text']}';
        _rewardedHintWatchCount = 0;
        _logic = GameLogic(
          players: ['Oyuncu'],
          secretWord: initial['word']!,
        );
        _usedWords.add(initial['word']!);
        _loading = false;
      });
    });
    _controller = AnimationController(
      vsync: this,
      duration: PerformanceService.instance.getWheelSpinDuration(),
    );
    _rotation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: PerformanceService.instance.getAnimationCurve()),
    )
      ..addListener(() {
        // Tick sound on segment change
        final perSlice = 2 * pi / _segments.length;
        final norm = (_rotation.value + pi / 2) % (2 * pi);
        final idx = (norm / perSlice).floor() % _segments.length;
        if (idx != _lastTickIndex) {
          _lastTickIndex = idx;
          SystemSound.play(SystemSoundType.click);
        }
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _spinning = false);
          final result = (_pendingTargetIndex != null)
              ? _segments[_pendingTargetIndex!]
              : _resultFromAngle(_rotation.value);
          _pendingTargetIndex = null;

          final previousScore = _logic.scores[_logic.currentPlayerIndex];
          _logic.applySpinResult(result);

          if (result == 'İflas') {
            AudioService.playBankrupt();
          } else if (result == 'Pas') {
            AudioService.playPass();
          } else if (result.startsWith('+')) {
            AudioService.playPoints();
          }

          if (WheelAdManager.isBadResult(result)) {
            _showBadResultOffer(result, previousScore);
          } else {
            _showActionPopup(result);
          }

          if (result == 'İflas' || result == 'Pas') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result == 'İflas'
                      ? 'İflas! Puan sıfırlandı.'
                      : (_logic.players.length <= 1
                          ? 'Pas! Tur boşa geçti.'
                          : 'Pas! Sıra diğer oyuncuda.'),
                ),
              ),
            );
          }
        }
      });
  }

  @override
  void dispose() {
    // Eğer Bitir'e basmadan çıkılırsa, puanı kaybetme diye sessizce kaydet
    if (!_sessionSaved) {
      _saveSessionGamePoints();
    }
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadWords() async {
    final jsonStr = await DefaultAssetBundle.of(context)
        .loadString('assets/words_hints.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;

    List<Map<String, String>> collect = [];

    String normDiff(String tag) => _normalizeDifficulty(tag);
    List<Map<String, String>> mapWords(List words, String diffTag) {
      return words
          .map((e) {
            final m = e as Map<String, dynamic>;
            final raw = (m['word'] ?? m['kelime'] ?? '').toString();
            final hintText =
                (m['ipuç'] ?? m['ipucu'] ?? m['hint'] ?? m['hints'] ?? '')
                    .toString();
            final word = raw.toString();
            final normalizedWord = _normalizeTr(word.toString());
            final hintsList = _normalizeHints(
              (m['hints'] is List) ? (m['hints'] as List) : null,
              fallbackCategory: 'Kelime İpucu',
              fallbackText: hintText.isNotEmpty
                  ? hintText
                  : 'Kelime hakkında ipucu',
              subject: normalizedWord,
              isProverb: false,
            );
            return {
              'word': normalizedWord,
              'hints': json.encode(hintsList),
              'difficulty': normDiff(diffTag),
            };
          })
          .cast<Map<String, String>>()
          .toList();
    }

    List<Map<String, String>> mapAtasozleri(
        List<dynamic> list, String diffTag) {
      return list
          .map((it) {
            if (it is String) {
              final proverb = _normalizeTr(it);
              return {
                'word': proverb,
                'hints': json.encode(
                  _normalizeHints(
                    const [
                      {
                        'category': 'Atasözü',
                        'text': 'Geleneksel bir öğüt içerir.'
                      },
                      {
                        'category': 'Atasözü',
                        'text': 'Günlük hayatta kullanılır.'
                      },
                    ],
                    fallbackCategory: 'Atasözü',
                    fallbackText: 'Geleneksel bir öğüt içerir.',
                    subject: proverb,
                    isProverb: true,
                  ),
                ),
                'difficulty': normDiff(diffTag),
              };
            } else {
              final m = it as Map<String, dynamic>;
              final proverb =
                  _normalizeTr((m['word'] ?? m['kelime'] ?? '').toString());
              return {
                'word': proverb,
                'hints': json.encode(
                  _normalizeHints(
                    (m['hints'] is List) ? (m['hints'] as List) : null,
                    fallbackCategory: 'Atasözü',
                    fallbackText: 'Geleneksel bir öğüt içerir.',
                    subject: proverb,
                    isProverb: true,
                  ),
                ),
                'difficulty': normDiff(diffTag),
              };
            }
          })
          .cast<Map<String, String>>()
          .toList();
    }

    if (data.containsKey('single')) {
      // Old schema
      _singleItems = (data['single'] as List)
          .map((e) {
            final m = e as Map<String, dynamic>;
            final word = '${m['word']}';
            return {
              'word': _normalizeTr(word),
              'hints': json.encode(
                _normalizeHints(
                  (m['hints'] is List) ? (m['hints'] as List) : null,
                  fallbackCategory: 'Kelime İpucu',
                  fallbackText: 'Kelime hakkında ipucu',
                  subject: _normalizeTr(word),
                  isProverb: false,
                ),
              ),
              'difficulty': _normalizeDifficulty(m['difficulty']?.toString()),
            };
          })
          .cast<Map<String, String>>()
          .toList();
      final extra =
          mapAtasozleri((data['atasozleri'] as List?) ?? const [], 'medium');
      _singleItems.addAll(extra);
    } else if (data.containsKey('ilkokul') ||
        data.containsKey('ortaokul') ||
        data.containsKey('lise')) {
      // New schema
      final ilkokul = (data['ilkokul'] as Map<String, dynamic>?);
      final ortaokul = (data['ortaokul'] as Map<String, dynamic>?);
      final lise = (data['lise'] as Map<String, dynamic>?);

      if (ilkokul != null) {
        collect.addAll(
            mapWords((ilkokul['kelimeler'] as List?) ?? const [], 'easy'));
        collect.addAll(mapAtasozleri(
            (ilkokul['atasozleri'] as List?) ?? const [], 'easy'));
      }
      if (ortaokul != null) {
        collect.addAll(
            mapWords((ortaokul['kelimeler'] as List?) ?? const [], 'medium'));
        collect.addAll(mapAtasozleri(
            (ortaokul['atasozleri'] as List?) ?? const [], 'medium'));
      }
      if (lise != null) {
        collect
            .addAll(mapWords((lise['kelimeler'] as List?) ?? const [], 'hard'));
        collect.addAll(
            mapAtasozleri((lise['atasozleri'] as List?) ?? const [], 'hard'));
      }

      _singleItems = collect;
    } else {
      // Fallback minimal
      _singleItems = [
        {
          'word': 'FLUTTER',
          'hints': json.encode([
            {'category': 'İpucu', 'text': 'Google’ın UI aracı'}
          ]),
          'difficulty': 'medium',
        }
      ];
    }
  }

  Map<String, String> _pickFromAssets() {
    final list = _singleItems;
    String targetDifficulty = 'medium';
    final grade = widget.profile.grade;
    if (grade != null) {
      if (grade <= 4)
        targetDifficulty = 'easy';
      else if (grade <= 8)
        targetDifficulty = 'medium';
      else
        targetDifficulty = 'hard';
    }
    final filtered = list
        .where((m) =>
            (m['difficulty'] == targetDifficulty) || m['difficulty'] == null)
        .toList();
    final pool = filtered.isNotEmpty ? filtered : list;
    // Prefer words not used in this session
    final fresh = pool.where((m) => !_usedWords.contains(m['word'])).toList();
    final selectionPool = fresh.isNotEmpty ? fresh : pool;
    if (list.isEmpty) {
      return {
        'word': 'FLUTTER',
        'hints': json.encode([
          {'category': 'İpucu', 'text': 'Google’ın UI aracı'}
        ])
      };
    }
    return selectionPool[_random.nextInt(selectionPool.length)];
  }

  void _spinWheel() async {
    if (_spinning) return;

    WheelAdManager.instance.incrementSpinCount();
    if (WheelAdManager.instance.shouldShowInterstitial &&
        WheelAdManager.instance.isInterstitialReady) {
      await WheelAdManager.instance.showInterstitialAd();
      if (!mounted) return;
    }

    _doSpin();
  }

  void _doSpin() {
    setState(() => _spinning = true);
    AudioService.playSpinStart();
    final spins = 3;
    final targetIndex = _random.nextInt(_segments.length);
    _pendingTargetIndex = targetIndex;
    final perSlice = 2 * pi / _segments.length;
    final double current = _rotation.value % (2 * pi);
    final double targetCenter =
        -(pi / 2 + perSlice / 2) - targetIndex * perSlice;
    double base = (targetCenter - current) % (2 * pi);
    if (base < 0) base += 2 * pi;
    final double totalAdvance = spins * 2 * pi + base;
    final double endAngle = _rotation.value + totalAdvance;
    _rotation = Tween<double>(begin: _rotation.value, end: endAngle).animate(
        CurvedAnimation(
            parent: _controller,
            curve: PerformanceService.instance.getAnimationCurve()));
    _controller.forward(from: 0);
  }

  String _resultFromAngle(double angle) {
    // Çarkın tepesindeki göstergeye göre sonuç
    final norm = (angle + pi / 2) % (2 * pi);
    final perSlice = 2 * pi / _segments.length;
    final index = ((norm + perSlice / 2) / perSlice).floor() % _segments.length;
    return _segments[index];
  }

  void _guessLetter() async {
    final last = _logic.lastSpin;
    if (last == null || last == 'İflas' || last == 'Pas') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce çarkı çevir ve sayı gelmeli.')),
      );
      return;
    }

    final letter = await _askForLetter();
    if (letter == null || letter.isEmpty) return;
    if (GameLogic.isVowel(letter)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesli harf satın alınır (200 puan).')),
      );
      return;
    }
    final count = _logic.revealLetter(letter[0]);
    final value = int.tryParse(last.replaceAll('+', '')) ?? 0;
    if (count > 0) {
      _logic.rewardForGuess(value, count);
      final total = value * count;
      final ch = _normalizeTr(letter[0]);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Doğru: $ch x $count = +$total puan'),
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() {});
      if (_logic.isSolved) {
        _showWinDialog();
      }
    } else {
      setState(() {
        _logic.switchTurn();
      });
    }
    // Her harf denemesinden sonra tekrar spin zorunlu olsun
    _logic.lastSpin = null;
  }

  void _buyVowel() async {
    final controller = TextEditingController();
    final letter = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sesli Harf Satın Al (200)'),
        content: TextField(
          controller: controller,
          maxLength: 1,
          decoration:
              const InputDecoration(hintText: 'Bir sesli harf gir (AEIİOÖUÜ)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Satın Al'),
          ),
        ],
      ),
    );
    if (letter == null || letter.isEmpty) return;
    if (!GameLogic.isVowel(letter)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu bir sesli harf değil.')),
      );
      return;
    }
    final result = _logic.buyVowel(letter);
    if (result == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yetersiz puan (200 gerekli).')),
      );
      return;
    }
    if (result > 0) {
      setState(() {});
      if (_logic.isSolved) _showWinDialog();
    } else {
      setState(() => _logic.switchTurn());
    }
  }

  void _useJoker() {
    final letter = _logic.useJoker(_random);
    if (letter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joker kullanılamıyor.')),
      );
      return;
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Joker açtı: $letter')),
    );
    if (_logic.isSolved) _showWinDialog();
  }

  Future<void> _watchAdForExtraHint() async {
    if (_logic.isSolved) return;
    if (!_canWatchMoreHintAds()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu soru için maksimum 3 ipucu reklamı izlendi.'),
        ),
      );
      return;
    }
    if (!_hasMoreHints()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu soru için açılacak başka ipucu kalmadı.'),
        ),
      );
      return;
    }

    if (!AdMobService.instance.isRewardedAdReady(
      RewardedPlacement.wheelExtraHint,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İpucu reklamı yükleniyor, biraz sonra tekrar dene.'),
        ),
      );
      return;
    }

    final success = await AdMobService.instance.showRewardedAd(
      placement: RewardedPlacement.wheelExtraHint,
      onRewarded: () {
        final nextHint = _unlockNextHint();
        if (nextHint == null || !mounted) return;
        setState(() {
          _rewardedHintWatchCount++;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ekstra ipucu açıldı. Kalan reklam hakkı: ${_remainingHintAdCount()}',
            ),
          ),
        );
      },
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reklam tamamlanmadı. Ekstra ipucu açılamadı.'),
        ),
      );
    }
  }

  void _showBadResultOffer(String result, int previousScore) {
    String title;
    String message;
    IconData icon;

    if (result == 'İflas') {
      title = 'İflas!';
      message =
          'Puanın sıfırlandı! Reklam izleyerek puanını geri al ve tekrar çevir.';
      icon = Icons.dangerous;
    } else if (result == 'Pas') {
      title = 'Pas!';
      message = 'Tur boşa geçti! Reklam izleyerek tekrar çevir.';
      icon = Icons.skip_next;
    } else {
      title = 'Düşük Puan: $result';
      message =
          'Ödülü beğenmedin mi? Reklam izle ve daha yüksek puan için tekrar çevir!';
      icon = Icons.sentiment_dissatisfied;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: Colors.redAccent, size: 28),
            const SizedBox(width: 8),
            Flexible(child: Text(title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: WheelAdManager.instance.isRewardedReady
                    ? () async {
                        Navigator.pop(ctx);
                        final success =
                            await WheelAdManager.instance.showRewardedAd(
                          onRewarded: () {
                            if (!mounted) return;
                            if (result == 'İflas') {
                              _logic.scores[_logic.currentPlayerIndex] =
                                  previousScore;
                            }
                            _logic.lastSpin = null;
                          },
                        );
                        if (success && mounted) {
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Tekrar çevirme hakkı kazandın!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Future.delayed(const Duration(milliseconds: 500),
                              () {
                            if (mounted && !_spinning) _doSpin();
                          });
                        }
                      }
                    : null,
                icon: const Icon(Icons.play_circle_outline),
                label: Text(
                  WheelAdManager.instance.isRewardedReady
                      ? 'Reklam İzle → Tekrar Çevir'
                      : 'Reklam Yükleniyor...',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (result.startsWith('+')) {
                _showActionPopup(result);
              }
            },
            child: Text(result.startsWith('+') ? 'Devam Et' : 'Kapat'),
          ),
        ],
      ),
    );
  }

  Future<String?> _askForLetter() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Harf Tahmini'),
        content: TextField(
          controller: controller,
          maxLength: 1,
          decoration: const InputDecoration(hintText: 'Bir harf gir'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _guessWord() async {
    final isProverb = (_hintCategory ?? '').toLowerCase().contains('atasö');
    final controller = TextEditingController();
    final guess = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isProverb ? 'Cümle Tahmini' : 'Kelime Tahmini'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
              hintText: isProverb ? 'Tüm cümleyi yaz' : 'Tüm kelimeyi yaz'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Tahmin Et'),
          ),
        ],
      ),
    );
    if (guess == null || guess.isEmpty) return;
    final g = _lettersOnlyUpper(guess);
    final target = _lettersOnlyUpper(_logic.secretWord);
    if (g == target) {
      setState(() {
        for (final ch in _logic.secretWord.characters) {
          if (GameLogic._isLetter(ch))
            _logic.revealed.add(GameLogic._normalize(ch));
        }
        // Bir sonraki turda serbest spin olsun
        _logic.lastSpin = null;
      });
      _showWinDialog();
    } else {
      setState(() {
        _logic.switchTurn();
        // Tahmin denendi, tekrar spin serbest
        _logic.lastSpin = null;
      });
    }
  }

  void _showWinDialog() {
    AudioService.playWin();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Tebrikler!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${_logic.players[_logic.currentPlayerIndex]} kelimeyi bildi!'),
            const SizedBox(height: 8),
            Text('Kelime: ${_logic.secretWord}'),
            const SizedBox(height: 8),
            Text('Oturum Toplam Puanı: ' +
                (_logic.scores.isNotEmpty
                        ? _logic.scores.reduce((a, b) => a + b)
                        : 0)
                    .toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog
              // Her kelime tamamlandığında puanları kaydet
              await _saveSessionGamePoints();
              _startNextWord();
            },
            child: const Text('Devam Et'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog
              await _saveSessionGamePoints();
              try {
                final prefs = await SharedPreferences.getInstance();
                final raw = prefs.getString('user_profile');
                if (raw != null) {
                  final profile = UserProfile.fromJson(json.decode(raw));
                  if (context.mounted) {
                    Navigator.pop(
                        context, profile); // exit with updated profile
                  }
                } else {
                  if (context.mounted) Navigator.pop(context);
                }
              } catch (_) {
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Bitir'),
          ),
        ],
      ),
    );
  }

  void _startNextWord() {
    final picked = _pickFromAssets();
    final newLogic = GameLogic(
      players: List<String>.from(_logic.players),
      secretWord: picked['word']!,
    );
    // Carry over scores
    for (int i = 0; i < _logic.scores.length; i++) {
      newLogic.scores[i] = _logic.scores[i];
    }
    final hints = (json.decode(picked['hints']!) as List).cast<Map>();
    setState(() {
      _logic = newLogic;
      _hintCategory = '${hints.first['category']}';
      _hintText = '${hints.first['text']}';
      _rewardedHintWatchCount = 0;
      _logic.lastSpin = null;
      _spinning = false;
      _usedWords.add(picked['word']!);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Difficulty by grade: choose pool based on user's grade (if provided via route)
    // We expect profile passed into widget; use its grade to bias selection size implicitly via asset lists order.
    final wheel = SizedBox(
      height: min(260, MediaQuery.of(context).size.width * 0.6),
      width: min(260, MediaQuery.of(context).size.width * 0.6),
      child: AnimatedBuilder(
        animation: _rotation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotation.value,
            child: CustomPaint(
              painter: _WheelPainter(segments: _segments),
            ),
          );
        },
      ),
    );

    final pointer = Positioned(
      top: 0,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 28),
      ),
    );

    final wordBoxes = SizedBox(
      width: double.infinity,
      child: Builder(builder: (context) {
        final hasSpaces = _logic.secretWord.contains(' ');
        final maxWordWidth =
            MediaQuery.of(context).size.width - 32; // padding payı
        if (!hasSpaces) {
          // Tek kelime: tek satırda ölçekleyerek göster
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: _logic.secretWord.characters.map((ch) {
                final isLetter = GameLogic._isLetter(ch);
                final show = !isLetter ||
                    _logic.revealed.contains(GameLogic._normalize(ch));
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    width: 36,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Text(
                      show ? _normalizeTr(ch) : '_',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 1.5),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }
        // Çok kelimeli: kelimelere göre satır başı ile Wrap kullan
        final words = _logic.secretWord.split(' ');
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: words.map((word) {
            if (word.isEmpty) return const SizedBox(width: 0, height: 0);
            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWordWidth),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: word.characters.map((ch) {
                    final isLetter = GameLogic._isLetter(ch);
                    final show = !isLetter ||
                        _logic.revealed.contains(GameLogic._normalize(ch));
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Container(
                        width: 34,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Text(
                          show ? _normalizeTr(ch) : '_',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1.4),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          }).toList(),
        );
      }),
    );

    final scoreboard = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Puan Tablosu',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        FutureBuilder<SharedPreferences>(
          future: SharedPreferences.getInstance(),
          builder: (context, snap) {
            final saved = (snap.data?.getString('user_profile'));
            int totalGame = 0;
            if (saved != null) {
              try {
                final map = json.decode(saved) as Map<String, dynamic>;
                totalGame = (map['totalGamePoints'] ?? 0) as int;
              } catch (_) {}
            }
            return Text('Kayıtlı Oyun Puanı: $totalGame',
                style: const TextStyle(fontSize: 12));
          },
        ),
        const SizedBox(height: 4),
        for (int i = 0; i < _logic.players.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: i == _logic.currentPlayerIndex
                  ? Colors.orange.withOpacity(0.2)
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_logic.players[i],
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Text('${_logic.scores[i]}'),
              ],
            ),
          ),
      ],
    );

    final bool canGuessLetter =
        _logic.lastSpin != null && _logic.lastSpin!.startsWith('+');
    final bool awaitingGuess =
        _logic.lastSpin != null && _logic.lastSpin!.startsWith('+');
    final bool isProverb =
        (_hintCategory ?? '').toLowerCase().contains('atasö');
    final bool hasMoreHints = !_loading && _hasMoreHints();
    final bool canWatchHintAd =
        !_loading && hasMoreHints && _canWatchMoreHintAds();
    final controls = Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        ElevatedButton.icon(
          onPressed: (_spinning || awaitingGuess) ? null : _spinWheel,
          icon: const Icon(Icons.casino),
          label: const Text('Çarkı Çevir'),
        ),
        ElevatedButton.icon(
          onPressed: canGuessLetter ? _guessLetter : null,
          icon: const Icon(Icons.font_download),
          label: const Text('Harf Tahmin Et'),
        ),
        OutlinedButton(
          onPressed: _guessWord,
          child: Text(isProverb ? 'Cümleyi Tahmin Et' : 'Kelimeyi Tahmin Et'),
        ),
        OutlinedButton.icon(
          onPressed: _buyVowel,
          icon: const Icon(Icons.shopping_cart),
          label: const Text('Sesli (200)'),
        ),
        OutlinedButton.icon(
          onPressed: _useJoker,
          icon: const Icon(Icons.stars),
          label: const Text('Joker'),
        ),
        OutlinedButton.icon(
          onPressed: (_logic.isSolved || !canWatchHintAd)
              ? null
              : (AdMobService.instance.isRewardedAdReady(
                      RewardedPlacement.wheelExtraHint)
                  ? _watchAdForExtraHint
                  : null),
          icon: const Icon(Icons.tips_and_updates_outlined),
          label: Text(
            !hasMoreHints
                ? 'Tüm İpuçları Açıldı'
                : !_canWatchMoreHintAds()
                    ? '3/3 Reklam İpucusu Kullanıldı'
                : (AdMobService.instance.isRewardedAdReady(
                        RewardedPlacement.wheelExtraHint)
                    ? 'Reklam İzle + Ekstra İpucu (${_remainingHintAdCount()})'
                    : 'İpucu Reklamı Yükleniyor...'),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎡 ÇARKIGO!'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Bilgi',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Çarkıfelek Bilgi'),
                  content: const SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• Amaç: Gizli kelimeyi bul.'),
                        SizedBox(height: 6),
                        Text('• Adımlar:'),
                        Text('  1) Çarkı çevir. Sayı gelirse harf tahmin et.'),
                        Text(
                            '  2) Doğru harf sayısı × çarktaki puan kadar kazanırsın.'),
                        Text(
                            '  3) Pas gelirse sıra değişir (tek oyuncuda tur boşa geçer).'),
                        Text(
                            '  4) İflas gelirse puanın sıfırlanır ve sıra değişir.'),
                        SizedBox(height: 8),
                        Text('• Sesli Harf: 200 puana satın alınır.'),
                        Text(
                            '• Joker: Bir gizli harfi açar (her oyuncu 1 kez).'),
                        SizedBox(height: 8),
                        Text('• Puan Dilimleri: 100 – 2000 arasında değişir.'),
                        SizedBox(height: 8),
                        Text(
                            '• Çok kelimeli ifadeler (atasözleri) satır kırarak gösterilir.'),
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
            },
          ),
        ],
      ),
      body: _showIntro
          ? _buildInfoPage()
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;

                final centerBody = Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      )
                    else ...[
                      const SizedBox(height: 12),
                      wordBoxes,
                      const SizedBox(height: 8),
                    ],
                    if (!_loading && _hintText != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: Colors.amber.withOpacity(0.4)),
                        ),
                        child: Column(
                          children: [
                            if (_hintCategory != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _hintCategory!,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            const SizedBox(height: 2),
                            Column(
                              children: [
                                Text(
                                  _hintText!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'İpucu: ${_hintCategory ?? 'Genel'}',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            TextButton.icon(
                              onPressed: hasMoreHints
                                  ? () {
                                // Cost for next hint scales with grade: ilkokul 50, ortaokul 100, lise 150
                                int cost = 100;
                                final grade = widget.profile.grade;
                                if (grade != null) {
                                  if (grade <= 4) {
                                    cost = 50;
                                  } else if (grade <= 8) {
                                    cost = 100;
                                  } else {
                                    cost = 150;
                                  }
                                }
                                // Deduct locally from current player's score if possible; else do nothing
                                if (_logic.scores[_logic.currentPlayerIndex] <
                                    cost) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Yetersiz puan: $cost gerekir')),
                                  );
                                  return;
                                }
                                final nextHint = _unlockNextHint();
                                if (nextHint == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Bu soru için açılacak başka ipucu kalmadı.'),
                                    ),
                                  );
                                  return;
                                }
                                setState(() {
                                  _logic.scores[_logic.currentPlayerIndex] -=
                                      cost;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'İpucu açıldı (-$cost). Yeni skor: ${_logic.scores[_logic.currentPlayerIndex]}'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                                  : null,
                              icon: const Icon(Icons.tips_and_updates_outlined),
                              label: Text(
                                hasMoreHints
                                    ? 'Başka ipucu (puan düşer)'
                                    : 'Tüm ipuçları açıldı',
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    const SizedBox(height: 12),
                    if (!_loading)
                      SizedBox(
                        height:
                            min(280, MediaQuery.of(context).size.width * 0.65),
                        child: Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            wheel,
                            pointer,
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (!_loading) controls,
                    const SizedBox(height: 8),
                    if (_logic.lastSpin != null)
                      Text('Sonuç: ${_logic.lastSpin!}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: Center(
                              child: SingleChildScrollView(child: centerBody))),
                      Flexible(
                        flex: 2,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 180,
                            maxWidth: 280,
                          ),
                          padding: const EdgeInsets.all(12),
                          child: !_loading ? scoreboard : const SizedBox(),
                        ),
                      ),
                    ],
                  );
                }
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        if (!_loading) scoreboard,
                        const SizedBox(height: 8),
                        centerBody,
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: _showIntro ? null : const BannerAdWidget(),
    );
  }

  Widget _buildInfoPage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.deepPurple.shade900,
            Colors.deepPurple.shade600,
          ],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 420;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(compact ? 16 : 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '🎡 Çarkıfelek',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: compact ? 28 : 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: compact ? 16 : 24),
                      Container(
                        padding: EdgeInsets.all(compact ? 14 : 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Kurallar:\n\n• Çarkı çevir; sayı gelirse harf tahmin et.\n• Doğru harf sayısı × çark puanı kadar kazan.\n• Pas: (tek oyuncuda) tur boşa geçer.\n• İflas: puanın sıfırlanır.\n• İstersen tüm kelimeyi tahmin edebilirsin.\n• Sesli harf: 200 puan; Joker: bir harfi açar (1 kez).\n',
                          style: TextStyle(
                            fontSize: compact ? 16 : 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 32 : 64),
                      ElevatedButton(
                        onPressed: () => setState(() => _showIntro = false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.deepPurple,
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 28 : 32,
                            vertical: compact ? 14 : 16,
                          ),
                        ),
                        child: Text(
                          'Başla',
                          style: TextStyle(fontSize: compact ? 20 : 22),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _saveSessionGamePoints() async {
    if (_sessionSaved) return;
    // Tek oyuncu olduğu için tüm skor toplamı oyuncunun skoru
    final earned =
        _logic.scores.isNotEmpty ? _logic.scores.reduce((a, b) => a + b) : 0;
    if (earned <= 0) {
      _sessionSaved = true;
      return;
    }
    try {
      // Firestore'dan güncel profili al
      final profile = await UserService.getCurrentUserProfile();
      if (profile != null) {
        final newTotal = (profile.totalGamePoints ?? 0) + earned;
        final updated = profile.copyWith(
          totalGamePoints: newTotal,
          points: profile.points + earned,
        );
        await UserService.updateCurrentUserProfile(updated);

        // Aktivite logla
        await UserService.logActivity(
          activityType: 'wheel_of_fortune_completed',
          data: {'points': earned},
        );

        // Puan kaydedildiğini bildir
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('+$earned puan kaydedildi! Toplam: $newTotal'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Wheel of Fortune puan kaydetme hatası: $e');
    }
    _sessionSaved = true;
  }

  // Çark durduktan sonra açılacak popup fonksiyonu
  void _showActionPopup(String result) {
    // Sadece sayı sonuçları için popup aç (İflas ve Pas için değil)
    if (result == 'İflas' || result == 'Pas') return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Flexible(
                child: Text(
                  '🎯 Çark Sonucu: $result',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  result,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ne yapmak istiyorsun?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _guessLetter();
                  },
                  icon: const Icon(Icons.font_download),
                  label: const Text('Harf Tahmin Et'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _guessWord();
                  },
                  icon: const Icon(Icons.text_fields),
                  label: Text(
                      ((_hintCategory ?? '').toLowerCase().contains('atasö'))
                          ? 'Cümle Tahmin Et'
                          : 'Kelime Tahmin Et'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _buyVowel();
                  },
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Sesli Harf Satın Al (200 puan)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _useJoker();
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Joker Kullan (1 kez)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mevcut Puan: ${_logic.scores[_logic.currentPlayerIndex]}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('İptal'),
            ),
          ],
        );
      },
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<String> segments;
  _WheelPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = min(size.width, size.height) / 2.0;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final per = 2 * pi / segments.length;
    final paint = Paint()..style = PaintingStyle.fill;
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    for (int i = 0; i < segments.length; i++) {
      paint.color = i.isEven ? Colors.orange : Colors.amber;
      final start = i * per;
      canvas.drawArc(rect, start, per, true, paint);
      // Label
      final angle = start + per / 2;
      final offset = Offset(center.dx + (radius * 0.6) * cos(angle),
          center.dy + (radius * 0.6) * sin(angle));
      textPainter.text = TextSpan(
        text: segments[i],
        style: const TextStyle(
            fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      // Dikey yazı: -90° döndür
      canvas.rotate(-pi / 2);
      textPainter.paint(
          canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }
    // Outer ring
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = Colors.brown;
    canvas.drawCircle(center, radius, ring);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) => false;
}
