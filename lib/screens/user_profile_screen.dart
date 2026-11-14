import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/app_assets.dart';
import '../core/theme/app_colors.dart';
import '../models/farm_models.dart';
import '../providers/farm_providers.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _nicController;
  late TextEditingController _branchController;
  String _selectedRole = 'Admin / Manager';

  bool _initialized = false;
  bool _isSaving = false;
  bool _showVisiblePassword = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _nicController = TextEditingController();
    _branchController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nicController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  void _populateData(AppUser user) {
    if (!_initialized) {
      _nameController.text = user.name;
      _selectedRole = user.role;
      _emailController.text = user.email;
      _phoneController.text = user.phone;
      _nicController.text = user.nic;
      _branchController.text = user.farmBranch;
      _initialized = true;
    }
  }

  String _generateStrongPassword({int length = 12}) {
    const chars = 'abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#%&*';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  void _showAddRoleDialog(BuildContext context) {
    final roleCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16264C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.add_moderator_rounded, color: AppColors.darkPrimaryGold),
              SizedBox(width: 10),
              Text('Create New Role', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: TextField(
            controller: roleCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Role Title (e.g. Field Agronomist)',
              labelStyle: TextStyle(color: Colors.white70),
              fillColor: Color(0xFF0B1B3D),
              filled: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkPrimaryGold,
                foregroundColor: const Color(0xFF0B1B3D),
              ),
              onPressed: () async {
                final text = roleCtrl.text.trim();
                if (text.isEmpty) return;

                // Confirmation alert before write
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    backgroundColor: const Color(0xFF16264C),
                    title: const Text('Confirm Role Creation', style: TextStyle(color: Colors.white)),
                    content: Text('Add "$text" to the farm roles registry?', style: const TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                      ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('CONFIRM')),
                    ],
                  ),
                );

                if (confirm != true) return;

                final db = ref.read(databaseServiceProvider);
                await db.addRole(text);

                setState(() => _selectedRole = text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Role "$text" added successfully!'), backgroundColor: AppColors.darkGreen),
                  );
                }
              },
              child: const Text('SAVE ROLE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveProfile(AppUser currentUser) async {
    if (!_formKey.currentState!.validate()) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16264C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Profile Update', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to save these profile changes?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkPrimaryGold, foregroundColor: const Color(0xFF0B1B3D)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);
    final db = ref.read(databaseServiceProvider);

    try {
      final updatedUser = AppUser(
        uid: currentUser.uid,
        name: _nameController.text.trim(),
        role: _selectedRole,
        email: currentUser.email, // Preserve locked username / email
        phone: _phoneController.text.trim(),
        nic: _nicController.text.trim(),
        farmBranch: _branchController.text.trim(),
        avatarUrl: currentUser.avatarUrl,
        visiblePassword: currentUser.visiblePassword,
        hasChangedPassword: currentUser.hasChangedPassword,
      );

      await db.updateUserProfile(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile changes saved successfully!'),
            backgroundColor: AppColors.darkGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppColors.darkRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showChangePasswordDialog(BuildContext context, AppUser user) {
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    final passwordFormKey = GlobalKey<FormState>();
    bool isUpdatingPassword = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF16264C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.lock_reset_rounded, color: AppColors.darkPrimaryGold, size: 26),
                  SizedBox(width: 10),
                  Text('Reset Password', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Form(
                key: passwordFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Admin override: Enter new password directly (current password is not required).',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: newPasswordCtrl,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'New Password *',
                        labelStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.vpn_key_outlined, color: AppColors.darkPrimaryGold),
                        fillColor: Color(0xFF0B1B3D),
                        filled: true,
                      ),
                      validator: (val) {
                        if (val == null || val.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: confirmPasswordCtrl,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password *',
                        labelStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.check_circle_outline, color: AppColors.darkPrimaryGold),
                        fillColor: Color(0xFF0B1B3D),
                        filled: true,
                      ),
                      validator: (val) {
                        if (val != newPasswordCtrl.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    // Suggest Strong Password Button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: AppColors.darkPrimaryGold),
                        icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                        label: const Text('Suggest Strong Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          final pass = _generateStrongPassword();
                          newPasswordCtrl.text = pass;
                          confirmPasswordCtrl.text = pass;
                          setDialogState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkPrimaryGold,
                    foregroundColor: const Color(0xFF0B1B3D),
                  ),
                  onPressed: isUpdatingPassword
                      ? null
                      : () async {
                          if (!passwordFormKey.currentState!.validate()) return;

                          // Global Confirmation AlertDialog before write
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              backgroundColor: const Color(0xFF16264C),
                              title: const Text('Confirm Password Reset', style: TextStyle(color: Colors.white)),
                              content: const Text(
                                'Override and update this user\'s password in Firebase? The new password will remain visible to the admin until the user changes it.',
                                style: TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('CONFIRM RESET')),
                              ],
                            ),
                          );

                          if (confirm != true) return;

                          setDialogState(() => isUpdatingPassword = true);

                          try {
                            final newPass = newPasswordCtrl.text.trim();
                            final db = ref.read(databaseServiceProvider);

                            // Lifecycle State 3: Admin override resets hasChangedPassword: false and sets visiblePassword
                            await db.updateUserPassword(
                              uid: user.uid,
                              newPassword: newPass,
                              isAdminReset: true,
                            );

                            final authUser = FirebaseAuth.instance.currentUser;
                            if (authUser != null) {
                              try {
                                await authUser.updatePassword(newPass);
                              } catch (_) {}
                            }

                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Password reset successfully! Visible to admin.'),
                                  backgroundColor: AppColors.darkGreen,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isUpdatingPassword = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Notice: $e'), backgroundColor: AppColors.darkRed),
                              );
                            }
                          }
                        },
                  child: isUpdatingPassword
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0B1B3D)))
                      : const Text('CONFIRM RESET', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final rolesAsync = ref.watch(rolesStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final uniqueRoles = List<String>.from(rolesAsync.value ?? ['Manager', 'Supervisor', 'Collector', 'Driver']).toSet().toList();
    if (_selectedRole.isNotEmpty && !uniqueRoles.contains(_selectedRole)) {
      uniqueRoles.add(_selectedRole);
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackgroundWarm,
      appBar: AppBar(
        title: const Text('User Profile Details', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: userAsync.when(
        data: (user) {
          _populateData(user);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Wimalasooriya Farms Crest Badge
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.darkPrimaryGold, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.darkPrimaryGold.withOpacity(0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              AppAssets.logo,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.darkPrimaryGold,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified_user_rounded, color: Color(0xFF0B1B3D), size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.darkPrimaryGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.darkPrimaryGold),
                    ),
                    child: Text(
                      user.role,
                      style: const TextStyle(color: AppColors.darkPrimaryGold, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Admin Password Visibility Lifecycle Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF16264C) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.darkPrimaryGold.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.security_rounded, color: AppColors.darkPrimaryGold, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Admin Password Record', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              if (user.hasChangedPassword)
                                const Text('Hidden (Updated by user)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600))
                              else if (user.visiblePassword != null && user.visiblePassword!.isNotEmpty)
                                Text(
                                  _showVisiblePassword ? user.visiblePassword! : '••••••••••••',
                                  style: const TextStyle(color: AppColors.darkPrimaryGold, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                )
                              else
                                const Text('Password set during initial provisioning', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                        if (!user.hasChangedPassword && user.visiblePassword != null)
                          IconButton(
                            icon: Icon(
                              _showVisiblePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: AppColors.darkPrimaryGold,
                            ),
                            tooltip: 'Toggle Password Visibility',
                            onPressed: () => setState(() => _showVisiblePassword = !_showVisiblePassword),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Editable Form Fields
                  _buildTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),

                  // Dynamic Role Selector with + Add New Role Button
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: uniqueRoles.contains(_selectedRole) ? _selectedRole : (uniqueRoles.isNotEmpty ? uniqueRoles.first : null),
                          dropdownColor: const Color(0xFF0B1B3D),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            labelText: 'Role / Designation',
                            labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.darkPrimaryGold),
                            fillColor: isDark ? const Color(0xFF16264C) : Colors.white,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: uniqueRoles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedRole = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.darkPrimaryGold,
                          foregroundColor: const Color(0xFF0B1B3D),
                          padding: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        tooltip: 'Add New Role',
                        onPressed: () => _showAddRoleDialog(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Strictly Locked Username / Email Field
                  _buildTextField(
                    controller: _emailController,
                    label: 'Username / Email Address (Locked)',
                    icon: Icons.lock_outline_rounded,
                    isDark: isDark,
                    readOnly: true,
                    helperText: 'Assigned by system administrator and cannot be modified.',
                  ),
                  const SizedBox(height: 14),

                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    isDark: isDark,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),

                  _buildTextField(
                    controller: _nicController,
                    label: 'NIC Number',
                    icon: Icons.credit_card_outlined,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),

                  _buildTextField(
                    controller: _branchController,
                    label: 'Farm Branch / Address',
                    icon: Icons.location_on_outlined,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),

                  // Change / Update Security Password Button
                  OutlinedButton.icon(
                    onPressed: () => _showChangePasswordDialog(context, user),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.darkPrimaryGold,
                      side: const BorderSide(color: AppColors.darkPrimaryGold, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    icon: const Icon(Icons.key_rounded, size: 20),
                    label: const Text('Reset / Update Security Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  const SizedBox(height: 16),

                  // Save Profile Changes Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : () => _saveProfile(user),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC59B27),
                        foregroundColor: const Color(0xFF0B1B3D),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Color(0xFF0B1B3D), strokeWidth: 2.5),
                            )
                          : const Text(
                              'Save Profile Changes',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.darkPrimaryGold)),
        error: (err, _) => Center(child: Text('Error loading profile: $err')),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    bool readOnly = false,
    String? helperText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      style: TextStyle(
        color: readOnly
            ? (isDark ? Colors.white60 : Colors.black54)
            : (isDark ? Colors.white : const Color(0xFF0B1B3D)),
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          fontWeight: readOnly ? FontWeight.w700 : FontWeight.normal,
        ),
        helperText: helperText,
        helperStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
        prefixIcon: Icon(icon, color: readOnly ? const Color(0xFF94A3B8) : AppColors.darkPrimaryGold),
        suffixIcon: readOnly ? const Icon(Icons.lock_rounded, color: Color(0xFF94A3B8), size: 18) : null,
        fillColor: readOnly
            ? (isDark ? const Color(0xFF0B1B3D).withOpacity(0.6) : const Color(0xFFE2E8F0))
            : (isDark ? const Color(0xFF16264C) : Colors.white),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? const Color(0x33FFFFFF) : const Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: readOnly
                ? (isDark ? Colors.white12 : const Color(0xFFCBD5E1))
                : (isDark ? const Color(0x33FFFFFF) : const Color(0xFFCBD5E1)),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: readOnly ? Colors.white24 : AppColors.darkPrimaryGold,
            width: 2,
          ),
        ),
      ),
      validator: (val) {
        if (!readOnly && (val == null || val.trim().isEmpty)) return '$label cannot be empty';
        return null;
      },
    );
  }
}
