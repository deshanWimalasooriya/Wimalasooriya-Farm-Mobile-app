import 'package:flutter/material.dart';

class HenIcon extends StatelessWidget {
  final double size;
  final Color color;

  const HenIcon({
    super.key,
    this.size = 24.0,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _HenSilhouettePainter(color: color),
    );
  }
}

class _HenSilhouettePainter extends CustomPainter {
  final Color color;

  _HenSilhouettePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Scale to a clean Hen silhouette matching the reference mockup
    final path = Path();
    
    // Comb
    path.moveTo(w * 0.65, h * 0.16);
    path.cubicTo(w * 0.65, h * 0.08, w * 0.75, h * 0.08, w * 0.75, h * 0.16);
    path.cubicTo(w * 0.77, h * 0.10, w * 0.85, h * 0.12, w * 0.82, h * 0.22);

    // Beak
    path.lineTo(w * 0.95, h * 0.28);
    path.lineTo(w * 0.80, h * 0.35);

    // Breast & Belly
    path.cubicTo(w * 0.78, h * 0.55, w * 0.65, h * 0.75, w * 0.45, h * 0.75);

    // Legs
    path.lineTo(w * 0.45, h * 0.92);
    path.moveTo(w * 0.40, h * 0.92);
    path.lineTo(w * 0.50, h * 0.92);

    // Back to body
    path.moveTo(w * 0.45, h * 0.75);
    // Back and Tail feathers
    path.cubicTo(w * 0.25, h * 0.75, w * 0.10, h * 0.65, w * 0.08, h * 0.40);
    path.cubicTo(w * 0.08, h * 0.25, w * 0.20, h * 0.28, w * 0.28, h * 0.45);
    path.cubicTo(w * 0.26, h * 0.30, w * 0.38, h * 0.35, w * 0.42, h * 0.50);

    // Neck
    path.cubicTo(w * 0.50, h * 0.45, w * 0.58, h * 0.30, w * 0.68, h * 0.22);

    canvas.drawPath(path, paint);

    // Eye dot
    canvas.drawCircle(Offset(w * 0.75, h * 0.24), size.width * 0.04, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _HenSilhouettePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

