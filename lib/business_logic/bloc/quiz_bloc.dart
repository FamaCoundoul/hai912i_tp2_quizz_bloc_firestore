// ========================================
// quiz_bloc.dart
// BLoC principal pour la gestion du Quiz
// ========================================

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'quiz_event.dart';
import 'quiz_state.dart';

class QuizBloc extends Bloc<QuizEvent, QuizState> {
  Timer? _timer;

  QuizBloc() : super(const QuizInitial()) {
    // Enregistrer les handlers pour chaque événement
    on<InitQuizEvent>(_onInitQuiz);
    on<SelectAnswerEvent>(_onSelectAnswer);
    on<NextQuestionEvent>(_onNextQuestion);
    on<DecrementTimerEvent>(_onDecrementTimer);
    on<StartTimerEvent>(_onStartTimer);
    on<StopTimerEvent>(_onStopTimer);
    on<ResetQuizEvent>(_onResetQuiz);
    on<TimerExpiredEvent>(_onTimerExpired);
  }

  // Handler : Initialiser le quiz
  Future<void> _onInitQuiz(
      InitQuizEvent event,
      Emitter<QuizState> emit,
      ) async {
    try {
      if (event.questions.isEmpty) {
        emit(const QuizError('Aucune question disponible'));
        return;
      }

      emit(QuizInProgress(
        questions: event.questions,
        currentQuestionIndex: 0,
        score: 0,
        selectedAnswer: null,
        timeRemaining: 30,
        isTimerRunning: true,
        userName: event.userName,
      ));

      // Démarrer le timer automatiquement
      _startTimerInternal();
    } catch (e) {
      emit(QuizError('Erreur lors de l\'initialisation: $e'));
    }
  }

  // Handler : Sélectionner une réponse
  Future<void> _onSelectAnswer(
      SelectAnswerEvent event,
      Emitter<QuizState> emit,
      ) async {
    if (state is! QuizInProgress) return;

    final currentState = state as QuizInProgress;

    // Si une réponse est déjà sélectionnée, ignorer
    if (currentState.selectedAnswer != null) return;

    // Vérifier si la réponse est correcte
    final currentQuestion = currentState.currentQuestion;
    if (currentQuestion == null) return;

    final isCorrect = event.answer == currentQuestion.correctAnswer;
    final newScore = isCorrect ? currentState.score + 1 : currentState.score;

    // Arrêter le timer
    _stopTimerInternal();

    emit(currentState.copyWith(
      selectedAnswer: event.answer,
      score: newScore,
      isTimerRunning: false,
    ));
  }

  // Handler : Passer à la question suivante
  Future<void> _onNextQuestion(
      NextQuestionEvent event,
      Emitter<QuizState> emit,
      ) async {
    if (state is! QuizInProgress) return;

    final currentState = state as QuizInProgress;

    // Si c'est la dernière question, terminer le quiz
    if (currentState.isLastQuestion) {
      _stopTimerInternal();
      emit(QuizCompleted(
        userName: currentState.userName,
        finalScore: currentState.score,
        totalQuestions: currentState.totalQuestions,
      ));
      return;
    }

    // Passer à la question suivante
    emit(currentState.copyWith(
      currentQuestionIndex: currentState.currentQuestionIndex + 1,
      clearSelectedAnswer: true,
      timeRemaining: 30,
      isTimerRunning: true,
    ));

    // Redémarrer le timer
    _startTimerInternal();
  }

  // Handler : Décrémenter le timer
  Future<void> _onDecrementTimer(
      DecrementTimerEvent event,
      Emitter<QuizState> emit,
      ) async {
    if (state is! QuizInProgress) return;

    final currentState = state as QuizInProgress;

    if (currentState.timeRemaining > 0 && currentState.selectedAnswer == null) {
      emit(currentState.copyWith(
        timeRemaining: currentState.timeRemaining - 1,
      ));

      // Si le temps est écoulé, ajouter l'événement TimerExpired
      if (currentState.timeRemaining - 1 == 0) {
        add(const TimerExpiredEvent());
      }
    }
  }

  // Handler : Démarrer le timer
  Future<void> _onStartTimer(
      StartTimerEvent event,
      Emitter<QuizState> emit,
      ) async {
    _startTimerInternal();
  }

  // Handler : Arrêter le timer
  Future<void> _onStopTimer(
      StopTimerEvent event,
      Emitter<QuizState> emit,
      ) async {
    _stopTimerInternal();
  }

  // Handler : Réinitialiser le quiz
  Future<void> _onResetQuiz(
      ResetQuizEvent event,
      Emitter<QuizState> emit,
      ) async {
    _stopTimerInternal();
    emit(const QuizInitial());
  }

  // Handler : Timer expiré
  Future<void> _onTimerExpired(
      TimerExpiredEvent event,
      Emitter<QuizState> emit,
      ) async {
    if (state is! QuizInProgress) return;

    final currentState = state as QuizInProgress;

    // Si aucune réponse n'a été sélectionnée, passer automatiquement
    if (currentState.selectedAnswer == null) {
      add(const NextQuestionEvent());
    }
  }

  // Méthode privée : Démarrer le timer
  void _startTimerInternal() {
    _stopTimerInternal(); // Arrêter le timer existant si présent

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state is QuizInProgress) {
        final currentState = state as QuizInProgress;
        if (currentState.isTimerRunning && currentState.timeRemaining > 0) {
          add(const DecrementTimerEvent());
        }
      }
    });
  }

  // Méthode privée : Arrêter le timer
  void _stopTimerInternal() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<void> close() {
    _stopTimerInternal();
    return super.close();
  }
}