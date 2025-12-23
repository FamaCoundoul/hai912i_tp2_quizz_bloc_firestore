// ========================================
// profile_page.dart
// Page de profil (Web & Mobile compatible)
// ========================================

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/analytics_repository.dart';
import '../constants/app_colors.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/storage_repository.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authRepository = AuthRepository();
  final _storageRepository = StorageRepository();
  final  _analyticsRepository = AnalyticsRepository();

  AppUser? currentUser;
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      AppUser? user = await _authRepository.getCurrentUserData();
      if (user != null) {
        setState(() {
          currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement profil: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadAvatar() async {
    // ✅ XFile (pas File)
    XFile? imageFile = await _storageRepository.pickImageFromGallery();

    if (imageFile == null || currentUser == null) return;

    setState(() => _isUploading = true);

    try {
      String? avatarUrl = await _storageRepository.uploadAvatar(
        currentUser!.uid,
        imageFile,
      );

      if (avatarUrl != null) {
        await _authRepository.updateAvatar(currentUser!.uid, avatarUrl);

        setState(() {
          currentUser = currentUser!.copyWith(avatarUrl: avatarUrl);
        });

        _showMessage('✅ Avatar mis à jour !', isError: false);
      } else {
        _showMessage('❌ Échec de l\'upload', isError: true);
      }

      await _analyticsRepository.logAvatarUpload();
    } catch (e) {
      print('❌ Erreur complète: $e');
      _showMessage('❌ Erreur upload: $e', isError: true);
    } finally {
      setState(() => _isUploading = false);
    }
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
        title: const Text('Mon Profil', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.darkTeal,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.darkTeal)))
          : currentUser == null
          ? const Center(child: Text('Erreur de chargement'))
          : SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: AppColors.darkTeal,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: AppColors.accentYellow, width: 4),
                        ),
                        child: _isUploading
                            ? const Center(child: CircularProgressIndicator())
                            : ClipOval(
                          child: currentUser!.avatarUrl != null
                              ? Image.network(
                            currentUser!.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 60, color: AppColors.darkTeal),
                          )
                              : const Icon(Icons.person, size: 60, color: AppColors.darkTeal),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _uploadAvatar,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.accentYellow,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: AppColors.darkTeal, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentUser!.displayName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentUser!.email,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Statistiques', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(child: _buildStatCard('Score Total', '${currentUser!.totalScore}', Icons.star, AppColors.accentYellow)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard('Quiz Joués', '${currentUser!.quizzesPlayed}', Icons.quiz, AppColors.mediumTeal)),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _buildStatCard('Moyenne', '${currentUser!.averageScore.toStringAsFixed(1)}', Icons.trending_up, AppColors.correctGreen, fullWidth: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {bool fullWidth = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}