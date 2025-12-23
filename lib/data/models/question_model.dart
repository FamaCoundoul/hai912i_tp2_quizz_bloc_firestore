// ========================================
// question_model.dart
// Modèle de données pour les questions avec support Firestore
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';

class Question {
  final String id;
  final String questionText;
  final bool isCorrect;
  final String theme;
  final int difficulty;
  final String image;
  final List<String> options;
  final String correctAnswer;

  Question({
    required this.id,
    required this.questionText,
    required this.isCorrect,
    required this.theme,
    required this.difficulty,
    required this.image,
    required this.options,
    required this.correctAnswer,
  });

  // Factory depuis JSON (pour import initial)
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? '',
      questionText: json['questionText'] ?? '',
      isCorrect: json['isCorrect'] ?? true,
      theme: json['theme'] ?? '',
      difficulty: json['difficulty'] ?? 1,
      image: json['image'] != null
          ? json['image']!.replaceFirst('./', 'assets/')
          : 'assets/images/placeholder.png',
      options: json['options'] != null
          ? List<String>.from(json['options'])
          : [],
      correctAnswer: json['correctAnswer'] ?? '',
    );
  }

  // Factory depuis Firestore
  factory Question.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Question(
      id: doc.id,
      questionText: data['questionText'] ?? '',
      isCorrect: data['isCorrect'] ?? true,
      theme: data['theme'] ?? '',
      difficulty: data['difficulty'] ?? 1,
      image: data['image'] ?? 'assets/images/placeholder.png',
      options: List<String>.from(data['options'] ?? []),
      correctAnswer: data['correctAnswer'] ?? '',
    );
  }

  // Convertir vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'questionText': questionText,
      'isCorrect': isCorrect,
      'theme': theme,
      'difficulty': difficulty,
      'image': image,
      'options': options,
      'correctAnswer': correctAnswer,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Convertir vers Map (pour affichage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionText': questionText,
      'isCorrect': isCorrect,
      'theme': theme,
      'difficulty': difficulty,
      'image': image,
      'options': options,
      'correctAnswer': correctAnswer,
    };
  }
}