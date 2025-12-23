// ========================================
// settings_page.dart
// Page de paramètres pour définir la thématique préférée (mode SHOOT)
// ========================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../../data/repositories/analytics_repository.dart';
import '../../data/repositories/question_repository.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AnalyticsRepository _analyticsRepository = AnalyticsRepository();
  final QuestionRepository _questionRepository = QuestionRepository();

  String? _selectedTheme;
  int _selectedDifficulty = 2;
  List<String> _availableThemes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      // Charger les thèmes disponibles
      List<String> themes = await _questionRepository.getAvailableThemes();

      // Charger les préférences sauvegardées
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedTheme = prefs.getString('preferred_theme');
      int? savedDifficulty = prefs.getInt('preferred_difficulty');

      setState(() {
        _availableThemes = themes;
        _selectedTheme = savedTheme ?? (themes.isNotEmpty ? themes[0] : null);
        _selectedDifficulty = savedDifficulty ?? 2;
        _isLoading = false;
      });

      print('✅ Thèmes chargés: $_availableThemes');
      print('✅ Préférences: theme=$_selectedTheme, difficulty=$_selectedDifficulty');
    } catch (e) {
      print('❌ Erreur chargement paramètres: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    if (_selectedTheme == null) {
      _showMessage('⚠️ Choisissez une thématique', isError: true);
      return;
    }

    try {
      // Sauvegarder en local
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('preferred_theme', _selectedTheme!);
      await prefs.setInt('preferred_difficulty', _selectedDifficulty);

      // Enregistrer dans Analytics (Question 4.3)
      await _analyticsRepository.setPreferredTheme(_selectedTheme!);
      await _analyticsRepository.setPreferredDifficulty(_selectedDifficulty);
      await _analyticsRepository.logThemePreferenceChanged(_selectedTheme!);

      _showMessage('✅ Préférences sauvegardées !', isError: false);
      print('✅ Préférences sauvegardées: $_selectedTheme (difficulté: $_selectedDifficulty)');
    } catch (e) {
      _showMessage('❌ Erreur sauvegarde: $e', isError: true);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.incorrectRed : AppColors.correctGreen,
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
        title: const Text(
          'Paramètres Mode SHOOT',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColors.darkTeal),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Mode SHOOT
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accentYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accentYellow),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flash_on, color: AppColors.accentYellow, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Mode SHOOT 🚀',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Lancez un quiz instantané avec vos préférences !',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Thématique Préférée
            const Text(
              'Thématique Préférée',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cette thématique sera utilisée en mode SHOOT',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            if (_availableThemes.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Text(
                  '⚠️ Aucune thématique disponible. Ajoutez des questions d\'abord !',
                  style: TextStyle(color: Colors.orange),
                ),
              )
            else
              ...(_availableThemes.map((theme) {
                final isSelected = _selectedTheme == theme;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => setState(() => _selectedTheme = theme),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.darkTeal : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.darkTeal : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getThemeIcon(theme),
                            color: isSelected ? Colors.white : AppColors.darkTeal,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              theme,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : AppColors.textDark,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                );
              })),

            const SizedBox(height: 32),

            // Difficulté Préférée
            const Text(
              'Difficulté Préférée',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),

            _buildDifficultyOption(1, 'Facile', '😊', Colors.green),
            _buildDifficultyOption(2, 'Moyen', '😐', Colors.orange),
            _buildDifficultyOption(3, 'Difficile', '😰', Colors.red),

            const SizedBox(height: 40),

            // Bouton Sauvegarder
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _savePreferences,
                icon: const Icon(Icons.save),
                label: const Text(
                  'Sauvegarder les Préférences',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(int level, String label, String emoji, Color color) {
    final isSelected = _selectedDifficulty == level;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => _selectedDifficulty = level),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? color : AppColors.textDark,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: color),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getThemeIcon(String theme) {
    switch (theme.toLowerCase()) {
      case 'géographie':
        return Icons.public;
      case 'histoire':
        return Icons.history_edu;
      case 'sciences':
        return Icons.science;
      case 'culture':
        return Icons.palette;
      case 'sport':
        return Icons.sports_soccer;
      case 'littérature':
        return Icons.menu_book;
      default:
        return Icons.category;
    }
  }
}