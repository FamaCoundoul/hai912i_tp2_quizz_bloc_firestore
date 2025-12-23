// ========================================
// quiz_state.dart
// États BLoC pour le Quiz
// ========================================

import 'package:equatable/equatable.dart';
import '../../data/models/question_model.dart';

abstract class QuizState extends Equatable {
  const QuizState();

  @override
  List<Object?> get props => [];
}

// État initial
class QuizInitial extends QuizState {
  const QuizInitial();
}

// État : Quiz en cours
class QuizInProgress extends QuizState {
  final List<Question> questions;
  final int currentQuestionIndex;
  final int score;
  final String? selectedAnswer;
  final int timeRemaining;
  final bool isTimerRunning;
  final String userName;

  const QuizInProgress({
    required this.questions,
    required this.currentQuestionIndex,
    required this.score,
    this.selectedAnswer,
    required this.timeRemaining,
    required this.isTimerRunning,
    required this.userName,
  });

  // Getters pratiques
  Question? get currentQuestion {
    if (questions.isEmpty || currentQuestionIndex >= questions.length) {
      return null;
    }
    return questions[currentQuestionIndex];
  }

  int get totalQuestions => questions.length;

  bool get isLastQuestion => currentQuestionIndex >= questions.length - 1;

  // Méthode copyWith pour créer un nouvel état avec certains champs modifiés
  QuizInProgress copyWith({
    List<Question>? questions,
    int? currentQuestionIndex,
    int? score,
    String? selectedAnswer,
    int? timeRemaining,
    bool? isTimerRunning,
    String? userName,
    bool clearSelectedAnswer = false,
  }) {
    return QuizInProgress(
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      score: score ?? this.score,
      selectedAnswer: clearSelectedAnswer ? null : (selectedAnswer ?? this.selectedAnswer),
      timeRemaining: timeRemaining ?? this.timeRemaining,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
      userName: userName ?? this.userName,
    );
  }

  @override
  List<Object?> get props => [
    questions,
    currentQuestionIndex,
    score,
    selectedAnswer,
    timeRemaining,
    isTimerRunning,
    userName,
  ];
}

// État : Quiz terminé
class QuizCompleted extends QuizState {
  final String userName;
  final int finalScore;
  final int totalQuestions;

  const QuizCompleted({
    required this.userName,
    required this.finalScore,
    required this.totalQuestions,
  });

  @override
  List<Object?> get props => [userName, finalScore, totalQuestions];
}

// État : Erreur
class QuizError extends QuizState {
  final String message;

  const QuizError(this.message);

  @override
  List<Object?> get props => [message];
}