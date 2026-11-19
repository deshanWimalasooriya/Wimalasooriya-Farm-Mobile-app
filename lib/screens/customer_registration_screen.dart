import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_assets.dart';
import '../core/theme/app_colors.dart';
import '../providers/farm_providers.dart';
import 'customer_map_screen.dart';
import 'customer_home_screen.dart';
import 'login_screen.dart';
import '../utils/app_snackbar.dart';

class CustomerRegistrationScreen extends ConsumerStatefulWidget {
  const CustomerRegistrationScreen({super.key});

  @override
  ConsumerState<CustomerRegistrationScreen> createState() => _CustomerRegistrationScreenState();
}

class _CustomerRegistrationScreenState extends ConsumerState<CustomerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  double? _selectedLatitude;
  double? _selectedLongitude;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _shopNameController.dispose();
    _shopAddressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  Future<void> _pickLocationOnMap() async {
    FocusScope.of(context).unfocus();
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerMapScreen(
          initialLat: _selectedLatitude,
          initialLng: _selectedLongitude,
          initialShopName: _shopNameController.text.trim(),
          initialShopAddress: _shopAddressController.text.trim(),
          isPickerOnly: true,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedLatitude = result['latitude'] as double?;
        _selectedLongitude = result['longitude'] as double?;
        final returnedName = result['shopName'] as String?;
        final returnedAddr = result['shopAddress'] as String?;
        if (returnedName != null && returnedName.isNotEmpty && _shopNameController.text.trim().isEmpty) {
          _shopNameController.text = returnedName;
        }
        if (returnedAddr != null && returnedAddr.isNotEmpty && _shopAddressController.text.trim().isEmpty) {
          _shopAddressController.text = returnedAddr;
        }
      });
      _showCorporateSnackBar('Delivery pin updated successfully', isError: false);
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLatitude == null || _selectedLongitude == null) {
      _showCorporateSnackBar('Please pin your shop location on the map for delivery logistics.', isError: true);
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final phone = _phoneController.text.trim();
    final shopName = _shopNameController.text.trim();
    final shopAddress = _shopAddressController.text.trim();
    final password = _passwordController.text;

    try {
      // 1. Create Firebase Auth User
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-null',
          message: 'Failed to create user session.',
        );
      }

      // Update Firebase Auth display name
      await user.updateDisplayName(name);

      // 2. Write Customer document in Firestore users/{uid}
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': 'Customer',
        'shopName': shopName,
        'shopAddress': shopAddress,
        'latitude': _selectedLatitude,
        'longitude': _selectedLongitude,
        'farmBranch': 'Main Farm — Kurunegala',
        'hasChangedPassword': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Persist login flag
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);

      // 4. Invalidate providers to force refresh
      ref.invalidate(authUserProvider);
      ref.invalidate(currentUserStreamProvider);

      if (!mounted) return;

      _showCorporateSnackBar('Account registered successfully! Welcome to Wimalasooriya Farms.', isError: false);

      // 5. Navigate to Customer Home Screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => CustomerHomeScreen(
            onLogout: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('is_logged_in', false);
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
    } on FirebaseAuthException catch (authErr) {
      debugPrint('Registration auth error: ${authErr.code} - ${authErr.message}');
      String friendlyMessage;
      switch (authErr.code) {
        case 'email-already-in-use':
          friendlyMessage = 'An account already exists for this email. Please log in.';
          break;
        case 'invalid-email':
          friendlyMessage = 'The email address is invalid.';
          break;
        case 'operation-not-allowed':
          friendlyMessage = 'Email/password accounts are not enabled in Firebase Auth.';
          break;
        case 'weak-password':
          friendlyMessage = 'The password is too weak. Please use at least 6 characters.';
          break;
        case 'network-request-failed':
          friendlyMessage = 'Network error. Please check your internet connection.';
          break;
        default:
          friendlyMessage = authErr.message ?? 'Registration failed. Please check your details.';
      }
      if (mounted) {
        setState(() => _errorMessage = friendlyMessage);
        _showCorporateSnackBar(friendlyMessage, isError: true);
      }
    } catch (e) {
      debugPrint('Registration general error: $e');
      final friendlyMessage = 'Registration error: ${e.toString().replaceAll('Exception:', '').trim()}';
      if (mounted) {
        setState(() => _errorMessage = friendlyMessage);
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
          child: Column(
            children: [
              // Top Bar with back button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Back to Login',
                    ),
                    const Expanded(
                      child: Text(
                        'Customer Registration',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance back button
                  ],
                ),
              ),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Column(
                      children: [
                        // Small Crest Logo
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.darkPrimaryGold.withOpacity(0.35),
                                blurRadius: 20,
                                spreadRadius: 4,
                                offset: const Offset(0, 2),
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
                                    child: Icon(Icons.storefront_rounded, size: 40, color: AppColors.darkPrimaryGold),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Wholesale & Retail Portal',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Register your retail store or bakery to order directly from farm harvest',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Form Glassmorphic Card
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              padding: const EdgeInsets.all(22),
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
                                    // Full Name Field
                                    _buildLabel('Full Name / Proprietor'),
                                    TextFormField(
                                      controller: _nameController,
                                      style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                                      decoration: _buildInputDecoration(
                                        hintText: 'e.g. Kasun Perera',
                                        prefixIcon: Icons.person_outline_rounded,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Please enter your full name';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),

                                    // Email Address Field
                                    _buildLabel('Email Address'),
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                                      decoration: _buildInputDecoration(
                                        hintText: 'e.g. buyer@gmail.com',
                                        prefixIcon: Icons.email_outlined,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Please enter your email address';
                                        }
                                        final trimmed = value.trim();
                                        if (!trimmed.contains('@') || !trimmed.contains('.')) {
                                          return 'Please enter a valid email address';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),

                                    // Phone Number Field
                                    _buildLabel('Phone Number'),
                                    TextFormField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                                      decoration: _buildInputDecoration(
                                        hintText: 'e.g. 077 123 4567',
                                        prefixIcon: Icons.phone_outlined,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Please enter your contact phone number';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),

                                    // Shop / Business Name Field
                                    _buildLabel('Shop / Business Name'),
                                    TextFormField(
                                      controller: _shopNameController,
                                      style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                                      decoration: _buildInputDecoration(
                                        hintText: 'e.g. Perera Grocery & Bakery',
                                        prefixIcon: Icons.store_outlined,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Please enter your shop or business name';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),

                                    // Shop Address Field
                                    _buildLabel('Shop / Delivery Address'),
                                    TextFormField(
                                      controller: _shopAddressController,
                                      maxLines: 2,
                                      style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                                      decoration: _buildInputDecoration(
                                        hintText: 'e.g. 142/A, Kandy Road, Kurunegala',
                                        prefixIcon: Icons.location_city_outlined,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Please enter your physical delivery address';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // GPS Location Picker Button / Indicator
                                    _buildLabel('GPS Delivery Location (Required for Logistics)'),
                                    InkWell(
                                      onTap: _pickLocationOnMap,
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        decoration: BoxDecoration(
                                          color: _selectedLatitude != null
                                              ? const Color(0x1F22C55E)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: _selectedLatitude != null
                                                ? const Color(0xFF22C55E)
                                                : const Color(0xFFCBD5E1),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              _selectedLatitude != null
                                                  ? Icons.check_circle_rounded
                                                  : Icons.add_location_alt_rounded,
                                              color: _selectedLatitude != null
                                                  ? const Color(0xFF16A34A)
                                                  : const Color(0xFFC59B27),
                                              size: 24,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _selectedLatitude != null
                                                        ? 'Delivery Pin Locked'
                                                        : 'Set Shop Location on Map',
                                                    style: TextStyle(
                                                      color: _selectedLatitude != null
                                                          ? const Color(0xFF15803D)
                                                          : const Color(0xFF0F172A),
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    _selectedLatitude != null
                                                        ? 'Lat: ${_selectedLatitude!.toStringAsFixed(4)}, Lng: ${_selectedLongitude!.toStringAsFixed(4)} (Tap to edit)'
                                                        : 'Tap to place pin on interactive map',
                                                    style: TextStyle(
                                                      color: _selectedLatitude != null
                                                          ? const Color(0xFF166534)
                                                          : const Color(0xFF64748B),
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              color: Color(0xFF94A3B8),
                                              size: 14,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Password Field
                                    _buildLabel('Password (Min. 6 Characters)'),
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
                                            setState(() => _obscurePassword = !_obscurePassword);
                                          },
                                        ),
                                        hintText: 'Enter secure password',
                                        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                                          return 'Please enter a password';
                                        }
                                        if (value.length < 6) {
                                          return 'Password must be at least 6 characters';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),

                                    // Confirm Password Field
                                    _buildLabel('Confirm Password'),
                                    TextFormField(
                                      controller: _confirmPasswordController,
                                      obscureText: _obscureConfirmPassword,
                                      style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF64748B)),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                            color: const Color(0xFF64748B),
                                          ),
                                          onPressed: () {
                                            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                                          },
                                        ),
                                        hintText: 'Re-enter password to confirm',
                                        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                                          return 'Please confirm your password';
                                        }
                                        if (value != _passwordController.text) {
                                          return 'Passwords do not match';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 24),

                                    // Register Button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _handleRegister,
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
                                                'Create Customer Account',
                                                style: TextStyle(
                                                  fontSize: 16,
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
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Back to login link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already registered?',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  color: AppColors.darkPrimaryGold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hintText, required IconData prefixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF64748B)),
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      errorStyle: const TextStyle(
        color: Color(0xFFFCA5A5),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    );
  }
}
