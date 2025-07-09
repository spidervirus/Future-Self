import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:future_self/app/theme/cosmic_dream_theme.dart';

class ResponseBubble extends StatefulWidget {
  final String text;
  final bool isSelected;
  final bool isVisible;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? customColor;
  final int animationDelay;

  const ResponseBubble({
    super.key,
    required this.text,
    this.isSelected = false,
    this.isVisible = true,
    this.onTap,
    this.icon,
    this.customColor,
    this.animationDelay = 0,
  });

  @override
  State<ResponseBubble> createState() => _ResponseBubbleState();
}

class _ResponseBubbleState extends State<ResponseBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.isSelected) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ResponseBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isSelected ? _pulseAnimation.value : 1.0,
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: widget.onTap,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: _buildBubbleDecoration(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color: CosmicDreamTheme.text,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        widget.text,
                        style: _buildTextStyle(context),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (widget.isSelected) ...[
                      const SizedBox(width: 8),
                      _buildSelectedIndicator(),
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
          duration: 600.ms,
          delay: Duration(milliseconds: widget.animationDelay),
          curve: Curves.elasticOut,
        )
        .fadeIn(
          duration: 400.ms,
          delay: Duration(milliseconds: widget.animationDelay),
          curve: Curves.easeOut,
        )
        .slideY(
          begin: 0.3,
          end: 0,
          duration: 500.ms,
          delay: Duration(milliseconds: widget.animationDelay),
          curve: Curves.easeOut,
        );
  }

  BoxDecoration _buildBubbleDecoration() {
    Gradient gradient;
    Color borderColor = Colors.transparent;
    double borderWidth = 0;

    if (widget.isSelected) {
      gradient = CosmicDreamTheme.selectedBubbleGradient;
      borderColor = CosmicDreamTheme.glowBlue;
      borderWidth = 2;
    } else if (_isHovered) {
      gradient = LinearGradient(
        colors: [
          CosmicDreamTheme.bubbleHover,
          CosmicDreamTheme.bubblePrimary,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      borderColor = CosmicDreamTheme.cosmicTeal.withOpacity(0.5);
      borderWidth = 1;
    } else {
      gradient = widget.customColor != null
          ? LinearGradient(
              colors: [
                widget.customColor!,
                widget.customColor!.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : CosmicDreamTheme.responseBubbleGradient;
    }

    return BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(25),
      border: borderWidth > 0
          ? Border.all(color: borderColor, width: borderWidth)
          : null,
      boxShadow: [
        if (widget.isSelected)
          BoxShadow(
            color: CosmicDreamTheme.cosmicTeal.withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        if (_isHovered && !widget.isSelected)
          BoxShadow(
            color: CosmicDreamTheme.bubbleHover.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        BoxShadow(
          color: Colors.black.withOpacity(_isPressed ? 0.4 : 0.2),
          blurRadius: _isPressed ? 4 : 8,
          offset: Offset(0, _isPressed ? 2 : 4),
        ),
      ],
    );
  }

  TextStyle _buildTextStyle(BuildContext context) {
    return CosmicDreamTheme.bubbleTextStyle(
      context: context,
      isSelected: widget.isSelected,
      fontSize: 14,
    ).copyWith(
      fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
      shadows: [
        Shadow(
          color: Colors.black.withOpacity(0.3),
          offset: const Offset(0, 1),
          blurRadius: 2,
        ),
      ],
    );
  }

  Widget _buildSelectedIndicator() {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: CosmicDreamTheme.text,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: CosmicDreamTheme.glowBlue.withOpacity(0.6),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    ).animate(onPlay: (controller) => controller.repeat()).scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.2, 1.2),
          duration: 1000.ms,
          curve: Curves.easeInOut,
        );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}

class CustomInputBubble extends StatefulWidget {
  final String hintText;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final bool isVisible;
  final int animationDelay;

  const CustomInputBubble({
    super.key,
    required this.hintText,
    this.initialValue,
    this.onChanged,
    this.isVisible = true,
    this.animationDelay = 0,
  });

  @override
  State<CustomInputBubble> createState() => _CustomInputBubbleState();
}

class _CustomInputBubbleState extends State<CustomInputBubble> {
  late TextEditingController _controller;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(() {
      widget.onChanged?.call(_controller.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CosmicDreamTheme.surface.withOpacity(0.8),
            CosmicDreamTheme.surface.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: _isFocused
              ? CosmicDreamTheme.cosmicTeal
              : CosmicDreamTheme.surface,
          width: 2,
        ),
        boxShadow: [
          if (_isFocused)
            BoxShadow(
              color: CosmicDreamTheme.cosmicTeal.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.edit_rounded,
            color: CosmicDreamTheme.text.withOpacity(0.7),
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              style: CosmicDreamTheme.bubbleTextStyle(
                context: context,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: CosmicDreamTheme.text.withOpacity(0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onTap: () => setState(() => _isFocused = true),
              onEditingComplete: () => setState(() => _isFocused = false),
              onSubmitted: (_) => setState(() => _isFocused = false),
            ),
          ),
        ],
      ),
    )
        .animate(target: widget.isVisible ? 1 : 0)
        .scale(
          begin: const Offset(0.3, 0.3),
          end: const Offset(1.0, 1.0),
          duration: 600.ms,
          delay: Duration(milliseconds: widget.animationDelay),
          curve: Curves.elasticOut,
        )
        .fadeIn(
          duration: 400.ms,
          delay: Duration(milliseconds: widget.animationDelay),
          curve: Curves.easeOut,
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
