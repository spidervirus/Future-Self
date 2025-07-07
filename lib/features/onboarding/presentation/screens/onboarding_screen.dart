import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:future_self/features/onboarding/domain/entities/onboarding_question.dart';
import 'package:future_self/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:future_self/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:future_self/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:future_self/features/onboarding/presentation/widgets/question_page.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OnboardingBloc(),
      child: const OnboardingView(),
    );
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
            context.go('/home');
          }
          if (state.currentPage != _pageController.page?.round()) {
            _pageController.animateToPage(
              state.currentPage,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          }
        },
        child: BlocBuilder<OnboardingBloc, OnboardingState>(
          builder: (context, state) {
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
                context
                    .read<OnboardingBloc>()
                    .add(PageChanged(state.currentPage - 1));
              },
              child: const Text('Back'),
            ),
          ElevatedButton(
            onPressed: () {
              if (state.currentPage < onboardingQuestions.length - 1) {
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
