import 'package:equatable/equatable.dart';

abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object> get props => [];
}

class PageChanged extends OnboardingEvent {
  final int pageIndex;

  const PageChanged(this.pageIndex);

  @override
  List<Object> get props => [pageIndex];
}

class AnswerUpdated extends OnboardingEvent {
  final Map<String, dynamic> answer;

  const AnswerUpdated(this.answer);

  @override
  List<Object> get props => [answer];
}

class OnboardingSubmitted extends OnboardingEvent {}

class OnboardingStarted extends OnboardingEvent {}

class OnboardingDataLoaded extends OnboardingEvent {}

class StepSubmitted extends OnboardingEvent {
  final int stepNumber;

  const StepSubmitted(this.stepNumber);

  @override
  List<Object> get props => [stepNumber];
}
