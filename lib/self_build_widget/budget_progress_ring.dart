import 'package:flutter/material.dart';
import 'dart:math';

class BudgetProgressRing extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final Color color;
  final double size;
  final String label;

  const BudgetProgressRing({
    Key? key,
    required this.value,
    this.min = 1000,
    this.max = 5000,
    required this.color,
    this.size = 280,
    this.label = 'Budget',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentage = ((value - min) / (max - min)).clamp(0.0, 1.0);
    final sweepAngle = 2 * pi * percentage;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _SolidRingPainter(sweepAngle, color),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: TextStyle(fontSize: 20, color: Colors.grey[600])),
              SizedBox(height: 10),
              Text(
                '${value.toStringAsFixed(0)} Wh',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SolidRingPainter extends CustomPainter {
  final double sweepAngle;
  final Color color;

  _SolidRingPainter(this.sweepAngle, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final backgroundPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final foregroundPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -pi / 2, sweepAngle, false, foregroundPaint);
  }

  @override
  bool shouldRepaint(_SolidRingPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle || oldDelegate.color != color;
  }
}
