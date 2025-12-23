// ========================================
// welcome_page_realtime.dart
// Page d'accueil avec MODE SHOOT (Question 4.3)
// ========================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../business_logic/bloc/quiz_bloc.dart';
import '../../business_logic/bloc/quiz_event.dart';
import '../../data/models/question_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/question_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/analytics_repository.dart';
import '../constants/app_colors.dart';
import 'quizz_page.dart';
import 'add_question_page.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';

class WelcomePageRealtime extends StatefulWidget {
  const WelcomePageRealtime({Key? key}) : super(key: key);

  @override
  State<WelcomePageRealtime> createState() => _WelcomePageRealtimeState();
}

class _WelcomePageRealtimeState extends State<WelcomePageRealtime> {
  final TextEditingController _nameController = TextEditingController();
  final QuestionRepository _questionRepository = QuestionRepository();
  final AuthRepository _authRepository = AuthRepository();
  final AnalyticsRepository _analyticsRepository = AnalyticsRepository();

  List<Question> _currentQuestions = [];
  bool _isInitializing = true;
  String? _errorMessage;
  AppUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _initializeQuestions();
    _loadUserData();
    _initializeAnalytics();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _initializeAnalytics() async {
    await _analyticsRepository.enableAnalytics();
    await _analyticsRepository.logScreenView('welcome_page');
  }

  Future<void> _loadUserData() async {
    try {
      AppUser? user = await _authRepository.getCurrentUserData();
      if (user != null && mounted) {
        setState(() {
          _currentUser = user;
          _nameController.text = user.displayName;
        });

        // Définir l'ID utilisateur dans Analytics
        await _analyticsRepository.setUserId(user.uid);

        // Définir le niveau de l'utilisateur
        String level = _analyticsRepository.calculateUserLevel(
          user.totalScore,
          user.quizzesPlayed,
        );
        await _analyticsRepository.setUserLevel(level);

        print('✅ Utilisateur connecté: ${user.displayName} (niveau: $level)');
      }
    } catch (e) {
      print('⚠️ Pas d\'utilisateur connecté');
    }
  }

  Future<void> _initializeQuestions() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      bool hasQuestions = await _questionRepository.hasFirestoreQuestions();

      if (!hasQuestions) {
        bool imported = await _questionRepository.importJsonToFirestore();
        if (!imported) {
          setState(() {
            _errorMessage = 'Impossible d\'importer les questions';
          });
        }
      }

      List<Question> questions = await _questionRepository.loadQuestionsFromFirestore();

      setState(() {
        _currentQuestions = questions;
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de chargement: $e';
        _isInitializing = false;
      });
    }
  }

  Future<void> _reloadQuestions() async {
    try {
      List<Question> questions = await _questionRepository.loadQuestionsFromFirestore();
      setState(() => _currentQuestions = questions);
    } catch (e) {
      print('❌ Erreur rechargement: $e');
    }
  }

  // ✅ MODE SHOOT (Question 4.3)
  Future<void> _startShootMode() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Entrez votre nom'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      // Charger les préférences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? preferredTheme = prefs.getString('preferred_theme');
      int? preferredDifficulty = prefs.getInt('preferred_difficulty');

      if (preferredTheme == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('⚠️ Définissez vos préférences d\'abord'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Paramètres',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
            ),
          ),
        );
        return;
      }

      // Charger les questions selon les préférences
      List<Question> filteredQuestions = await _questionRepository.loadQuestionsWithFilters(
        theme: preferredTheme,
        difficulty: preferredDifficulty,
        limit: 10,
      );

      if (filteredQuestions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Aucune question disponible pour "$preferredTheme"'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Logger l'activation du mode SHOOT
      await _analyticsRepository.logShootModeActivated();
      await _analyticsRepository.logQuizStart(
        theme: preferredTheme,
        difficulty: preferredDifficulty ?? 2,
        totalQuestions: filteredQuestions.length,
        isShootMode: true,
      );

      // Lancer le quiz
      context.read<QuizBloc>().add(
        InitQuizEvent(
          questions: filteredQuestions,
          userName: _nameController.text.trim(),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: context.read<QuizBloc>(),
            child: const QuizPageBloc(),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _startQuiz() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Entrez votre nom'), backgroundColor: Colors.orange),
      );
      return;
    }

    await _reloadQuestions();

    if (_currentQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Aucune question disponible'), backgroundColor: Colors.red),
      );
      return;
    }

    // Logger le démarrage du quiz normal
    await _analyticsRepository.logQuizStart(
      theme: 'Mixte',
      difficulty: 2,
      totalQuestions: _currentQuestions.length,
      isShootMode: false,
    );

    context.read<QuizBloc>().add(
      InitQuizEvent(questions: _currentQuestions, userName: _nameController.text.trim()),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<QuizBloc>(),
          child: const QuizPageBloc(),
        ),
      ),
    );
  }

  Future<void> _goToAddQuestion() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddQuestionPage()),
    );
    await _reloadQuestions();
  }

  Future<void> _goToSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
  }

  Future<void> _logout() async {
    await _authRepository.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isUserConnected = _currentUser != null;

    return Scaffold(
      backgroundColor: AppColors.darkTeal,
      body: SafeArea(
        child: Column(
          children: [
            // Header avec boutons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Bouton Paramètres (Mode SHOOT)
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white, size: 28),
                    onPressed: _goToSettings,
                    tooltip: 'Paramètres Mode SHOOT',
                  ),

                  // Boutons Profil/Login
                  Row(
                    children: [
                      if (isUserConnected) ...[
                        IconButton(
                          icon: const Icon(Icons.person, color: Colors.white, size: 28),
                          onPressed: () async {
                            await _analyticsRepository.logProfileView();
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ProfilePage()),
                            );
                            await _loadUserData();
                          },
                          tooltip: 'Mon Profil',
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout,color: Colors.white, size: 28),
                          onPressed: _logout,
                          tooltip: 'Déconnexion',
                        ),
                      ] else ...[
                        IconButton(
                          icon: const Icon(Icons.login, color: Colors.white, size: 28),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginPage()),
                            );
                            await _loadUserData();
                          },
                          tooltip: 'Se connecter',
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isInitializing
                  ? _buildLoadingState()
                  : _errorMessage != null
                  ? _buildErrorState()
                  : _buildMainContent(isUserConnected),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
          SizedBox(height: 24),
          Text('Initialisation...', style: TextStyle(color: Colors.white, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage ?? 'Erreur', style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeQuestions,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentYellow),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(bool isUserConnected) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Center(
                child: Text('QUIZ', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.darkTeal, letterSpacing: 2)),
              ),
            ),

            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _currentQuestions.isEmpty ? Colors.red.withOpacity(0.3) : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _currentQuestions.isEmpty ? Colors.red.shade300 : Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _currentQuestions.isEmpty ? Icons.warning_amber : Icons.question_answer,
                    color: _currentQuestions.isEmpty ? Colors.red.shade200 : AppColors.accentYellow,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _currentQuestions.isEmpty ? 'Aucune question' : '${_currentQuestions.length} question${_currentQuestions.length > 1 ? 's' : ''}',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Champ nom
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Text(
                    'Enter your name',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  if (isUserConnected)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.lock, color: AppColors.accentYellow, size: 16),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              enabled: !isUserConnected,
              style: TextStyle(color: isUserConnected ? Colors.white70 : Colors.white),
              decoration: InputDecoration(
                hintText: 'BIENVENUE',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                filled: true,
                fillColor: isUserConnected
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.1),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.accentYellow.withOpacity(0.5), width: 2)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accentYellow, width: 2)),
              ),
            ),

            const SizedBox(height: 30),

            // ✅ BOUTON MODE SHOOT (Question 4.3)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _currentQuestions.isEmpty ? null : _startShootMode,
                icon: const Icon(Icons.flash_on, size: 24),
                label: const Text('MODE SHOOT 🚀', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentYellow,
                  foregroundColor: AppColors.darkTeal,
                  disabledBackgroundColor: Colors.grey.shade600,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _goToAddQuestion,
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text('Ajouter Questions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mediumTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _currentQuestions.isEmpty ? null : _startQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.darkTeal,
                  disabledBackgroundColor: Colors.grey.shade600,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Start Quiz Normal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}