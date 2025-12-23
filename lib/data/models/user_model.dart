// ========================================
// user_model.dart
// Modèle de données pour les utilisateurs
// ========================================

import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final int totalScore;
  final int quizzesPlayed;
  final DateTime? createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.totalScore = 0,
    this.quizzesPlayed = 0,
    this.createdAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      avatarUrl: data['avatarUrl'],
      totalScore: data['totalScore'] ?? 0,
      quizzesPlayed: data['quizzesPlayed'] ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'totalScore': totalScore,
      'quizzesPlayed': quizzesPlayed,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? avatarUrl,
    int? totalScore,
    int? quizzesPlayed,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      totalScore: totalScore ?? this.totalScore,
      quizzesPlayed: quizzesPlayed ?? this.quizzesPlayed,
      createdAt: createdAt,
    );
  }

  double get averageScore => quizzesPlayed == 0 ? 0.0 : totalScore / quizzesPlayed;
}