import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:future_self/features/onboarding/domain/entities/onboarding_question.dart';
import 'package:future_self/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:future_self/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:future_self/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:future_self/features/onboarding/presentation/widgets/cosmic_background.dart';
import 'package:future_self/features/onboarding/presentation/widgets/question_bubble.dart';
import 'package:future_self/features/onboarding/presentation/widgets/bubble_grid.dart';
import 'package:future_self/features/onboarding/presentation/widgets/progress_constellation.dart';
import 'package:future_self/app/theme/cosmic_dream_theme.dart';
import 'package:future_self/core/di/service_locator.dart';
import 'package:future_self/core/api/services/onboarding_service.dart';

class BubbleOnboardingScreen extends StatefulWidget {
  const BubbleOnboardingScreen({super.key});

  @override
  State<BubbleOnboardingScreen> createState() => _BubbleOnboardingScreenState();
}

class _BubbleOnboardingScreenState extends State<BubbleOnboardingScreen>
    with TickerProviderStateMixin {
  late final OnboardingBloc _bloc;
  late PageController _pageController;
  bool _hasNavigated = false;
  bool _showAchievement = false;
  String _achievementMessage = '';

  @override
  void initState() {
    super.initState();
    _bloc = sl<OnboardingBloc>();
    _pageController = PageController();
    _checkOnboardingBeforeStart();
  }

  Future<void> _checkOnboardingBeforeStart() async {
    if (!mounted) return;

    try {
      final onboardingService = OnboardingService();
      final progress = await onboardingService.getProgress();

      print(
          '📊 Bubble Onboarding: isComplete=${progress.isComplete}, completedSteps=${progress.completedSteps}');

      if (progress.isComplete && mounted && !_hasNavigated) {
        print('🚫 Onboarding already complete, redirecting to home');
        _hasNavigated = true;
        context.go('/home');
        return;
      }

      if (!progress.isComplete && mounted && !_bloc.isClosed) {
        print('✨ Loading existing onboarding progress and starting');
        // Load existing data instead of starting fresh
        _bloc.add(OnboardingDataLoaded());
      }
    } catch (e) {
      print('⚠️ Error checking onboarding status: $e');
      if (mounted && !_bloc.isClosed) {
        // If there's an error loading progress, start fresh
        _bloc.add(OnboardingStarted());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        body: BlocListener<OnboardingBloc, OnboardingState>(
          listener: _handleStateChanges,
          child: BlocBuilder<OnboardingBloc, OnboardingState>(
            builder: (context, state) {
              return CosmicBackground(
                currentStep: state.currentPage,
                totalSteps: onboardingQuestions.length,
                child: _buildContent(context, state),
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleStateChanges(BuildContext context, OnboardingState state) {
    if (state.status == OnboardingStatus.success) {
      _showCompletionCelebration();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !_hasNavigated) {
          _hasNavigated = true;
          context.go('/home');
        }
      });
    } else if (state.status == OnboardingStatus.error) {
      _showErrorMessage(state.errorMessage ?? 'An error occurred');
    }

    // Handle page navigation when data is loaded
    if (state.status == OnboardingStatus.inProgress &&
        state.currentPage != _pageController.page?.round()) {
      // Navigate to the correct page after data is loaded
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _pageController.hasClients) {
          _pageController.animateToPage(
            state.currentPage,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    }

    // Show achievement for section completions
    if (state.currentPage > 0 && state.currentPage % 5 == 0) {
      _showSectionAchievement(state.currentPage);
    }
  }

  Widget _buildContent(BuildContext context, OnboardingState state) {
    if (state.status == OnboardingStatus.loading) {
      return _buildLoadingView();
    }

    return Stack(
      children: [
        // Main content
        Column(
          children: [
            _buildProgressHeader(state),
            Expanded(
              child: _buildQuestionView(state),
            ),
            _buildNavigationFooter(state),
          ],
        ),

        // Achievement overlay
        if (_showAchievement) _buildAchievementOverlay(),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: CosmicDreamTheme.questionBubbleGradient,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: CosmicDreamTheme.primary.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                const CircularProgressIndicator(
                  color: CosmicDreamTheme.text,
                ),
                const SizedBox(height: 16),
                Text(
                  'Preparing your cosmic journey...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: CosmicDreamTheme.text,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .scale(duration: 800.ms, curve: Curves.elasticOut)
        .fadeIn(duration: 600.ms);
  }

  Widget _buildProgressHeader(OnboardingState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
      child: Column(
        children: [
          Text(
            'Connect with Your Future Self',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: CosmicDreamTheme.text,
                  fontWeight: FontWeight.w300,
                ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(duration: 800.ms, delay: 200.ms)
              .slideY(begin: -0.3, duration: 600.ms, delay: 200.ms),
          const SizedBox(height: 24),
          ProgressConstellation(
            currentStep: state.currentPage,
            totalSteps: onboardingQuestions.length,
            height: 80,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionView(OnboardingState state) {
    return PageView.builder(
      controller: _pageController,
      itemCount: onboardingQuestions.length,
      onPageChanged: (index) {
        _bloc.add(PageChanged(index));
      },
      itemBuilder: (context, index) {
        final question = onboardingQuestions[index];
        final currentAnswer = _getCurrentAnswer(state, question.key);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              // Question bubble
              QuestionBubble(
                question: question,
                isVisible: true,
              ),

              const SizedBox(height: 32),

              // Response bubbles
              BubbleGrid(
                question: question,
                selectedValue: currentAnswer,
                onBubbleSelected: (value) {
                  _bloc.add(
                    AnswerUpdated({question.key: value}),
                  );
                },
                isVisible: true,
              ),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavigationFooter(OnboardingState state) {
    final isLastPage = state.currentPage >= onboardingQuestions.length - 1;
    final canContinue = _canContinueFromCurrentPage(state);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Back button
          if (state.currentPage > 0)
            _buildNavButton(
              icon: Icons.arrow_back_ios,
              label: 'Back',
              onTap: () => _navigateToPage(state.currentPage - 1),
              isPrimary: false,
            )
          else
            const Spacer(),

          const SizedBox(width: 16),

          // Continue/Complete button
          Expanded(
            flex: 2,
            child: _buildNavButton(
              icon: isLastPage ? Icons.auto_awesome : Icons.arrow_forward_ios,
              label: isLastPage ? 'Complete Journey' : 'Continue',
              onTap:
                  canContinue ? () => _handleContinue(state, isLastPage) : null,
              isPrimary: true,
              isEnabled: canContinue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool isPrimary = false,
    bool isEnabled = true,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: isPrimary && isEnabled
            ? CosmicDreamTheme.questionBubbleGradient
            : LinearGradient(
                colors: [
                  CosmicDreamTheme.surface.withOpacity(0.8),
                  CosmicDreamTheme.surface.withOpacity(0.6),
                ],
              ),
        borderRadius: BorderRadius.circular(28),
        border: isPrimary
            ? Border.all(color: CosmicDreamTheme.cosmicTeal.withOpacity(0.5))
            : null,
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: (isPrimary
                          ? CosmicDreamTheme.primary
                          : CosmicDreamTheme.surface)
                      .withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: MaterialButton(
        onPressed: isEnabled ? onTap : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isPrimary) ...[
              Icon(
                icon,
                color: isEnabled
                    ? CosmicDreamTheme.text
                    : CosmicDreamTheme.text.withOpacity(0.5),
                size: 18,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: isEnabled
                    ? CosmicDreamTheme.text
                    : CosmicDreamTheme.text.withOpacity(0.5),
                fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
                fontSize: 16,
              ),
            ),
            if (isPrimary) ...[
              const SizedBox(width: 8),
              Icon(
                icon,
                color: isEnabled
                    ? CosmicDreamTheme.text
                    : CosmicDreamTheme.text.withOpacity(0.5),
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: CosmicDreamTheme.questionBubbleGradient,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: CosmicDreamTheme.primary.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: CosmicDreamTheme.accent,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  _achievementMessage,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: CosmicDreamTheme.text,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Your future self is proud! ✨',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: CosmicDreamTheme.text.withOpacity(0.9),
                        ),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .scale(duration: 800.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 600.ms),
        ),
      ),
    );
  }

  void _navigateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  void _handleContinue(OnboardingState state, bool isLastPage) {
    if (isLastPage) {
      _bloc.add(OnboardingSubmitted());
    } else {
      _navigateToPage(state.currentPage + 1);
    }
  }

  bool _canContinueFromCurrentPage(OnboardingState state) {
    final currentQuestion = onboardingQuestions[state.currentPage];
    final currentAnswer = _getCurrentAnswer(state, currentQuestion.key);

    // Optional questions can always be skipped
    if (currentQuestion.key == 'photoPath' ||
        currentQuestion.key == 'lostCoping') {
      return true;
    }

    return currentAnswer != null && currentAnswer.isNotEmpty;
  }

  String? _getCurrentAnswer(OnboardingState state, String key) {
    final data = state.onboardingData;
    switch (key) {
      case 'name':
        return data.name;
      case 'birthday':
        return data.birthday?.toIso8601String();
      case 'culture':
        return data.culture;
      case 'location':
        return data.location;
      case 'mindState':
        return data.mindState;
      case 'selfPerception':
        return data.selfPerception;
      case 'selfLike':
        return data.selfLike;
      case 'pickMeUp':
        return data.pickMeUp;
      case 'stuckPattern':
        return data.stuckPattern;
      case 'desiredFeeling':
        return data.desiredFeeling;
      case 'futureSelfVision':
        return data.futureSelfVision;
      case 'futureSelfAge':
        return data.futureSelfAge?.toString();
      case 'dreamDay':
        return data.dreamDay;
      case 'ambition':
        return data.ambition;
      case 'photoPath':
        return data.photoPath;
      case 'trustedVibes':
        return data.trustedVibes;
      case 'messageLength':
        return data.messageLength;
      case 'messageFrequency':
        return data.messageFrequency;
      case 'personalityFlair':
        return data.personalityFlair;
      case 'lostCoping':
        return data.lostCoping;
      default:
        return null;
    }
  }

  void _showSectionAchievement(int completedSteps) {
    final sectionTitles = {
      5: 'Getting to Know You! 🌟',
      10: 'Understanding Your Journey! 🚀',
      15: 'Envisioning Your Future! ✨',
      20: 'Almost There! 🎯',
    };

    _achievementMessage = sectionTitles[completedSteps] ?? 'Great Progress!';
    setState(() => _showAchievement = true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showAchievement = false);
      }
    });
  }

  void _showCompletionCelebration() {
    _achievementMessage = 'Journey Complete! 🎉\nWelcome to Future Self!';
    setState(() => _showAchievement = true);
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: CosmicDreamTheme.nebulaPink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
