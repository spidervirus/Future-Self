import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:future_self/app/theme/cosmic_dream_theme.dart';

class ProgressConstellation extends StatefulWidget {
  final int currentStep;
  final int totalSteps;
  final double height;

  const ProgressConstellation({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.height = 80,
  });

  @override
  State<ProgressConstellation> createState() => _ProgressConstellationState();
}

class _ProgressConstellationState extends State<ProgressConstellation>
    with TickerProviderStateMixin {
  late AnimationController _twinkleController;
  late AnimationController _connectionController;
  late Animation<double> _twinkleAnimation;
  late Animation<double> _connectionAnimation;

  List<Offset> _starPositions = [];
  List<bool> _starStates = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateStarPositions();
  }

  void _initializeAnimations() {
    _twinkleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _connectionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _twinkleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _twinkleController,
      curve: Curves.easeInOut,
    ));

    _connectionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _connectionController,
      curve: Curves.easeOut,
    ));

    _twinkleController.repeat(reverse: true);
  }

  void _generateStarPositions() {
    _starPositions.clear();
    _starStates.clear();

    final random = Random(42); // Fixed seed for consistent positions

    for (int i = 0; i < widget.totalSteps; i++) {
      // Create a constellation-like pattern
      final progress = i / (widget.totalSteps - 1);
      final x = 0.1 + progress * 0.8; // Keep stars within bounds
      final y = 0.3 + sin(progress * pi * 2) * 0.4; // Sine wave pattern

      // Add some randomness for natural look
      final offsetX = (random.nextDouble() - 0.5) * 0.1;
      final offsetY = (random.nextDouble() - 0.5) * 0.2;

      _starPositions.add(Offset(x + offsetX, y + offsetY));
      _starStates.add(i < widget.currentStep);
    }
  }

  @override
  void didUpdateWidget(ProgressConstellation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentStep != oldWidget.currentStep ||
        widget.totalSteps != oldWidget.totalSteps) {
      _generateStarPositions();
      if (widget.currentStep > oldWidget.currentStep) {
        _connectionController.forward(from: 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: Listenable.merge([_twinkleAnimation, _connectionAnimation]),
        builder: (context, child) {
          return CustomPaint(
            size: Size.infinite,
            painter: ConstellationPainter(
              starPositions: _starPositions,
              currentStep: widget.currentStep,
              totalSteps: widget.totalSteps,
              twinkleValue: _twinkleAnimation.value,
              connectionValue: _connectionAnimation.value,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _twinkleController.dispose();
    _connectionController.dispose();
    super.dispose();
  }
}

class ConstellationPainter extends CustomPainter {
  final List<Offset> starPositions;
  final int currentStep;
  final int totalSteps;
  final double twinkleValue;
  final double connectionValue;

  ConstellationPainter({
    required this.starPositions,
    required this.currentStep,
    required this.totalSteps,
    required this.twinkleValue,
    required this.connectionValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawConnections(canvas, size);
    _drawStars(canvas, size);
    _drawProgressLabel(canvas, size);
  }

  void _drawConnections(Canvas canvas, Size size) {
    if (starPositions.length < 2) return;

    final connectionPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..shader = LinearGradient(
        colors: [
          CosmicDreamTheme.primary.withOpacity(0.6),
          CosmicDreamTheme.cosmicTeal.withOpacity(0.4),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Draw connections between completed stars
    for (int i = 0; i < currentStep - 1; i++) {
      final start = Offset(
        starPositions[i].dx * size.width,
        starPositions[i].dy * size.height,
      );
      final end = Offset(
        starPositions[i + 1].dx * size.width,
        starPositions[i + 1].dy * size.height,
      );

      // Animate the connection line
      final animatedEnd = Offset.lerp(start, end, connectionValue) ?? end;

      _drawAnimatedLine(canvas, start, animatedEnd, connectionPaint);
    }
  }

  void _drawAnimatedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    // Create a gentle curve instead of straight line
    final controlPoint = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2 - 20,
    );

    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      end.dx,
      end.dy,
    );

    canvas.drawPath(path, paint);

    // Add sparkle effect at the end
    _drawSparkle(canvas, end, paint.color);
  }

  void _drawStars(Canvas canvas, Size size) {
    for (int i = 0; i < starPositions.length; i++) {
      final position = Offset(
        starPositions[i].dx * size.width,
        starPositions[i].dy * size.height,
      );

      _drawStar(canvas, position, i);
    }
  }

  void _drawStar(Canvas canvas, Offset position, int index) {
    final isCompleted = index < currentStep;
    final isCurrent = index == currentStep;
    final isUpcoming = index > currentStep;

    // Base star properties
    double starSize = 8;
    Color starColor = CosmicDreamTheme.stardust.withOpacity(0.3);
    double glowRadius = 0;

    if (isCompleted) {
      starSize = 12;
      starColor = CosmicDreamTheme.cosmicTeal;
      glowRadius = 15;
    } else if (isCurrent) {
      starSize = 10 + sin(twinkleValue * 2 * pi) * 2;
      starColor = CosmicDreamTheme.primary;
      glowRadius = 12 + sin(twinkleValue * 2 * pi) * 3;
    }

    // Draw glow effect
    if (glowRadius > 0) {
      final glowPaint = Paint()
        ..color = starColor.withOpacity(0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius);

      canvas.drawCircle(position, glowRadius, glowPaint);
    }

    // Draw star shape
    _drawStarShape(canvas, position, starSize, starColor);

    // Draw pulse for current star
    if (isCurrent) {
      _drawPulse(canvas, position, starSize * 2);
    }
  }

  void _drawStarShape(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final outerRadius = size;
    final innerRadius = size * 0.4;
    final angleStep = pi / 5; // 5-pointed star

    for (int i = 0; i < 10; i++) {
      final angle = i * angleStep - pi / 2; // Start from top
      final radius = i.isEven ? outerRadius : innerRadius;
      final x = center.dx + cos(angle) * radius;
      final y = center.dy + sin(angle) * radius;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);

    // Add inner highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, size * 0.3, highlightPaint);
  }

  void _drawPulse(Canvas canvas, Offset center, double maxRadius) {
    final pulseRadius = maxRadius * twinkleValue;
    final pulsePaint = Paint()
      ..color = CosmicDreamTheme.primary.withOpacity(0.3 * (1 - twinkleValue))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, pulseRadius, pulsePaint);
  }

  void _drawSparkle(Canvas canvas, Offset position, Color? color) {
    final sparklePaint = Paint()
      ..color = color ?? CosmicDreamTheme.accent
      ..style = PaintingStyle.fill;

    // Draw small sparkle cross
    final sparkleSize = 3;
    canvas.drawLine(
      Offset(position.dx - sparkleSize, position.dy),
      Offset(position.dx + sparkleSize, position.dy),
      sparklePaint,
    );
    canvas.drawLine(
      Offset(position.dx, position.dy - sparkleSize),
      Offset(position.dx, position.dy + sparkleSize),
      sparklePaint,
    );
  }

  void _drawProgressLabel(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$currentStep / $totalSteps',
        style: TextStyle(
          color: CosmicDreamTheme.text.withOpacity(0.8),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final position = Offset(
      size.width - textPainter.width - 16,
      size.height - textPainter.height - 8,
    );

    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(ConstellationPainter oldDelegate) {
    return currentStep != oldDelegate.currentStep ||
        twinkleValue != oldDelegate.twinkleValue ||
        connectionValue != oldDelegate.connectionValue ||
        starPositions != oldDelegate.starPositions;
  }
}

// Achievement celebration widget for milestone completions
class ConstellationAchievement extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool isVisible;

  const ConstellationAchievement({
    super.key,
    required this.title,
    required this.subtitle,
    this.isVisible = false,
  });

  @override
  State<ConstellationAchievement> createState() =>
      _ConstellationAchievementState();
}

class _ConstellationAchievementState extends State<ConstellationAchievement> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CosmicDreamTheme.primary.withOpacity(0.2),
            CosmicDreamTheme.cosmicTeal.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: CosmicDreamTheme.cosmicTeal.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            color: CosmicDreamTheme.accent,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    color: CosmicDreamTheme.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    color: CosmicDreamTheme.text.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(target: widget.isVisible ? 1 : 0)
        .scale(
          begin: const Offset(0.8, 0.8),
          duration: 600.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.3, duration: 500.ms, curve: Curves.easeOut);
  }
}
