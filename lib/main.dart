// ========================================
// main.dart
// Point d'entrée de l'application avec BLoC
// Version optimisée pour Firestore temps réel
// ========================================

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hai912i_tp3_quizz_bloc_firestore/presentation/pages/login_page.dart';
import 'business_logic/bloc/quiz_bloc.dart';
import 'firebase_options.dart';
import 'presentation/pages/welcome_page_realtime.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (kDebugMode) {
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  }

  print('🔥 Firebase initialisé avec succès !');

  // Plus besoin de charger les questions ici !
  // Le StreamBuilder dans WelcomePageRealtime le fait automatiquement

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Créer une instance du QuizBloc disponible dans toute l'application
      create: (context) => QuizBloc(),
      child: MaterialApp(
        title: 'Quiz App with BLoC & Firebase',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.teal,
          useMaterial3: true,
        ),
        // WelcomePageRealtime n'a pas besoin de paramètres !
        // Elle utilise son propre QuestionRepository en interne
        home: const LoginPage(),
      ),
    );
  }
}