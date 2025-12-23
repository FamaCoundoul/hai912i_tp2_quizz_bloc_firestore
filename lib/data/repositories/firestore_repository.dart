// ========================================
// firestore_repository.dart
// Repository pour gérer les opérations Firestore
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/question_model.dart';

class FirestoreRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection principale
  static const String questionsCollection = 'questions';

  Future<void> test() async {
  await _firestore.collection('questions').get();
  }


  // ==========================================
  // LECTURE
  // ==========================================

  // Récupérer toutes les questions
  Future<List<Question>> getAllQuestions() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(questionsCollection)
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => Question.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Erreur récupération questions: $e');
      return [];
    }
  }

  // Récupérer questions par thème
  Future<List<Question>> getQuestionsByTheme(String theme) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(questionsCollection)
          .where('theme', isEqualTo: theme)
          .get();

      return snapshot.docs
          .map((doc) => Question.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Erreur: $e');
      return [];
    }
  }

  // Récupérer questions par difficulté
  Future<List<Question>> getQuestionsByDifficulty(int difficulty) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(questionsCollection)
          .where('difficulty', isEqualTo: difficulty)
          .get();

      return snapshot.docs
          .map((doc) => Question.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Erreur: $e');
      return [];
    }
  }

  // Récupérer tous les thèmes disponibles
  Future<List<String>> getAvailableThemes() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(questionsCollection)
          .get();

      Set<String> themes = {};
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['theme'] != null) {
          themes.add(data['theme'] as String);
        }
      }

      return themes.toList()..sort();
    } catch (e) {
      print(' Erreur récupération thèmes: $e');
      return [];
    }
  }

  /// Charge les questions depuis Firestore
  Future<List<String>> loadQuestions() async {
    final snapshot = await _firestore.collection('questions').get();

    return snapshot.docs
        .where((doc) => doc.data().containsKey('label'))
        .map((doc) => doc['label'] as String)
        .toList();
  }

  // ==========================================
  // ÉCRITURE
  // ==========================================

  // Ajouter une question
  Future<String?> addQuestion(Question question) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(questionsCollection)
          .add(question.toFirestore());

      print(' Question ajoutée avec ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print(' Erreur ajout question: $e');
      return null;
    }
  }

  // Mettre à jour une question
  Future<bool> updateQuestion(String id, Question question) async {
    try {
      await _firestore
          .collection(questionsCollection)
          .doc(id)
          .update(question.toFirestore());

      print(' Question mise à jour: $id');
      return true;
    } catch (e) {
      print(' Erreur mise à jour: $e');
      return false;
    }
  }

  // Supprimer une question
  Future<bool> deleteQuestion(String id) async {
    try {
      await _firestore
          .collection(questionsCollection)
          .doc(id)
          .delete();

      print(' Question supprimée: $id');
      return true;
    } catch (e) {
      print(' Erreur suppression: $e');
      return false;
    }
  }

  // ==========================================
  // IMPORT MASSIF
  // ==========================================

  // Importer plusieurs questions en batch
  Future<bool> importQuestions(List<Question> questions) async {
    try {
      WriteBatch batch = _firestore.batch();

      for (Question question in questions) {
        DocumentReference docRef = _firestore
            .collection(questionsCollection)
            .doc();

        batch.set(docRef, question.toFirestore());
      }

      await batch.commit();

      print(' ${questions.length} questions importées avec succès !');
      return true;
    } catch (e) {
      print(' Erreur import batch: $e');
      return false;
    }
  }

  // ==========================================
  // STREAMS (TEMPS RÉEL)
  // ==========================================

  // Stream de toutes les questions
  Stream<List<Question>> questionsStream() {
    return _firestore
        .collection(questionsCollection)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Question.fromFirestore(doc))
        .toList());
  }

  // Stream des questions par thème
  Stream<List<Question>> questionsByThemeStream(String theme) {
    return _firestore
        .collection(questionsCollection)
        .where('theme', isEqualTo: theme)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Question.fromFirestore(doc))
        .toList());
  }

  // ==========================================
  // UTILITAIRES
  // ==========================================

  // Compter les questions
  Future<int> getQuestionsCount() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(questionsCollection)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print(' Erreur comptage: $e');
      return 0;
    }
  }

  // Vérifier si des questions existent
  Future<bool> hasQuestions() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(questionsCollection)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print(' Erreur vérification: $e');
      return false;
    }
  }
}