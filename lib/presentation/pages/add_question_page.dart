// ========================================
// add_question_page.dart
// Page pour ajouter de nouvelles questions à Firestore
// ========================================

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../../data/models/question_model.dart';
import '../../data/repositories/question_repository.dart';

class AddQuestionPage extends StatefulWidget {
  const AddQuestionPage({Key? key}) : super(key: key);

  @override
  State<AddQuestionPage> createState() => _AddQuestionPageState();
}

class _AddQuestionPageState extends State<AddQuestionPage> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _option1Controller = TextEditingController();
  final _option2Controller = TextEditingController();
  final _option3Controller = TextEditingController();
  final _option4Controller = TextEditingController();

  String _selectedTheme = 'Géographie';
  int _selectedDifficulty = 1;
  int _correctAnswerIndex = 0;
  bool _isLoading = false;

  final List<String> _availableThemes = [
    'Géographie',
    'Histoire',
    'Sciences',
    'Culture',
    'Sport',
    'Littérature',
  ];

  @override
  void dispose() {
    _questionController.dispose();
    _option1Controller.dispose();
    _option2Controller.dispose();
    _option3Controller.dispose();
    _option4Controller.dispose();
    super.dispose();
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    // Construire la liste des options
    List<String> options = [
      _option1Controller.text.trim(),
      _option2Controller.text.trim(),
    ];

    if (_option3Controller.text.trim().isNotEmpty) {
      options.add(_option3Controller.text.trim());
    }
    if (_option4Controller.text.trim().isNotEmpty) {
      options.add(_option4Controller.text.trim());
    }

    if (_correctAnswerIndex >= options.length) {
      _showMessage('Sélectionnez une réponse correcte valide', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    // Créer la question
    Question newQuestion = Question(
      id: '', // Auto-généré par Firestore
      questionText: _questionController.text.trim(),
      options: options,
      correctAnswer: options[_correctAnswerIndex],
      theme: _selectedTheme,
      difficulty: _selectedDifficulty,
      image: 'assets/images/placeholder.png',
      isCorrect: true,
    );

    // Sauvegarder dans Firestore
    final repository = QuestionRepository();
    String? id = await repository.addQuestion(newQuestion);

    setState(() => _isLoading = false);

    if (id != null) {
      _showMessage('✅ Question ajoutée avec succès !', isError: false);

      // Réinitialiser le formulaire
      _resetForm();

      // Retour après 1.5s
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) Navigator.pop(context, true);
      });
    } else {
      _showMessage('❌ Erreur lors de l\'ajout', isError: true);
    }
  }

  void _resetForm() {
    _questionController.clear();
    _option1Controller.clear();
    _option2Controller.clear();
    _option3Controller.clear();
    _option4Controller.clear();
    setState(() {
      _selectedTheme = 'Géographie';
      _selectedDifficulty = 1;
      _correctAnswerIndex = 0;
    });
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.correctGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBeige,
      appBar: AppBar(
        backgroundColor: AppColors.darkTeal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ajouter une Question',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkTeal),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question
              _buildLabel('Question'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _questionController,
                decoration: _buildInputDecoration(
                  'Entrez la question...',
                  Icons.help_outline,
                ),
                maxLines: 3,
                style: const TextStyle(color: AppColors.textDark),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une question';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Thème et Difficulté
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Thème'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedTheme,
                          decoration: _buildInputDecoration('', Icons.category),
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: AppColors.textDark),
                          items: _availableThemes.map((theme) {
                            return DropdownMenuItem(
                              value: theme,
                              child: Text(theme),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedTheme = value!);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Difficulté'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: _selectedDifficulty,
                          decoration: _buildInputDecoration('', Icons.speed),
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: AppColors.textDark),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('Facile')),
                            DropdownMenuItem(value: 2, child: Text('Moyen')),
                            DropdownMenuItem(value: 3, child: Text('Difficile')),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedDifficulty = value!);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Options
              _buildLabel('Options de Réponse'),
              const SizedBox(height: 8),
              const Text(
                'Cochez la réponse correcte',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),

              _buildOptionField('Option 1 *', _option1Controller, 0, true),
              _buildOptionField('Option 2 *', _option2Controller, 1, true),
              _buildOptionField('Option 3', _option3Controller, 2, false),
              _buildOptionField('Option 4', _option4Controller, 3, false),

              const SizedBox(height: 32),

              // Bouton Ajouter
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Ajouter la Question',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      prefixIcon: Icon(icon, color: AppColors.darkTeal),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkTeal, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  Widget _buildOptionField(
      String label,
      TextEditingController controller,
      int index,
      bool required,
      ) {
    final isSelected = _correctAnswerIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.correctGreen : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: label,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(color: AppColors.textDark),
                  validator: required
                      ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'Champ requis';
                    }
                    return null;
                  }
                      : null,
                ),
              ),
              Radio<int>(
                value: index,
                groupValue: _correctAnswerIndex,
                activeColor: AppColors.correctGreen,
                onChanged: (value) {
                  setState(() => _correctAnswerIndex = value!);
                },
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.correctGreen,
                  size: 20,
                ),
            ],
          ),
        ],
      ),
    );
  }
}