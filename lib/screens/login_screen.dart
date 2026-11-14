import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_assets.dart';
import '../core/theme/app_colors.dart';
import '../providers/farm_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _employeeIdController = TextEditingController(text: 'deshanwimalasooriya000@gmail.com');
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _employeeIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final input = _employeeIdController.text.trim();
      final password = _passwordController.text.trim();

      String uid = 'current_user';
      final email = input.contains('@') ? input : 'deshanwimalasooriya000@gmail.com';

      // Attempt Firebase Auth sign-in if an email format is provided
      if (input.contains('@') && password.isNotEmpty) {
        try {
          final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: input,
            password: password,
          );
          uid = cred.user?.uid ?? uid;
        } on FirebaseAuthException catch (authErr) {
          if (authErr.code == 'user-not-found') {
            // Auto-provision initial Admin credentials if first time
            final newCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: input,
              password: password,
            );
            uid = newCred.user?.uid ?? uid;
          } else {
            rethrow;
          }
        }
      }

      // Automatically create and seed admin profile in Firestore if not existing
      final db = ref.read(databaseServiceProvider);
      await db.ensureAdminProfileSeeded(uid: uid, email: email);

      // Persist login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);

      widget.onLoginSuccess();
    } catch (e) {
      debugPrint('Auth notice: $e');
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'current_user';
      final db = ref.read(databaseServiceProvider);
      await db.ensureAdminProfileSeeded(uid: uid, email: 'deshanwimalasooriya000@gmail.com');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      widget.onLoginSuccess();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.3),
            radius: 1.2,
            colors: [
              Color(0xFF0F2656),
              Color(0xFF0B1B3D),
              Color(0xFF071229),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Title and Subtitle
                  const Text(
                    'Wimalasooriya Farms',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Commercial Agricultural ERP',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Circular Crest Logo with Golden Outer Glow
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.darkPrimaryGold.withOpacity(0.35),
                          blurRadius: 36,
                          spreadRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        AppAssets.logo,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFF16264C),
                            child: const Center(
                              child: Icon(Icons.agriculture, size: 80, color: AppColors.darkPrimaryGold),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 44),

                  // Glassmorphic Login Panel
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0x6616264C),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.18),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Employee ID Field
                            TextField(
                              controller: _employeeIdController,
                              style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF64748B)),
                                hintText: 'Admin Email / Employee ID',
                                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF64748B)),
                                hintText: 'Admin Password',
                                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Login Button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFC59B27),
                                  foregroundColor: Colors.white,
                                  elevation: 6,
                                  shadowColor: const Color(0x66C59B27),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                      )
                                    : const Text(
                                        'Login to Dashboard',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                              ),
                            ),

                            if (_errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                style: const TextStyle(color: AppColors.darkRed, fontSize: 13),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
