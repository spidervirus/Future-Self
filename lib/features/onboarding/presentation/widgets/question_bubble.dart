import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:future_self/app/theme/cosmic_dream_theme.dart';
import 'package:future_self/features/onboarding/domain/entities/onboarding_question.dart';

class QuestionBubble extends StatefulWidget {
  final OnboardingQuestion question;
  final bool isVisible;
  final VoidCallback? onTap;

  const QuestionBubble({
    super.key,
    required this.question,
    this.isVisible = true,
    this.onTap,
  });

  @override
  State<QuestionBubble> createState() => _QuestionBubbleState();
}

class _QuestionBubbleState extends State<QuestionBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatingController;
  late Animation<double> _floatingAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _floatingAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    _floatingController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _getFloatingOffset()),
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                padding: const EdgeInsets.all(24),
                decoration: _buildBubbleDecoration(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildQuestionIcon(),
                    const SizedBox(height: 16),
                    Text(
                      widget.question.questionText,
                      style: _buildQuestionTextStyle(context),
                      textAlign: TextAlign.center,
                    ),
                    if (_shouldShowHint()) ...[
                      const SizedBox(height: 12),
                      _buildHintText(context),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    )
        .animate(target: widget.isVisible ? 1 : 0)
        .scale(
          begin: const Offset(0.3, 0.3),
          end: const Offset(1.0, 1.0),
          duration: 800.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn(
          duration: 600.ms,
          curve: Curves.easeOut,
        );
  }

  double _getFloatingOffset() {
    return (_floatingAnimation.value * 2 - 1) * 8;
  }

  BoxDecoration _buildBubbleDecoration() {
    return BoxDecoration(
      gradient: CosmicDreamTheme.questionBubbleGradient,
      borderRadius: BorderRadius.circular(32),
      boxShadow: [
        if (_isHovered)
          BoxShadow(
            color: CosmicDreamTheme.cosmicTeal.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        BoxShadow(
          color: CosmicDreamTheme.primary.withOpacity(0.3),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      border: _isHovered
          ? Border.all(
              color: CosmicDreamTheme.glowBlue.withOpacity(0.6),
              width: 2,
            )
          : null,
    );
  }

  Widget _buildQuestionIcon() {
    IconData iconData;
    switch (widget.question.type) {
      case QuestionType.date:
        iconData = Icons.calendar_today_rounded;
        break;
      case QuestionType.dropdown:
        iconData = Icons.list_rounded;
        break;
      case QuestionType.image:
        iconData = Icons.photo_camera_rounded;
        break;
      case QuestionType.country:
        iconData = Icons.public_rounded;
        break;
      case QuestionType.text:
        iconData = Icons.chat_bubble_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        iconData,
        color: CosmicDreamTheme.text,
        size: 24,
      ),
    );
  }

  TextStyle _buildQuestionTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.headlineSmall!.copyWith(
      color: CosmicDreamTheme.text,
      fontWeight: FontWeight.w600,
      height: 1.3,
      shadows: [
        Shadow(
          color: Colors.black.withOpacity(0.3),
          offset: const Offset(0, 2),
          blurRadius: 4,
        ),
      ],
    );
  }

  bool _shouldShowHint() {
    return widget.question.type != QuestionType.text &&
        widget.question.options != null;
  }

  Widget _buildHintText(BuildContext context) {
    String hintText = '';
    switch (widget.question.type) {
      case QuestionType.date:
        hintText = 'Tap to select a date';
        break;
      case QuestionType.dropdown:
        hintText = 'Choose from the options below';
        break;
      case QuestionType.image:
        hintText = 'Upload or skip to continue';
        break;
      case QuestionType.country:
        hintText = 'Select your country from the picker';
        break;
      default:
        hintText = 'Type your answer below';
    }

    return Text(
      hintText,
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: CosmicDreamTheme.text.withOpacity(0.8),
            fontStyle: FontStyle.italic,
          ),
      textAlign: TextAlign.center,
    );
  }

  @override
  void dispose() {
    _floatingController.dispose();
    super.dispose();
  }
}
