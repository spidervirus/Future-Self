import 'package:equatable/equatable.dart';
import 'package:future_self/features/onboarding/domain/entities/onboarding_data.dart';

enum OnboardingStatus { initial, inProgress, success, failure }

class OnboardingState extends Equatable {
  final OnboardingStatus status;
  final OnboardingData onboardingData;
  final int currentPage;

  const OnboardingState({
    this.status = OnboardingStatus.initial,
    required this.onboardingData,
    this.currentPage = 0,
  });

  factory OnboardingState.initial() {
    return OnboardingState(onboardingData: OnboardingData());
  }

  OnboardingState copyWith({
    OnboardingStatus? status,
    OnboardingData? onboardingData,
    int? currentPage,
  }) {
    return OnboardingState(
      status: status ?? this.status,
      onboardingData: onboardingData ?? this.onboardingData,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object> get props => [status, onboardingData, currentPage];
}
