import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:future_self/features/onboarding/domain/entities/onboarding_question.dart';
import 'package:future_self/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:future_self/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:future_self/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:future_self/features/onboarding/presentation/widgets/question_page.dart';
import 'package:future_self/core/di/service_locator.dart';
import 'package:future_self/core/api/services/onboarding_service.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final OnboardingBloc _bloc;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _bloc = sl<OnboardingBloc>();
    _checkOnboardingBeforeStart();
  }

  Future<void> _checkOnboardingBeforeStart() async {
    if (!mounted) return;

    try {
      final onboardingService = OnboardingService();
      final progress = await onboardingService.getProgress();

      print(
          '📊 Raw progress data: isComplete=${progress.isComplete}, completedSteps=${progress.completedSteps}');

      if (progress.isComplete && mounted && !_hasNavigated) {
        print('🚫 Onboarding already complete, redirecting to home');
        _hasNavigated = true;
        context.go('/home');
        return;
      }

      // Only start onboarding if not complete and bloc is still active
      if (!progress.isComplete && mounted && !_bloc.isClosed) {
        print('▶️ Starting onboarding process');
        _bloc.add(OnboardingStarted());
      }
    } catch (e) {
      print('⚠️ Error checking onboarding status: $e');
      // If we can't check, proceed with onboarding only if bloc is active
      if (mounted && !_bloc.isClosed) {
        _bloc.add(OnboardingStarted());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: const OnboardingView(),
    );
  }

  @override
  void dispose() {
    // Don't dispose the bloc here since it's managed by the service locator
    super.dispose();
  }
}

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tell Us About Yourself'),
      ),
      body: BlocListener<OnboardingBloc, OnboardingState>(
        listener: (context, state) {
          if (state.status == OnboardingStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Onboarding completed! Welcome to Future Self!'),
                backgroundColor: Colors.green,
              ),
            );
            print('🎉 Onboarding completed, navigating to home');
            context.go('/home');
          } else if (state.status == OnboardingStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'An error occurred'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<OnboardingBloc, OnboardingState>(
          builder: (context, state) {
            if (state.status == OnboardingStatus.loading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Processing your onboarding...'),
                  ],
                ),
              );
            }

            final progress =
                (state.currentPage + 1) / onboardingQuestions.length;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 16.0),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: onboardingQuestions.length,
                    onPageChanged: (index) {
                      context.read<OnboardingBloc>().add(PageChanged(index));
                    },
                    itemBuilder: (context, index) {
                      return QuestionPage(
                        question: onboardingQuestions[index],
                      );
                    },
                  ),
                ),
                _buildNavigation(context, state),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavigation(BuildContext context, OnboardingState state) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (state.currentPage > 0)
            TextButton(
              onPressed: () {
                _pageController.animateToPage(
                  state.currentPage - 1,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
                context
                    .read<OnboardingBloc>()
                    .add(PageChanged(state.currentPage - 1));
              },
              child: const Text('Back'),
            ),
          ElevatedButton(
            onPressed: () {
              if (state.currentPage < onboardingQuestions.length - 1) {
                _pageController.animateToPage(
                  state.currentPage + 1,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
                context
                    .read<OnboardingBloc>()
                    .add(PageChanged(state.currentPage + 1));
              } else {
                context.read<OnboardingBloc>().add(OnboardingSubmitted());
              }
            },
            child: Text(
              state.currentPage < onboardingQuestions.length - 1
                  ? 'Next'
                  : 'Finish',
            ),
          ),
        ],
      ),
    );
  }
}
