import 'dart:math';
import 'package:flutter/material.dart';

class PulsatingAiOrb extends StatefulWidget {
  final double size;
  final Color color;

  const PulsatingAiOrb({
    super.key,
    this.size = 150.0,
    this.color = Colors.cyanAccent,
  });

  @override
  PulsatingAiOrbState createState() => PulsatingAiOrbState();
}

class PulsatingAiOrbState extends State<PulsatingAiOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.color.withValues(alpha: 0.8),
                widget.color.withValues(alpha: 0.4 * _controller.value),
                Colors.transparent,
              ],
              stops: const [0.2, 0.6, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.6 * _controller.value),
                blurRadius: 40 * _controller.value + 20,
                spreadRadius: 10 * _controller.value,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _OrbCorePainter(
              animationValue: _controller.value,
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}

class _OrbCorePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _OrbCorePainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final coreRadius = size.width / 4;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8 + 0.2 * animationValue)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawCircle(center, coreRadius, paint);

    // Draw some inner energy rings
    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < 3; i++) {
      final radius = coreRadius + (10 * i) + (5 * animationValue * sin(i));
      canvas.drawCircle(center, radius, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbCorePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
