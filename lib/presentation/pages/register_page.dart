// ========================================
// register_page.dart
// ========================================

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authRepository = AuthRepository();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      AppUser? user = await _authRepository.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Compte créé !'), backgroundColor: AppColors.correctGreen),
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_authRepository.getErrorMessage(e)), backgroundColor: AppColors.incorrectRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkTeal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.person_add, size: 50, color: AppColors.darkTeal),
                  ),
                  const SizedBox(height: 24),
                  const Text('Inscription', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 30),
                  _buildField(_nameController, 'Nom', Icons.person, false),
                  const SizedBox(height: 16),
                  _buildField(_emailController, 'Email', Icons.email, false, isEmail: true),
                  const SizedBox(height: 16),
                  _buildField(_passwordController, 'Mot de passe', Icons.lock, true, isPassword: true),
                  const SizedBox(height: 16),
                  _buildField(_confirmPasswordController, 'Confirmer', Icons.lock_outline, true, isConfirm: true),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentYellow,
                        foregroundColor: AppColors.darkTeal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.darkTeal)))
                          : const Text('S\'inscrire', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, bool isPasswordField, {bool isEmail = false, bool isPassword = false, bool isConfirm = false}) {
    bool isVisible = isPasswordField ? (isPassword ? _isPasswordVisible : _isConfirmVisible) : false;

    return TextFormField(
      controller: controller,
      obscureText: isPasswordField && !isVisible,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: isPasswordField
            ? IconButton(
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
          onPressed: () => setState(() {
            if (isPassword) {
              _isPasswordVisible = !_isPasswordVisible;
            } else {
              _isConfirmVisible = !_isConfirmVisible;
            }
          }),
        )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accentYellow, width: 2)),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Champ requis';
        if (isEmail && !v.contains('@')) return 'Email invalide';
        if (isPassword && v.length < 6) return 'Min 6 caractères';
        if (isConfirm && v != _passwordController.text) return 'Mots de passe différents';
        return null;
      },
    );
  }
}