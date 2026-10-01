import 'package:flutter/material.dart';

/// A custom painted Google "G" logo that renders crisply at any size.
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.22;
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Blue arc (right)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.65, 1.3, false, paint);

    // Green arc (bottom)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.65, 1.45, false, paint);

    // Yellow arc (bottom-left)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.1, 1.3, false, paint);

    // Red arc (top)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 3.4, 1.6, false, paint);

    // Horizontal blue bar to center
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final barRect = Rect.fromLTWH(
      center.dx,
      center.dy - strokeWidth / 2,
      radius + strokeWidth / 2,
      strokeWidth,
    );
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
