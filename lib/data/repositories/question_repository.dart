// ========================================
// question_repository.dart
// Repository hybride pour charger les questions
// JSON local OU Firebase Firestore
// ========================================

import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/question_model.dart';
import 'firestore_repository.dart';

class QuestionRepository {
  final FirestoreRepository _firestoreRepository = FirestoreRepository();

  // ==========================================
  // MÉTHODE PRINCIPALE
  // ==========================================

  /// Charge les questions avec stratégie intelligente :
  /// 1. Essaie Firestore d'abord
  /// 2. Si vide, charge depuis JSON local
  /// 3. Importe automatiquement JSON → Firestore
  Future<List<Question>> loadQuestions() async {
    try {
      print('📡 Tentative de chargement depuis Firestore...');

      // 1. Essayer Firestore en premier
      List<Question> firestoreQuestions = await _firestoreRepository.getAllQuestions();

      if (firestoreQuestions.isNotEmpty) {
        print(' ${firestoreQuestions.length} questions chargées depuis Firestore');
        return firestoreQuestions;
      }

      print(' Firestore vide. Chargement depuis JSON local...');

      // 2. Charger depuis JSON local
      List<Question> jsonQuestions = await loadQuestionsFromJson();

      if (jsonQuestions.isEmpty) {
        print(' Aucune question disponible dans le JSON');
        return [];
      }

      print(' ${jsonQuestions.length} questions chargées depuis JSON');

      // 3. Import automatique dans Firestore (optionnel mais recommandé)
      print(' Import automatique dans Firestore...');
      bool imported = await _firestoreRepository.importQuestions(jsonQuestions);

      if (imported) {
        print(' Questions importées dans Firestore avec succès !');
      } else {
        print('️ Échec de l\'import automatique (pas grave)');
      }

      return jsonQuestions;

    } catch (e) {
      print(' Erreur dans loadQuestions(): $e');

      // Fallback : essayer JSON en cas d'erreur Firestore
      try {
        print(' Fallback vers JSON...');
        return await loadQuestionsFromJson();
      } catch (jsonError) {
        print(' Erreur fallback JSON: $jsonError');
        return [];
      }
    }
  }

  // ==========================================
  // CHARGEMENT DEPUIS JSON LOCAL
  // ==========================================

  /// Charge les questions depuis le fichier JSON dans assets/
  Future<List<Question>> loadQuestionsFromJson() async {
    try {
      print('📦 Chargement du fichier JSON...');

      final String jsonData = await rootBundle.loadString(
        'assets/data/quizz_questions.json',
      );

      final List<dynamic> jsonList = json.decode(jsonData);

      List<Question> questions = jsonList
          .map((json) => Question.fromJson(json))
          .toList();

      print(' ${questions.length} questions décodées depuis JSON');
      return questions;

    } catch (e) {
      print(' Erreur chargement JSON: $e');
      return [];
    }
  }

  // ==========================================
  // CHARGEMENT DEPUIS FIRESTORE
  // ==========================================

  /// Charge toutes les questions depuis Firestore uniquement
  Future<List<Question>> loadQuestionsFromFirestore() async {
    try {
      return await _firestoreRepository.getAllQuestions();
    } catch (e) {
      print(' Erreur loadQuestionsFromFirestore(): $e');
      return [];
    }
  }

  /// Charge les questions par thème depuis Firestore
  Future<List<Question>> loadQuestionsByTheme(String theme) async {
    try {
      return await _firestoreRepository.getQuestionsByTheme(theme);
    } catch (e) {
      print(' Erreur loadQuestionsByTheme(): $e');
      return [];
    }
  }

  /// Charge les questions par difficulté depuis Firestore
  Future<List<Question>> loadQuestionsByDifficulty(int difficulty) async {
    try {
      return await _firestoreRepository.getQuestionsByDifficulty(difficulty);
    } catch (e) {
      print(' Erreur loadQuestionsByDifficulty(): $e');
      return [];
    }
  }

  // ==========================================
  // THÈMES
  // ==========================================

  /// Récupère tous les thèmes disponibles dans Firestore
  Future<List<String>> getAvailableThemes() async {
    try {
      return await _firestoreRepository.getAvailableThemes();
    } catch (e) {
      print(' Erreur getAvailableThemes(): $e');
      return [];
    }
  }

  // ==========================================
  // AJOUT/MODIFICATION
  // ==========================================

  /// Ajoute une nouvelle question dans Firestore
  Future<String?> addQuestion(Question question) async {
    try {
      return await _firestoreRepository.addQuestion(question);
    } catch (e) {
      print(' Erreur addQuestion(): $e');
      return null;
    }
  }

  /// Met à jour une question existante dans Firestore
  Future<bool> updateQuestion(String id, Question question) async {
    try {
      return await _firestoreRepository.updateQuestion(id, question);
    } catch (e) {
      print(' Erreur updateQuestion(): $e');
      return false;
    }
  }

  /// Supprime une question de Firestore
  Future<bool> deleteQuestion(String id) async {
    try {
      return await _firestoreRepository.deleteQuestion(id);
    } catch (e) {
      print(' Erreur deleteQuestion(): $e');
      return false;
    }
  }

  // ==========================================
  // IMPORT MASSIF
  // ==========================================

  /// Importe toutes les questions du JSON vers Firestore
  /// Utile pour initialiser la base de données
  Future<bool> importJsonToFirestore() async {
    try {
      print('📦 Import JSON → Firestore en cours...');

      // Charger depuis JSON
      List<Question> questions = await loadQuestionsFromJson();

      if (questions.isEmpty) {
        print(' Aucune question à importer');
        return false;
      }

      print(' Import de ${questions.length} questions...');

      // Importer dans Firestore
      bool success = await _firestoreRepository.importQuestions(questions);

      if (success) {
        print(' ${questions.length} questions importées avec succès !');
      } else {
        print(' Échec de l\'import');
      }

      return success;

    } catch (e) {
      print(' Erreur importJsonToFirestore(): $e');
      return false;
    }
  }

  // ==========================================
  // UTILITAIRES
  // ==========================================

  /// Vérifie si Firestore contient des questions
  Future<bool> hasFirestoreQuestions() async {
    try {
      return await _firestoreRepository.hasQuestions();
    } catch (e) {
      print(' Erreur hasFirestoreQuestions(): $e');
      return false;
    }
  }

  /// Compte le nombre total de questions dans Firestore
  Future<int> getQuestionsCount() async {
    try {
      return await _firestoreRepository.getQuestionsCount();
    } catch (e) {
      print(' Erreur getQuestionsCount(): $e');
      return 0;
    }
  }

  /// Réinitialise Firestore en supprimant toutes les questions
  /// ⚠️ ATTENTION : Opération irréversible !
  Future<bool> clearAllQuestions() async {
    try {
      print('⚠️ Suppression de toutes les questions...');

      List<Question> allQuestions = await _firestoreRepository.getAllQuestions();

      for (Question question in allQuestions) {
        await _firestoreRepository.deleteQuestion(question.id);
      }

      print(' ${allQuestions.length} questions supprimées');
      return true;

    } catch (e) {
      print(' Erreur clearAllQuestions(): $e');
      return false;
    }
  }

  // ==========================================
  // STREAMS (TEMPS RÉEL)
  // ==========================================

  /// Stream de toutes les questions (temps réel)
  Stream<List<Question>> questionsStream() {
    return _firestoreRepository.questionsStream();
  }

  /// Stream des questions par thème (temps réel)
  Stream<List<Question>> questionsByThemeStream(String theme) {
    return _firestoreRepository.questionsByThemeStream(theme);
  }

  // ==========================================
  // FILTRAGE AVANCÉ
  // ==========================================

  /// Charge questions avec filtres multiples
  Future<List<Question>> loadQuestionsWithFilters({
    String? theme,
    int? difficulty,
    int? limit,
  }) async {
    try {
      print('🔍 Chargement avec filtres: theme=$theme, difficulty=$difficulty, limit=$limit');

      List<Question> questions = await _firestoreRepository.getAllQuestions();

      // Filtrer par thème
      if (theme != null) {
        questions = questions.where((q) => q.theme == theme).toList();
      }

      // Filtrer par difficulté
      if (difficulty != null) {
        questions = questions.where((q) => q.difficulty == difficulty).toList();
      }

      // Limiter le nombre
      if (limit != null && limit > 0) {
        questions = questions.take(limit).toList();
      }

      print(' ${questions.length} questions après filtrage');
      return questions;

    } catch (e) {
      print(' Erreur loadQuestionsWithFilters(): $e');
      return [];
    }
  }

  /// Charge des questions aléatoires
  Future<List<Question>> loadRandomQuestions(int count) async {
    try {
      List<Question> allQuestions = await _firestoreRepository.getAllQuestions();

      if (allQuestions.isEmpty) {
        return [];
      }

      allQuestions.shuffle();
      return allQuestions.take(count).toList();

    } catch (e) {
      print(' Erreur loadRandomQuestions(): $e');
      return [];
    }
  }

  // ==========================================
  // STATISTIQUES
  // ==========================================

  /// Obtient des statistiques sur les questions
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      List<Question> questions = await _firestoreRepository.getAllQuestions();
      List<String> themes = await _firestoreRepository.getAvailableThemes();

      return {
        'totalQuestions': questions.length,
        'totalThemes': themes.length,
        'themes': themes,
        'difficultyBreakdown': {
          'easy': questions.where((q) => q.difficulty == 1).length,
          'medium': questions.where((q) => q.difficulty == 2).length,
          'hard': questions.where((q) => q.difficulty == 3).length,
        },
      };

    } catch (e) {
      print(' Erreur getStatistics(): $e');
      return {};
    }
  }
}