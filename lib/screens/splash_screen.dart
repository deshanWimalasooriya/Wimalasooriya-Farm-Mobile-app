import 'package:flutter/material.dart';
import '../core/constants/app_assets.dart';
import '../core/theme/app_colors.dart';

class SplashScreen extends StatelessWidget {
  final String statusText;

  const SplashScreen({
    super.key,
    this.statusText = 'Connecting to Wimalasooriya Cloud...',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.3),
            radius: 1.4,
            colors: [
              Color(0xFF0F2656),
              Color(0xFF0B1B3D),
              Color(0xFF071229),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Centered Circular Crest Logo with Soft Golden Glow
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.darkPrimaryGold.withOpacity(0.4),
                      blurRadius: 40,
                      spreadRadius: 6,
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
                          child: Icon(Icons.agriculture, size: 70, color: AppColors.darkPrimaryGold),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Farm Title in Crisp White / Gold Typography
              const Text(
                'Wimalasooriya Farms',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'COMMERCIAL AGRICULTURAL ERP',
                style: TextStyle(
                  color: AppColors.darkPrimaryGold,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                ),
              ),

              const Spacer(),

              // Smooth Gold Loading Indicator
              const SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkPrimaryGold),
                  strokeWidth: 3.2,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                statusText,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}

