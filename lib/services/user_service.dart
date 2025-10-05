import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

/// Firebase Firestore'da kullanıcı verilerini yöneten servis
class UserService {
  UserService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String usersCollection = 'users';

  /// Mevcut kullanıcının UID'sini al
  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Kullanıcı kayıt olduğunda Firestore'a ekle
  static Future<void> createUser({
    required String uid,
    required String email,
    UserProfile? initialProfile,
  }) async {
    try {
      final profile = initialProfile ?? UserProfile();
      final data = profile.toJson();
      data['email'] = email;
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(usersCollection).doc(uid).set(data);
    } catch (e) {
      throw Exception('Kullanıcı oluşturma hatası: $e');
    }
  }

  /// Kullanıcı profilini Firestore'dan oku
  static Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection(usersCollection).doc(uid).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data();
      if (data == null) {
        return null;
      }

      return UserProfile.fromJson(data);
    } catch (e) {
      throw Exception('Kullanıcı profili okuma hatası: $e');
    }
  }

  /// Mevcut kullanıcının profilini al
  static Future<UserProfile?> getCurrentUserProfile() async {
    final uid = getCurrentUserId();
    if (uid == null) return null;
    return getUserProfile(uid);
  }

  /// Kullanıcı profilini güncelle
  static Future<void> updateUserProfile({
    required String uid,
    required UserProfile profile,
  }) async {
    try {
      final data = profile.toJson();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(usersCollection).doc(uid).update(data);
    } catch (e) {
      throw Exception('Kullanıcı profili güncelleme hatası: $e');
    }
  }

  /// Mevcut kullanıcının profilini güncelle
  static Future<void> updateCurrentUserProfile(UserProfile profile) async {
    final uid = getCurrentUserId();
    if (uid == null) throw Exception('Kullanıcı giriş yapmamış');

    await updateUserProfile(uid: uid, profile: profile);
  }

  /// Kullanıcı profilini dinle (realtime updates)
  static Stream<UserProfile?> watchUserProfile(String uid) {
    return _firestore.collection(usersCollection).doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      final data = snapshot.data();
      if (data == null) return null;
      return UserProfile.fromJson(data);
    });
  }

  /// Mevcut kullanıcının profilini dinle
  static Stream<UserProfile?> watchCurrentUserProfile() {
    final uid = getCurrentUserId();
    if (uid == null) {
      return Stream.value(null);
    }
    return watchUserProfile(uid);
  }

  /// Puan ekle
  static Future<void> addPoints(int points) async {
    final uid = getCurrentUserId();
    if (uid == null) throw Exception('Kullanıcı giriş yapmamış');

    await _firestore.collection(usersCollection).doc(uid).update({
      'points': FieldValue.increment(points),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Quiz puanı ekle
  static Future<void> addQuizPoints(int points) async {
    final uid = getCurrentUserId();
    if (uid == null) throw Exception('Kullanıcı giriş yapmamış');

    await _firestore.collection(usersCollection).doc(uid).update({
      'totalQuizPoints': FieldValue.increment(points),
      'points': FieldValue.increment(points),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Oyun puanı ekle
  static Future<void> addGamePoints(int points) async {
    final uid = getCurrentUserId();
    if (uid == null) throw Exception('Kullanıcı giriş yapmamış');

    await _firestore.collection(usersCollection).doc(uid).update({
      'totalGamePoints': FieldValue.increment(points),
      'points': FieldValue.increment(points),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Tamamlanan görev sayısını artır
  static Future<void> incrementCompletedTasks() async {
    final uid = getCurrentUserId();
    if (uid == null) throw Exception('Kullanıcı giriş yapmamış');

    await _firestore.collection(usersCollection).doc(uid).update({
      'completedTasks': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Rozet ekle
  static Future<void> addBadge(String badgeId) async {
    final uid = getCurrentUserId();
    if (uid == null) throw Exception('Kullanıcı giriş yapmamış');

    await _firestore.collection(usersCollection).doc(uid).update({
      'badges': FieldValue.arrayUnion([badgeId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Kategori istatistiğini güncelle
  static Future<void> updateCategoryStats(String category, int increment) async {
    final uid = getCurrentUserId();
    if (uid == null) throw Exception('Kullanıcı giriş yapmamış');

    await _firestore.collection(usersCollection).doc(uid).update({
      'categoryStats.$category': FieldValue.increment(increment),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Avatar puanlarını güncelle
  static Future<void> updateAvatarPoints({
    int? intelligence,
    int? strength,
    int? wisdom,
    int? creativity,
    int? social,
    int? tech,
  }) async {
    final uid = getCurrentUserId();
    if (uid == null) throw Exception('Kullanıcı giriş yapmamış');

    final Map<String, dynamic> updates = {'updatedAt': FieldValue.serverTimestamp()};

    if (intelligence != null) {
      updates['intelligencePoints'] = FieldValue.increment(intelligence);
    }
    if (strength != null) {
      updates['strengthPoints'] = FieldValue.increment(strength);
    }
    if (wisdom != null) {
      updates['wisdomPoints'] = FieldValue.increment(wisdom);
    }
    if (creativity != null) {
      updates['creativityPoints'] = FieldValue.increment(creativity);
    }
    if (social != null) {
      updates['socialPoints'] = FieldValue.increment(social);
    }
    if (tech != null) {
      updates['techPoints'] = FieldValue.increment(tech);
    }

    if (updates.length > 1) {
      await _firestore.collection(usersCollection).doc(uid).update(updates);
    }
  }

  /// Kullanıcı aktivitelerini kaydet (opsiyonel: detaylı loglama için)
  static Future<void> logActivity({
    required String activityType,
    required Map<String, dynamic> data,
  }) async {
    final uid = getCurrentUserId();
    if (uid == null) return;

    await _firestore.collection(usersCollection).doc(uid).collection('activities').add({
      'type': activityType,
      'data': data,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Kullanıcının mevcut olup olmadığını kontrol et, yoksa oluştur
  static Future<void> ensureUserExists() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection(usersCollection).doc(user.uid).get();

    if (!doc.exists) {
      // Kullanıcı Firestore'da yok, oluştur
      await createUser(
        uid: user.uid,
        email: user.email ?? '',
      );
    }
  }

  /// Kullanıcı çıkış yap
  static Future<void> signOut() async {
    await _auth.signOut();
  }
}
