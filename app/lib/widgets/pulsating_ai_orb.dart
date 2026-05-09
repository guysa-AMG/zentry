import 'dart:math';
import 'package:flutter/material.dart';

class PulsatingAiOrb extends StatefulWidget {
  final double size;
  final Color color;
  final bool isActive;
  final double volume;

  const PulsatingAiOrb({
    super.key,
    this.size = 150.0,
    this.color = const Color(0xFF9FFC2D),
    this.isActive = false,
    this.volume = 0.0,
  });

  @override
  PulsatingAiOrbState createState() => PulsatingAiOrbState();
}

class PulsatingAiOrbState extends State<PulsatingAiOrb>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.isActive ? 800 : 2000),
    )..repeat(reverse: true);
    
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.isActive ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(covariant PulsatingAiOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.duration = const Duration(milliseconds: 800);
        _controller.repeat(reverse: true);
        _scaleController.forward();
      } else {
        _controller.duration = const Duration(seconds: 2);
        _controller.repeat(reverse: true);
        _scaleController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _scaleController]),
      builder: (context, child) {
        // Base scale + pulse + voice volume reactivity
        final pulseScale = _controller.value * 0.05;
        final voiceScale = widget.volume * 0.5;
        final scale = 1.0 + (_scaleController.value * 0.2) + pulseScale + voiceScale;
        
        final currentSize = widget.size * scale;
        final intensity = (widget.isActive ? 1.0 : 0.6) + (widget.volume * 0.4);

        return Container(
          width: currentSize,
          height: currentSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.color.withValues(alpha: (0.8 * intensity).clamp(0.0, 1.0)),
                widget.color.withValues(alpha: (0.4 * _controller.value * intensity).clamp(0.0, 1.0)),
                Colors.transparent,
              ],
              stops: const [0.2, 0.6, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: (intensity * _controller.value).clamp(0.0, 1.0)),
                blurRadius: 40 * _controller.value + 20 + (widget.volume * 30),
                spreadRadius: 10 * _controller.value * scale,
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
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

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
