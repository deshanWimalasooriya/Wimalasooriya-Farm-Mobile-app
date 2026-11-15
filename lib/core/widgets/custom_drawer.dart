import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';
import '../../providers/farm_providers.dart';
import '../../screens/user_profile_screen.dart';
import '../../screens/admin_panel_screen.dart';

class CustomNavigationDrawer extends ConsumerWidget {
  final VoidCallback? onOpenTeamLabor;
  final VoidCallback? onOpenBulkOrders;
  final VoidCallback? onOpenFleet;
  final VoidCallback? onLogout;

  const CustomNavigationDrawer({
    super.key,
    this.onOpenTeamLabor,
    this.onOpenBulkOrders,
    this.onOpenFleet,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final userAsync = ref.watch(currentUserStreamProvider);
    final isDark = themeMode == ThemeMode.dark;

    final userName = userAsync.value?.name ?? 'Deshan Wimalasooriya';
    final userRole = userAsync.value?.role ?? 'Admin / Manager';

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0B1B3D) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Manager Profile Section (Clean, Compact Header)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MANAGER PROFILE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.darkPrimaryGold, width: 2),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            AppAssets.logo,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.darkPrimaryGold, width: 1),
                                color: const Color(0x1FD4AF37),
                              ),
                              child: Text(
                                userRole,
                                style: const TextStyle(
                                  color: AppColors.darkPrimaryGold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0x22FFFFFF), height: 1),

            // Navigation Links
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerTile(
                    icon: Icons.badge_outlined,
                    label: 'User Profile Details',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UserProfileScreen()),
                      );
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Admin Panel',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                      );
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.groups_outlined,
                    label: 'Team & Labor',
                    onTap: () {
                      Navigator.pop(context);
                      if (onOpenTeamLabor != null) onOpenTeamLabor!();
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.shopping_cart_outlined,
                    label: 'Bulk Orders (B2B)',
                    onTap: () {
                      Navigator.pop(context);
                      if (onOpenBulkOrders != null) onOpenBulkOrders!();
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.local_shipping_outlined,
                    label: 'Fleet & Logistics',
                    onTap: () {
                      Navigator.pop(context);
                      if (onOpenFleet != null) onOpenFleet!();
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Internal Support Chat',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Support Chat: Connected to Farm Fleet & Dispatch')),
                      );
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.fact_check_outlined,
                    label: 'Activity Log',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Activity Log: Real-time Firestore server timestamps active')),
                      );
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.settings_outlined,
                    label: 'App Settings & Security',
                    trailing: Switch(
                      value: isDark,
                      activeThumbColor: AppColors.darkPrimaryGold,
                      onChanged: (val) {
                        ref.read(themeModeProvider.notifier).toggleTheme();
                      },
                    ),
                    onTap: () {
                      ref.read(themeModeProvider.notifier).toggleTheme();
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.info_outline_rounded,
                    label: 'About & Info',
                    onTap: () {
                      Navigator.pop(context);
                      showAboutDialog(
                        context: context,
                        applicationName: 'Wimalasooriya Farms ERP',
                        applicationVersion: '1.0.0',
                        applicationLegalese: '© 2026 Wimalasooriya Farms — Sri Lanka',
                      );
                    },
                  ),
                ],
              ),
            ),

            // Logout Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  if (onLogout != null) onLogout!();
                },
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 26),
                      SizedBox(width: 14),
                      Text(
                        'LOG OUT',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.darkPrimaryGold, size: 24),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}
