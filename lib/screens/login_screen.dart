import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_assets.dart';
import '../core/theme/app_colors.dart';
import '../providers/farm_providers.dart';
import 'customer_registration_screen.dart';
import 'customer_home_screen.dart';
import '../utils/app_snackbar.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _employeeIdController = TextEditingController(text: 'deshanwimalasooriya000@gmail.com');
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _employeeIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showCorporateSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    if (isError) {
      AppSnackBar.showError(context, message);
    } else {
      AppSnackBar.showSuccess(context, message);
    }
  }

  Future<void> _handleLogin() async {
    // 1. Strict Frontend Form Validation
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Dismiss soft keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final input = _employeeIdController.text.trim();
    final password = _passwordController.text;

    // Resolve email format if Employee ID provided
    String email = input;
    if (!input.contains('@')) {
      final cleaned = input.toLowerCase().replaceAll('-', '').replaceAll(' ', '');
      email = '$cleaned@wimalasooriya.farm';
    }

    try {
      // 2. Strict Firebase Authentication Call
      UserCredential cred;
      try {
        cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (authErr) {
        // One-time initial provisioning for primary admin account if first time run
        if (authErr.code == 'user-not-found' && email == 'deshanwimalasooriya000@gmail.com') {
          cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
        } else {
          rethrow;
        }
      }

      final user = cred.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-null',
          message: 'Failed to obtain user session from authentication service.',
        );
      }

      // 3. Seed admin profile in Firestore if admin email
      final db = ref.read(databaseServiceProvider);
      if (user.email == 'deshanwimalasooriya000@gmail.com') {
        await db.ensureAdminProfileSeeded(uid: user.uid, email: user.email);
      }

      // 4. Persist login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);

      // 5. Invalidate auth and user stream providers to sync live state
      ref.invalidate(authUserProvider);
      ref.invalidate(currentUserStreamProvider);

      // 6. Strict Role-Based Routing
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      String userRole = 'Customer';
      if (userDoc.exists && userDoc.data() != null && userDoc.data()!['role'] != null) {
        userRole = userDoc.data()!['role'].toString();
      } else if (user.email == 'deshanwimalasooriya000@gmail.com') {
        userRole = 'Admin / Manager';
      }

      if (!mounted) return;

      if (userRole.toLowerCase().contains('customer')) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => CustomerHomeScreen(
              onLogout: () async {
                final p = await SharedPreferences.getInstance();
                await p.setBool('is_logged_in', false);
                try {
                  await FirebaseAuth.instance.signOut();
                } catch (_) {}
                ref.invalidate(authUserProvider);
                ref.invalidate(currentUserStreamProvider);
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(
                        onLoginSuccess: () {},
                      ),
                    ),
                    (route) => false,
                  );
                }
              },
            ),
          ),
          (route) => false,
        );
      } else {
        // Admin, Manager, or operational staff
        widget.onLoginSuccess();
      }
    } on FirebaseAuthException catch (authErr) {
      debugPrint('FirebaseAuthException during login: ${authErr.code} - ${authErr.message}');
      String friendlyMessage;
      switch (authErr.code) {
        case 'user-not-found':
          friendlyMessage = 'No account found with this email or employee ID.';
          break;
        case 'wrong-password':
        case 'invalid-credential':
          friendlyMessage = 'Invalid password. Please check your credentials.';
          break;
        case 'invalid-email':
          friendlyMessage = 'The email address format is invalid.';
          break;
        case 'user-disabled':
          friendlyMessage = 'This account has been deactivated. Contact management.';
          break;
        case 'too-many-requests':
          friendlyMessage = 'Too many failed login attempts. Please try again shortly.';
          break;
        case 'network-request-failed':
          friendlyMessage = 'Network error. Please check your internet connection.';
          break;
        default:
          friendlyMessage = authErr.message ?? 'Authentication failed. Please verify your credentials.';
      }

      if (mounted) {
        setState(() {
          _errorMessage = friendlyMessage;
        });
        _showCorporateSnackBar(friendlyMessage, isError: true);
      }
    } catch (e) {
      debugPrint('General error during login: $e');
      final friendlyMessage = 'Authentication failed: ${e.toString().replaceAll('Exception:', '').trim()}';
      if (mounted) {
        setState(() {
          _errorMessage = friendlyMessage;
        });
        _showCorporateSnackBar(friendlyMessage, isError: true);
      }
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Employee ID / Email Field
                              TextFormField(
                                controller: _employeeIdController,
                                keyboardType: TextInputType.emailAddress,
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
                                  errorStyle: const TextStyle(
                                    color: Color(0xFFFCA5A5),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your email or employee ID';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF64748B)),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: const Color(0xFF64748B),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  hintText: 'Password',
                                  hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  errorStyle: const TextStyle(
                                    color: Color(0xFFFCA5A5),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
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
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0x33DC2626),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFDC2626), width: 0.8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline_rounded, color: Color(0xFFFCA5A5), size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'New Customer?',
                                    style: TextStyle(
                                      color: Color(0xFFCBD5E1),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => const CustomerRegistrationScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Create Account',
                                      style: TextStyle(
                                        color: AppColors.darkPrimaryGold,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
