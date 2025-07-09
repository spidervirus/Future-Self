import 'package:equatable/equatable.dart';
import 'package:future_self/features/onboarding/domain/entities/onboarding_data.dart';

enum OnboardingStatus { initial, loading, inProgress, success, error, failure }

class OnboardingState extends Equatable {
  final OnboardingStatus status;
  final OnboardingData onboardingData;
  final int currentPage;
  final String? errorMessage;

  const OnboardingState({
    this.status = OnboardingStatus.initial,
    required this.onboardingData,
    this.currentPage = 0,
    this.errorMessage,
  });

  factory OnboardingState.initial() {
    return OnboardingState(onboardingData: OnboardingData());
  }

  OnboardingState copyWith({
    OnboardingStatus? status,
    OnboardingData? onboardingData,
    int? currentPage,
    String? errorMessage,
  }) {
    return OnboardingState(
      status: status ?? this.status,
      onboardingData: onboardingData ?? this.onboardingData,
      currentPage: currentPage ?? this.currentPage,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, onboardingData, currentPage, errorMessage];
}
