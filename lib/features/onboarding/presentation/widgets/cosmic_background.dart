import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:future_self/app/theme/cosmic_dream_theme.dart';
import 'bubble_animation_manager.dart';

class CosmicBackground extends StatefulWidget {
  final Widget child;
  final int currentStep;
  final int totalSteps;

  const CosmicBackground({
    super.key,
    required this.child,
    this.currentStep = 0,
    this.totalSteps = 10,
  });

  @override
  State<CosmicBackground> createState() => _CosmicBackgroundState();
}

class _CosmicBackgroundState extends State<CosmicBackground>
    with TickerProviderStateMixin {
  late BubbleAnimationManager animationManager;
  late AnimationController colorController;
  late Animation<Color?> backgroundColorAnimation;

  @override
  void initState() {
    super.initState();
    animationManager = BubbleAnimationManager(vsync: this);

    colorController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _createColorAnimation();
  }

  void _createColorAnimation() {
    backgroundColorAnimation = ColorTween(
      begin: CosmicDreamTheme.background,
      end: CosmicDreamTheme.deepSpace,
    ).animate(CurvedAnimation(
      parent: colorController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(CosmicBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentStep != oldWidget.currentStep) {
      _updateBackgroundColor();
    }
  }

  void _updateBackgroundColor() {
    final progress = widget.currentStep / widget.totalSteps;
    colorController.animateTo(progress);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        animationManager.starfieldController,
        colorController,
      ]),
      builder: (context, _) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                backgroundColorAnimation.value ?? CosmicDreamTheme.background,
                CosmicDreamTheme.deepSpace,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Background star layers (parallax effect)
              _buildStarLayer(
                starCount: 100,
                speed: 0.2,
                size: 1.0,
                opacity: 0.3,
              ),
              _buildStarLayer(
                starCount: 60,
                speed: 0.5,
                size: 1.5,
                opacity: 0.5,
              ),
              _buildStarLayer(
                starCount: 30,
                speed: 0.8,
                size: 2.0,
                opacity: 0.7,
              ),

              // Nebula effect
              _buildNebulaLayer(),

              // Floating particles
              _buildParticleLayer(),

              // Content
              widget.child,
            ],
          ),
        );
      },
    );
  }

  Widget _buildStarLayer({
    required int starCount,
    required double speed,
    required double size,
    required double opacity,
  }) {
    return CustomPaint(
      size: Size.infinite,
      painter: StarfieldPainter(
        starCount: starCount,
        animationValue: animationManager.starfieldAnimation.value,
        speed: speed,
        starSize: size,
        opacity: opacity,
      ),
    );
  }

  Widget _buildNebulaLayer() {
    return CustomPaint(
      size: Size.infinite,
      painter: NebulaPainter(
        animationValue: animationManager.starfieldAnimation.value,
        progress: widget.currentStep / widget.totalSteps,
      ),
    );
  }

  Widget _buildParticleLayer() {
    return CustomPaint(
      size: Size.infinite,
      painter: ParticlePainter(
        animationValue: animationManager.starfieldAnimation.value,
      ),
    );
  }

  @override
  void dispose() {
    animationManager.dispose();
    colorController.dispose();
    super.dispose();
  }
}

class StarfieldPainter extends CustomPainter {
  final int starCount;
  final double animationValue;
  final double speed;
  final double starSize;
  final double opacity;

  StarfieldPainter({
    required this.starCount,
    required this.animationValue,
    required this.speed,
    required this.starSize,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CosmicDreamTheme.stardust.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    final random = Random(42); // Fixed seed for consistent star positions

    for (int i = 0; i < starCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = (random.nextDouble() * size.height +
              animationValue * size.height * speed) %
          size.height;

      // Twinkling effect
      final twinkle = sin(animationValue * 2 * pi + i) * 0.3 + 0.7;
      paint.color = CosmicDreamTheme.stardust.withOpacity(opacity * twinkle);

      canvas.drawCircle(
        Offset(x, y),
        starSize * (0.5 + random.nextDouble() * 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(StarfieldPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}

class NebulaPainter extends CustomPainter {
  final double animationValue;
  final double progress;

  NebulaPainter({
    required this.animationValue,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

    // Create shifting nebula clouds
    final random = Random(123);

    for (int i = 0; i < 3; i++) {
      final centerX = size.width * (0.2 + i * 0.3);
      final centerY = size.height * (0.3 + sin(animationValue + i) * 0.2);

      final gradient = RadialGradient(
        colors: [
          _getNebulaColor(i, progress).withOpacity(0.1),
          _getNebulaColor(i, progress).withOpacity(0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      );

      paint.shader = gradient.createShader(
        Rect.fromCircle(
          center: Offset(centerX, centerY),
          radius: size.width * 0.4,
        ),
      );

      canvas.drawCircle(
        Offset(centerX, centerY),
        size.width * 0.4,
        paint,
      );
    }
  }

  Color _getNebulaColor(int index, double progress) {
    final colors = [
      CosmicDreamTheme.primary,
      CosmicDreamTheme.nebulaPink,
      CosmicDreamTheme.cosmicTeal,
    ];

    final baseColor = colors[index % colors.length];
    final targetColor = CosmicDreamTheme.glowBlue;

    return Color.lerp(baseColor, targetColor, progress) ?? baseColor;
  }

  @override
  bool shouldRepaint(NebulaPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue ||
        progress != oldDelegate.progress;
  }
}

class ParticlePainter extends CustomPainter {
  final double animationValue;

  ParticlePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CosmicDreamTheme.accent.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final random = Random(789);

    // Floating dust particles
    for (int i = 0; i < 20; i++) {
      final x = (random.nextDouble() * size.width +
              animationValue * 50 * (i % 2 == 0 ? 1 : -1)) %
          size.width;
      final y = (random.nextDouble() * size.height + animationValue * 30) %
          size.height;

      final particleOpacity = sin(animationValue * 2 + i) * 0.3 + 0.4;
      paint.color = CosmicDreamTheme.accent.withOpacity(particleOpacity * 0.3);

      canvas.drawCircle(
        Offset(x, y),
        0.5 + random.nextDouble(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}
