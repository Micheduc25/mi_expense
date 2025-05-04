import 'package:flutter/material.dart';
import 'dart:math' as math;

class MiExpenseAppIcon extends StatelessWidget {
  final double size;
  final bool isOutlined;

  const MiExpenseAppIcon({
    super.key,
    this.size = 192.0,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color:
            isOutlined ? Colors.white : Theme.of(context).colorScheme.primary,
        border: isOutlined
            ? Border.all(
                color: Theme.of(context).colorScheme.primary, width: size / 48)
            : null,
        borderRadius: BorderRadius.circular(size / 4),
        boxShadow: isOutlined
            ? null
            : [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: size / 8,
                  spreadRadius: size / 48,
                ),
              ],
      ),
      child: CustomPaint(
        size: Size(size, size),
        painter: MiExpenseIconPainter(
          primaryColor: isOutlined
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onPrimary,
          accentColor: Theme.of(context).colorScheme.secondary,
          isOutlined: isOutlined,
        ),
      ),
    );
  }
}

class MiExpenseIconPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;
  final bool isOutlined;

  MiExpenseIconPainter({
    required this.primaryColor,
    required this.accentColor,
    this.isOutlined = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;
    final strokeWidth = size.width / 16;

    // 1. Paint the coin/circle
    final coinPaint = Paint()
      ..color = primaryColor.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, coinPaint);

    // 2. Draw the 'M' letter stylized as a money chart line
    // Use a dark color for the M in outlined mode to ensure visibility
    final pathColor = isOutlined ? Colors.black87 : accentColor;

    final pathPaint = Paint()
      ..color = pathColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    // Starting point of M (bottom left)
    path.moveTo(center.dx - radius * 0.6, center.dy + radius * 0.5);

    // First up stroke of M
    path.lineTo(center.dx - radius * 0.3, center.dy - radius * 0.5);

    // Middle down stroke of M (also looks like a decreasing chart)
    path.lineTo(center.dx, center.dy);

    // Last up stroke of M (also looks like increasing chart)
    path.lineTo(center.dx + radius * 0.3, center.dy - radius * 0.3);

    // End point of M (bottom right)
    path.lineTo(center.dx + radius * 0.6, center.dy + radius * 0.5);

    canvas.drawPath(path, pathPaint);

    // 3. Add small horizontal lines to represent expense/income list
    // Use the same color as the M for consistency
    final linePaint = Paint()
      ..color = pathColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth / 2.5
      ..strokeCap = StrokeCap.round;

    // Draw 3 small horizontal lines on the right side with more spacing
    for (int i = 0; i < 3; i++) {
      final yOffset = center.dy - radius * 0.25 + (i * radius * 0.25);
      canvas.drawLine(
        Offset(center.dx + radius * 0.15, yOffset),
        Offset(center.dx + radius * 0.6, yOffset),
        linePaint,
      );
    }

    // 4. Add a small sound wave icon at the bottom to represent voice commands
    final soundWavePaint = Paint()
      ..color = pathColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth / 2.0
      ..strokeCap = StrokeCap.round;

    // Center wave
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + radius * 0.7),
        width: radius * 0.3,
        height: radius * 0.3,
      ),
      math.pi * 1.2,
      math.pi * 0.6,
      false,
      soundWavePaint,
    );

    // Left wave
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + radius * 0.7),
        width: radius * 0.5,
        height: radius * 0.5,
      ),
      math.pi * 1.3,
      math.pi * 0.4,
      false,
      soundWavePaint,
    );

    // Right wave
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + radius * 0.7),
        width: radius * 0.7,
        height: radius * 0.7,
      ),
      math.pi * 1.4,
      math.pi * 0.2,
      false,
      soundWavePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Widget to preview the app icon
class AppIconPreview extends StatelessWidget {
  const AppIconPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Expense App Icon'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'App Icon Preview',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const MiExpenseAppIcon(size: 120),
                    const SizedBox(height: 16),
                    Text(
                      'Filled',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const MiExpenseAppIcon(
                      size: 120,
                      isOutlined: true,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Outlined',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 64),
            const Text(
              'Mi Expense',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track your finances with voice',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
