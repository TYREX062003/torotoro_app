import 'package:flutter/material.dart';

// 🎨 Colores
const kBeige = Color(0xFFF2E8D5);
const kOlive = Color(0xFF6B7C3F);
const kBrown = Color(0xFF5B4636);

/// Widget personalizado: Huella de Dinosaurio estilo Material
class DinoFootprint extends StatelessWidget {
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;

  const DinoFootprint({
    super.key,
    this.size = 48,
    this.backgroundColor = kOlive,
    this.foregroundColor = kBrown,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: CustomPaint(
        painter: _DinoFootprintPainter(color: foregroundColor),
      ),
    );
  }
}

class _DinoFootprintPainter extends CustomPainter {
  final Color color;

  _DinoFootprintPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final width = size.width;
    final height = size.height;
    final centerX = width / 2;
    final centerY = height / 2;

    // 🦖 Huella de dinosaurio tridáctila (3 dedos)
    
    // Dedo/garra izquierda
    final leftToe = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(centerX - width * 0.20, centerY - height * 0.12),
        width: width * 0.18,
        height: height * 0.28,
      ));
    canvas.save();
    canvas.translate(centerX - width * 0.20, centerY - height * 0.12);
    canvas.rotate(-0.4);
    canvas.translate(-(centerX - width * 0.20), -(centerY - height * 0.12));
    canvas.drawPath(leftToe, paint);
    canvas.restore();

    // Dedo/garra central
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, centerY - height * 0.18),
        width: width * 0.20,
        height: height * 0.35,
      ),
      paint,
    );

    // Dedo/garra derecha
    final rightToe = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(centerX + width * 0.20, centerY - height * 0.12),
        width: width * 0.18,
        height: height * 0.28,
      ));
    canvas.save();
    canvas.translate(centerX + width * 0.20, centerY - height * 0.12);
    canvas.rotate(0.4);
    canvas.translate(-(centerX + width * 0.20), -(centerY - height * 0.12));
    canvas.drawPath(rightToe, paint);
    canvas.restore();

    // Base/talón principal
    final heelPath = Path();
    heelPath.moveTo(centerX - width * 0.25, centerY);
    heelPath.quadraticBezierTo(
      centerX - width * 0.28,
      centerY + height * 0.15,
      centerX - width * 0.22,
      centerY + height * 0.28,
    );
    heelPath.quadraticBezierTo(
      centerX - width * 0.15,
      centerY + height * 0.35,
      centerX,
      centerY + height * 0.36,
    );
    heelPath.quadraticBezierTo(
      centerX + width * 0.15,
      centerY + height * 0.35,
      centerX + width * 0.22,
      centerY + height * 0.28,
    );
    heelPath.quadraticBezierTo(
      centerX + width * 0.28,
      centerY + height * 0.15,
      centerX + width * 0.25,
      centerY,
    );
    heelPath.quadraticBezierTo(
      centerX,
      centerY - height * 0.02,
      centerX - width * 0.25,
      centerY,
    );
    
    canvas.drawPath(heelPath, paint);

    // Almohadilla central inferior
    final detailPaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, centerY + height * 0.22),
        width: width * 0.12,
        height: height * 0.10,
      ),
      detailPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}