import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quiz.dart';

class QuizRepository {
  QuizRepository._();

  static const String collectionName = 'quiz_questions';

  static QuizQuestion _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return QuizQuestion.fromJson({
      'id': data['id'] ?? doc.id,
      'question': data['question'],
      'options': data['options'],
      'correctAnswerIndex': data['correctAnswerIndex'],
      'category': data['category'],
      'explanation': data['explanation'],
      'basePoints': data['basePoints'],
    });
  }

  static Future<List<QuizQuestion>> fetchAll() async {
    final snap =
        await FirebaseFirestore.instance.collection(collectionName).get();
    return snap.docs.map(_fromDoc).toList();
  }

  static Future<List<QuizQuestion>> fetchByCategory(QuizCategory category) {
    return FirebaseFirestore.instance
        .collection(collectionName)
        .where('category', isEqualTo: category.toString())
        .get()
        .then((s) => s.docs.map(_fromDoc).toList());
  }

  static Stream<List<QuizQuestion>> streamAll() {
    return FirebaseFirestore.instance
        .collection(collectionName)
        .orderBy('id')
        .snapshots()
        .map((s) => s.docs.map(_fromDoc).toList());
  }

  static Future<List<QuizQuestion>> fetchRandom({
    QuizCategory? category,
    int count = 10,
    Set<String> excludeIds = const {},
  }) async {
    List<QuizQuestion> list;
    if (category != null) {
      list = await fetchByCategory(category);
    } else {
      list = await fetchAll();
    }
    // Hariç tutulanları filtrele
    if (excludeIds.isNotEmpty) {
      list = list.where((q) => !excludeIds.contains(q.id)).toList();
    }
    list.shuffle();
    if (list.length >= count) {
      return list.take(count).toList();
    }
    // Havuz yetersizse: eksik kalanları kalanlardan (exclude dahil) doldur
    final backup = await fetchAll();
    backup.shuffle();
    final usedIds = list.map((e) => e.id).toSet();
    for (final q in backup) {
      if (usedIds.contains(q.id)) continue;
      list.add(q);
      usedIds.add(q.id);
      if (list.length == count) break;
    }
    return list;
  }

  static Future<void> addQuestion(QuizQuestion question) async {
    final ref =
        FirebaseFirestore.instance.collection(collectionName).doc(question.id);
    await ref.set(question.toJson(), SetOptions(merge: true));
  }

  static Future<void> updateQuestion(QuizQuestion question) async {
    final ref =
        FirebaseFirestore.instance.collection(collectionName).doc(question.id);
    await ref.update(question.toJson());
  }

  static Future<void> deleteQuestion(String id) async {
    final ref = FirebaseFirestore.instance.collection(collectionName).doc(id);
    await ref.delete();
  }
}
