import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'hen_icon.dart';

class CustomCurvedNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;
  final VoidCallback onOpenMenu;

  const CustomCurvedNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.onOpenMenu,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBarBg = isDark ? const Color(0xFF0B1B3D) : const Color(0xFF0B1B3D);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const double barHeight = 72.0;
    const double totalHeight = barHeight + 35.0; // Extra room for elevated button

    final items = [
      _NavItem(icon: Icons.grid_view_rounded, label: 'Dashboard'),
      _NavItem(isHen: true, label: 'Flock'),
      _NavItem(icon: Icons.home_rounded, label: 'Home'),
      _NavItem(icon: Icons.monetization_on_outlined, label: 'Finance'),
      _NavItem(icon: Icons.menu_rounded, label: 'Menu'),
    ];

    return SizedBox(
      height: totalHeight + bottomPadding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / 5;
          final activeCenterX = (selectedIndex * tabWidth) + (tabWidth / 2);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Curved Navy Bar Background
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                top: 25,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: activeCenterX, end: activeCenterX),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  builder: (context, currentX, child) {
                    return CustomPaint(
                      size: Size(constraints.maxWidth, barHeight + bottomPadding),
                      painter: _CurvedNavBarPainter(
                        backgroundColor: navBarBg,
                        activeX: currentX,
                        notchRadius: 36.0,
                      ),
                    );
                  },
                ),
              ),

              // 2. Tab Items (Icons and Labels)
              Positioned(
                left: 0,
                right: 0,
                bottom: bottomPadding + 8,
                height: barHeight - 12,
                child: Row(
                  children: List.generate(5, (index) {
                    final item = items[index];
                    final isActive = selectedIndex == index;

                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (index == 4) {
                            onTabSelected(4);
                            onOpenMenu();
                          } else {
                            onTabSelected(index);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // For active tab, the icon is in the elevated button above
                              Opacity(
                                opacity: isActive ? 0.0 : 1.0,
                                child: item.isHen
                                    ? const HenIcon(
                                        size: 24,
                                        color: Colors.white,
                                      )
                                    : Icon(
                                        item.icon,
                                        size: 24,
                                        color: Colors.white,
                                      ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                  color: isActive
                                      ? AppColors.darkPrimaryGold
                                      : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // 3. Animated Elevated Gold Circle Dock
              AnimatedPositioned(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeInOutCubic,
                left: activeCenterX - 30.0,
                top: 0,
                child: GestureDetector(
                  onTap: () {
                    if (selectedIndex == 4) {
                      onOpenMenu();
                    }
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFFFFDF7A),
                          AppColors.darkHarvestGold,
                          Color(0xFFB8860B),
                        ],
                        center: Alignment(0.0, -0.2),
                        radius: 0.9,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.darkPrimaryGold.withOpacity(0.45),
                          blurRadius: 18,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: items[selectedIndex].isHen
                          ? const HenIcon(
                              size: 28,
                              color: Color(0xFF0B1B3D),
                            )
                          : Icon(
                              items[selectedIndex].icon,
                              size: 28,
                              color: const Color(0xFF0B1B3D),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NavItem {
  final IconData? icon;
  final bool isHen;
  final String label;

  _NavItem({this.icon, this.isHen = false, required this.label});
}

class _CurvedNavBarPainter extends CustomPainter {
  final Color backgroundColor;
  final double activeX;
  final double notchRadius;

  _CurvedNavBarPainter({
    required this.backgroundColor,
    required this.activeX,
    required this.notchRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    // Top border stroke
    final strokePaint = Paint()
      ..color = const Color(0x33D4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    const cornerRadius = 24.0;
    final w = size.width;
    final h = size.height;

    final notchWidth = notchRadius * 2.2;
    final leftDipStart = (activeX - notchWidth).clamp(cornerRadius, w - cornerRadius);
    final rightDipEnd = (activeX + notchWidth).clamp(cornerRadius, w - cornerRadius);
    final dipDepth = notchRadius * 0.92;

    // Start at bottom left
    path.moveTo(0, h);
    path.lineTo(0, cornerRadius);

    // Top-left rounded corner
    path.quadraticBezierTo(0, 0, cornerRadius, 0);

    // Line to left side of the notch
    path.lineTo(leftDipStart, 0);

    // Smooth cutout curve down and around the active button
    path.cubicTo(
      leftDipStart + (notchWidth * 0.4), 0,
      activeX - (notchRadius * 0.8), dipDepth,
      activeX, dipDepth,
    );
    path.cubicTo(
      activeX + (notchRadius * 0.8), dipDepth,
      rightDipEnd - (notchWidth * 0.4), 0,
      rightDipEnd, 0,
    );

    // Line to top-right corner
    path.lineTo(w - cornerRadius, 0);

    // Top-right rounded corner
    path.quadraticBezierTo(w, 0, w, cornerRadius);

    // Bottom right
    path.lineTo(w, h);
    path.close();

    // Draw shadow
    canvas.drawShadow(path, Colors.black.withOpacity(0.5), 8.0, true);

    // Draw bar background
    canvas.drawPath(path, paint);

    // Draw subtle top stroke
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _CurvedNavBarPainter oldDelegate) {
    return oldDelegate.activeX != activeX ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

