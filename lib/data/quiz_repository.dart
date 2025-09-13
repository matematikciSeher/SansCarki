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
    final snap = await FirebaseFirestore.instance.collection(collectionName).get();
    return snap.docs.map(_fromDoc).toList();
  }

  static Future<List<QuizQuestion>> fetchByCategory(QuizCategory category) {
    return FirebaseFirestore.instance
        .collection(collectionName)
        .where('category', isEqualTo: category.toString())
        .get()
        .then((s) => s.docs.map(_fromDoc).toList());
  }

  static Future<List<QuizQuestion>> fetchRandom({
    QuizCategory? category,
    int count = 10,
  }) async {
    List<QuizQuestion> list;
    if (category != null) {
      list = await fetchByCategory(category);
    } else {
      list = await fetchAll();
    }
    list.shuffle();
    return list.take(count).toList();
  }
}
