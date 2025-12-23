// ========================================
// quiz_event.dart
// Événements BLoC pour le Quiz
// ========================================

import 'package:equatable/equatable.dart';
import '../../data/models/question_model.dart';

abstract class QuizEvent extends Equatable {
  const QuizEvent();

  @override
  List<Object?> get props => [];
}

// Événement : Initialiser le quiz
class InitQuizEvent extends QuizEvent {
  final List<Question> questions;
  final String userName;

  const InitQuizEvent({
    required this.questions,
    required this.userName,
  });

  @override
  List<Object?> get props => [questions, userName];
}

// Événement : Sélectionner une réponse
class SelectAnswerEvent extends QuizEvent {
  final String answer;

  const SelectAnswerEvent(this.answer);

  @override
  List<Object?> get props => [answer];
}

// Événement : Passer à la question suivante
class NextQuestionEvent extends QuizEvent {
  const NextQuestionEvent();
}

// Événement : Décrémenter le timer
class DecrementTimerEvent extends QuizEvent {
  const DecrementTimerEvent();
}

// Événement : Démarrer le timer
class StartTimerEvent extends QuizEvent {
  const StartTimerEvent();
}

// Événement : Arrêter le timer
class StopTimerEvent extends QuizEvent {
  const StopTimerEvent();
}

// Événement : Réinitialiser le quiz
class ResetQuizEvent extends QuizEvent {
  const ResetQuizEvent();
}

// Événement : Timer expiré (temps écoulé)
class TimerExpiredEvent extends QuizEvent {
  const TimerExpiredEvent();
}