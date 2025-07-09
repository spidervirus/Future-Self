import 'dart:math';
import 'package:flutter/material.dart';

class BubbleAnimationManager {
  final TickerProvider vsync;

  // Core animation controllers
  late final AnimationController floatingController;
  late final AnimationController entryController;
  late final AnimationController selectionController;
  late final AnimationController transitionController;
  late final AnimationController celebrationController;
  late final AnimationController starfieldController;

  // Animations
  late final Animation<double> floatingAnimation;
  late final Animation<double> entryAnimation;
  late final Animation<double> selectionAnimation;
  late final Animation<double> transitionAnimation;
  late final Animation<double> celebrationAnimation;
  late final Animation<double> starfieldAnimation;

  // Bubble-specific animations
  late final Animation<double> bubbleScale;
  late final Animation<double> bubbleGlow;
  late final Animation<Offset> bubbleFloat;

  BubbleAnimationManager({required this.vsync}) {
    _initializeControllers();
    _createAnimations();
    _startContinuousAnimations();
  }

  void _initializeControllers() {
    floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: vsync,
    );

    entryController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: vsync,
    );

    selectionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: vsync,
    );

    transitionController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: vsync,
    );

    celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: vsync,
    );

    starfieldController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: vsync,
    );
  }

  void _createAnimations() {
    // Floating animation for continuous gentle movement
    floatingAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: floatingController,
      curve: Curves.easeInOut,
    ));

    // Entry animation for bubble appearance
    entryAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: entryController,
      curve: Curves.elasticOut,
    ));

    // Selection animation for bubble interaction
    selectionAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: selectionController,
      curve: Curves.bounceOut,
    ));

    // Transition animation for page changes
    transitionAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: transitionController,
      curve: Curves.easeInOutCubic,
    ));

    // Celebration animation for achievements
    celebrationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: celebrationController,
      curve: Curves.elasticOut,
    ));

    // Starfield animation for background
    starfieldAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: starfieldController,
      curve: Curves.linear,
    ));

    // Bubble-specific composite animations
    bubbleScale = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: entryController,
      curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
    ));

    bubbleGlow = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: selectionController,
      curve: Curves.easeOut,
    ));

    bubbleFloat = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -8),
    ).animate(CurvedAnimation(
      parent: floatingController,
      curve: Curves.easeInOut,
    ));
  }

  void _startContinuousAnimations() {
    // Start infinite floating animation
    floatingController.repeat(reverse: true);

    // Start infinite starfield animation
    starfieldController.repeat();
  }

  // Public methods for controlling animations
  Future<void> animateBubbleEntry({int delay = 0}) async {
    if (delay > 0) {
      await Future.delayed(Duration(milliseconds: delay));
    }
    await entryController.forward();
  }

  Future<void> animateBubbleSelection() async {
    await selectionController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    await selectionController.reverse();
  }

  Future<void> animatePageTransition() async {
    await transitionController.forward();
    await transitionController.reverse();
  }

  Future<void> animateCelebration() async {
    await celebrationController.forward();
    await celebrationController.reverse();
  }

  void resetBubbleEntry() {
    entryController.reset();
  }

  void resetTransition() {
    transitionController.reset();
  }

  // Utility methods for creating staggered animations
  List<Animation<double>> createStaggeredEntryAnimations(int count) {
    final List<Animation<double>> animations = [];

    for (int i = 0; i < count; i++) {
      final begin = i * 0.1;
      final end = begin + 0.3;

      animations.add(
        Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: entryController,
            curve: Interval(
              begin.clamp(0.0, 1.0),
              end.clamp(0.0, 1.0),
              curve: Curves.elasticOut,
            ),
          ),
        ),
      );
    }

    return animations;
  }

  // Particle system animations
  Animation<double> createParticleAnimation({
    required double delay,
    required double duration,
  }) {
    return TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(
      CurvedAnimation(
        parent: celebrationController,
        curve: Interval(
          delay,
          (delay + duration).clamp(0.0, 1.0),
        ),
      ),
    );
  }

  // Cosmic-specific animations
  double getFloatingOffset() {
    return sin(floatingAnimation.value * 2 * pi) * 8;
  }

  double getStarfieldOffset() {
    return starfieldAnimation.value * 100;
  }

  double getBubbleHoverScale(bool isHovered) {
    return isHovered ? 1.1 : 1.0;
  }

  Color getBubbleGlowColor(bool isSelected, Color baseColor) {
    if (!isSelected) return baseColor;

    final intensity = 0.5 + (sin(floatingAnimation.value * 2 * pi) * 0.3);
    return Color.lerp(baseColor, Colors.white, intensity * 0.3) ?? baseColor;
  }

  void dispose() {
    floatingController.dispose();
    entryController.dispose();
    selectionController.dispose();
    transitionController.dispose();
    celebrationController.dispose();
    starfieldController.dispose();
  }
}

// Extension for easier animation access
extension BubbleAnimationExtension on BubbleAnimationManager {
  Widget buildAnimatedBubble({
    required Widget child,
    required bool isVisible,
    required bool isSelected,
    required bool isHovered,
    int entryDelay = 0,
  }) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        floatingController,
        entryController,
        selectionController,
      ]),
      builder: (context, _) {
        final scale = isVisible ? bubbleScale.value : 0.0;
        final hoverScale = getBubbleHoverScale(isHovered);
        final selectionScale =
            isSelected ? 1.0 + (selectionAnimation.value * 0.1) : 1.0;
        final floatingOffset = getFloatingOffset();

        return Transform.translate(
          offset: Offset(0, floatingOffset),
          child: Transform.scale(
            scale: scale * hoverScale * selectionScale,
            child: child,
          ),
        );
      },
    );
  }
}
