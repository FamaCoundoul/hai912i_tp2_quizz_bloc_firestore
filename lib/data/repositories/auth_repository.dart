// ========================================
// auth_repository.dart
// Repository pour Firebase Authentication
// ========================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'analytics_repository.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsRepository _analyticsRepository = AnalyticsRepository();

  // Stream de l'utilisateur connecté
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Utilisateur actuel
  User? get currentUser => _auth.currentUser;

  // Vérifie si connecté
  bool get isSignedIn => _auth.currentUser != null;

  // ==========================================
  // INSCRIPTION
  // ==========================================

  Future<AppUser?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      print('📝 Inscription de $displayName...');

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        AppUser appUser = AppUser(
          uid: user.uid,
          email: email,
          displayName: displayName,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(appUser.toFirestore());

        // ✅ CORRIGÉ : Logger APRÈS la création
        await _analyticsRepository.logSignUp('email');
        await _analyticsRepository.setUserId(user.uid);

        print('✅ Utilisateur créé: $displayName');
        return appUser;
      }
    } on FirebaseAuthException catch (e) {
      print('❌ Erreur Auth: ${e.code}');
      rethrow;
    } catch (e) {
      print('❌ Erreur inscription: $e');
      rethrow;
    }
    return null;
  }

  // ==========================================
  // CONNEXION
  // ==========================================

  Future<AppUser?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Connexion de $email...');

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        // ✅ CORRIGÉ : Logger APRÈS la connexion
        await _analyticsRepository.logLogin('email');
        await _analyticsRepository.setUserId(user.uid);

        print('✅ Connexion réussie');
        return await getUserData(user.uid);
      }
    } on FirebaseAuthException catch (e) {
      print('❌ Erreur Auth: ${e.code}');
      rethrow;
    } catch (e) {
      print('❌ Erreur connexion: $e');
      rethrow;
    }
    return null;
  }

  // ==========================================
  // DÉCONNEXION
  // ==========================================

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('👋 Déconnexion réussie');
    } catch (e) {
      print('❌ Erreur déconnexion: $e');
      rethrow;
    }
  }

  // ==========================================
  // DONNÉES UTILISATEUR
  // ==========================================

  Future<AppUser?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
    } catch (e) {
      print('❌ Erreur récupération user: $e');
    }
    return null;
  }

  Future<AppUser?> getCurrentUserData() async {
    if (currentUser == null) return null;
    return await getUserData(currentUser!.uid);
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
      print('✅ Profil mis à jour');
    } catch (e) {
      print('❌ Erreur mise à jour: $e');
      rethrow;
    }
  }

  Future<void> updateAvatar(String uid, String avatarUrl) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .update({'avatarUrl': avatarUrl});
      print('✅ Avatar mis à jour');
    } catch (e) {
      print('❌ Erreur avatar: $e');
      rethrow;
    }
  }

  // ==========================================
  // SCORES
  // ==========================================

  Future<void> addScore(String uid, int score) async {
    try {
      DocumentReference userRef = _firestore.collection('users').doc(uid);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userRef);

        if (snapshot.exists) {
          int currentScore = snapshot.get('totalScore') ?? 0;
          int currentQuizzes = snapshot.get('quizzesPlayed') ?? 0;

          transaction.update(userRef, {
            'totalScore': currentScore + score,
            'quizzesPlayed': currentQuizzes + 1,
          });
        }
      });

      print('✅ Score ajouté: $score');
    } catch (e) {
      print('❌ Erreur ajout score: $e');
      rethrow;
    }
  }

  // ==========================================
  // GESTION DES ERREURS
  // ==========================================

  String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'weak-password':
          return 'Mot de passe trop faible (min 6 caractères)';
        case 'email-already-in-use':
          return 'Cet email est déjà utilisé';
        case 'user-not-found':
          return 'Aucun utilisateur trouvé avec cet email';
        case 'wrong-password':
          return 'Mot de passe incorrect';
        case 'invalid-email':
          return 'Email invalide';
        case 'user-disabled':
          return 'Ce compte a été désactivé';
        case 'too-many-requests':
          return 'Trop de tentatives. Réessayez plus tard';
        case 'network-request-failed':
          return 'Erreur réseau. Vérifiez votre connexion';
        default:
          return 'Erreur: ${error.message}';
      }
    }
    return 'Erreur inconnue: $error';
  }
}