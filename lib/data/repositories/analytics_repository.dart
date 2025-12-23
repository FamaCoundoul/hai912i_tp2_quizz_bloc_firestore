// ========================================
// analytics_repository.dart
// Repository pour Firebase Analytics
// ========================================

import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsRepository {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // ==========================================
  // CONFIGURATION
  // ==========================================

  /// Activer la collecte des données Analytics
  Future<void> enableAnalytics() async {
    await _analytics.setAnalyticsCollectionEnabled(true);
    print('✅ Analytics activé');
  }

  /// Définir l'ID utilisateur
  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
    print('✅ User ID défini: $userId');
  }

  // ==========================================
  // USER PROPERTIES (Question 4.3)
  // ==========================================

  /// Définir la thématique préférée de l'utilisateur (pour mode SHOOT)
  Future<void> setPreferredTheme(String theme) async {
    await _analytics.setUserProperty(
      name: 'preferred_theme',
      value: theme,
    );
    print('🎯 Thématique préférée définie: $theme');
  }

  /// Définir la difficulté préférée
  Future<void> setPreferredDifficulty(int difficulty) async {
    await _analytics.setUserProperty(
      name: 'preferred_difficulty',
      value: difficulty.toString(),
    );
    print('🎯 Difficulté préférée définie: $difficulty');
  }

  /// Définir le niveau de l'utilisateur (débutant, intermédiaire, expert)
  Future<void> setUserLevel(String level) async {
    await _analytics.setUserProperty(
      name: 'user_level',
      value: level,
    );
    print('🎯 Niveau utilisateur défini: $level');
  }

  // ==========================================
  // EVENTS - QUIZ (Question 4.2)
  // ==========================================

  /// Logger le début d'un quiz
  Future<void> logQuizStart({
    required String theme,
    required int difficulty,
    required int totalQuestions,
    required bool isShootMode,
  }) async {
    await _analytics.logEvent(
      name: 'quiz_start',
      parameters: {
        'theme': theme,
        'difficulty': difficulty,
        'total_questions': totalQuestions,
        'is_shoot_mode': isShootMode ? 1 : 0, // ✅ CORRIGÉ : int au lieu de bool
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    print('📊 Event: quiz_start (theme: $theme, difficulty: $difficulty)');
  }

  /// Logger la fin d'un quiz avec le score
  Future<void> logQuizComplete({
    required String theme,
    required int difficulty,
    required int score,
    required int totalQuestions,
    required int duration,
    required bool isShootMode,
  }) async {
    await _analytics.logEvent(
      name: 'quiz_complete',
      parameters: {
        'theme': theme,
        'difficulty': difficulty,
        'score': score,
        'total_questions': totalQuestions,
        'duration_seconds': duration,
        'is_shoot_mode': isShootMode ? 1 : 0, // ✅ CORRIGÉ : int au lieu de bool
        'percentage': (score / totalQuestions * 100).toInt(),
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    print('📊 Event: quiz_complete (score: $score/$totalQuestions)');
  }

  /// Logger une réponse correcte
  Future<void> logCorrectAnswer({
    required String questionTheme,
    required int difficulty,
  }) async {
    await _analytics.logEvent(
      name: 'answer_correct',
      parameters: {
        'theme': questionTheme,
        'difficulty': difficulty,
      },
    );
  }

  /// Logger une réponse incorrecte
  Future<void> logIncorrectAnswer({
    required String questionTheme,
    required int difficulty,
  }) async {
    await _analytics.logEvent(
      name: 'answer_incorrect',
      parameters: {
        'theme': questionTheme,
        'difficulty': difficulty,
      },
    );
  }

  // ==========================================
  // EVENTS - MODE SHOOT (Question 4.3)
  // ==========================================

  /// Logger l'activation du mode SHOOT
  Future<void> logShootModeActivated() async {
    await _analytics.logEvent(
      name: 'shoot_mode_activated',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    print('🚀 Event: shoot_mode_activated');
  }

  /// Logger la sélection d'une thématique préférée
  Future<void> logThemePreferenceChanged(String theme) async {
    await _analytics.logEvent(
      name: 'theme_preference_changed',
      parameters: {
        'new_theme': theme,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    print('📊 Event: theme_preference_changed ($theme)');
  }

  // ==========================================
  // EVENTS - AUTHENTIFICATION
  // ==========================================

  /// Logger une inscription
  Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
    print('📊 Event: sign_up (method: $method)');
  }

  /// Logger une connexion
  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
    print('📊 Event: login (method: $method)');
  }

  // ==========================================
  // EVENTS - PROFILE
  // ==========================================

  /// Logger l'upload d'un avatar
  Future<void> logAvatarUpload() async {
    await _analytics.logEvent(
      name: 'avatar_upload',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    print('📊 Event: avatar_upload');
  }

  /// Logger la consultation du profil
  Future<void> logProfileView() async {
    await _analytics.logEvent(
      name: 'profile_view',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    print('📊 Event: profile_view');
  }

  // ==========================================
  // EVENTS - QUESTIONS
  // ==========================================

  /// Logger l'ajout d'une question
  Future<void> logQuestionAdded({
    required String theme,
    required int difficulty,
  }) async {
    await _analytics.logEvent(
      name: 'question_added',
      parameters: {
        'theme': theme,
        'difficulty': difficulty,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    print('📊 Event: question_added (theme: $theme)');
  }

  // ==========================================
  // EVENTS - LEADERBOARD
  // ==========================================

  /// Logger la consultation du leaderboard
  Future<void> logLeaderboardView() async {
    await _analytics.logEvent(
      name: 'leaderboard_view',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    print('📊 Event: leaderboard_view');
  }

  // ==========================================
  // SCREEN TRACKING
  // ==========================================

  /// Logger la navigation vers un écran
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(
      screenName: screenName,
    );
    print('📊 Screen: $screenName');
  }

  // ==========================================
  // UTILITAIRES
  // ==========================================

  /// Calculer le niveau de l'utilisateur basé sur ses stats
  String calculateUserLevel(int totalScore, int quizzesPlayed) {
    if (quizzesPlayed == 0) return 'beginner';
    double average = totalScore / quizzesPlayed;

    if (average >= 8) return 'expert';
    if (average >= 5) return 'intermediate';
    return 'beginner';
  }
}