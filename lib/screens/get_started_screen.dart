import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/constants/app_assets.dart';
import '../core/theme/app_colors.dart';

class GetStartedScreen extends StatelessWidget {
  final VoidCallback onGetStarted;

  const GetStartedScreen({super.key, required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.35),
            radius: 1.3,
            colors: [
              Color(0xFF0F2656),
              Color(0xFF0B1B3D),
              Color(0xFF071229),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Wimalasooriya Farms Crest Logo
                Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.darkPrimaryGold.withOpacity(0.4),
                        blurRadius: 40,
                        spreadRadius: 8,
                        offset: const Offset(0, 6),
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
                const SizedBox(height: 32),

                // Farm Title & Tagline
                const Text(
                  'Wimalasooriya Farms',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'COMMERCIAL POULTRY ERP & FLOCK INTELLIGENCE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.darkPrimaryGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 28),

                // Feature Highlights Pill Cards
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0x6616264C),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: Column(
                        children: [
                          _buildFeatureRow(
                            icon: Icons.inventory_2_outlined,
                            title: 'Real-Time Flock & Egg Tracking',
                            subtitle: 'Daily yield counters and audit-backed ledger',
                          ),
                          const Divider(color: Colors.white12, height: 20),
                          _buildFeatureRow(
                            icon: Icons.account_balance_wallet_outlined,
                            title: 'Automated Financial Ledger',
                            subtitle: 'Dynamic egg sales calculation & expense audits',
                          ),
                          const Divider(color: Colors.white12, height: 20),
                          _buildFeatureRow(
                            icon: Icons.badge_outlined,
                            title: 'Workforce & Labor Management',
                            subtitle: 'Teams, shifts, payroll execution & QR identification',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // Get Started Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: onGetStarted,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkPrimaryGold,
                      foregroundColor: const Color(0xFF0B1B3D),
                      elevation: 6,
                      shadowColor: AppColors.darkPrimaryGold.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 22),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Closed Registration Disclaimer
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF94A3B8)),
                    SizedBox(width: 6),
                    Text(
                      'Restricted farm portal. Authorized personnel only.',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.darkPrimaryGold.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.darkPrimaryGold, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

