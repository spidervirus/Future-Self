import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:future_self/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:future_self/features/onboarding/presentation/bloc/onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc() : super(OnboardingState.initial()) {
    on<PageChanged>(_onPageChanged);
    on<AnswerUpdated>(_onAnswerUpdated);
    on<OnboardingSubmitted>(_onOnboardingSubmitted);
  }

  void _onPageChanged(PageChanged event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(currentPage: event.pageIndex));
  }

  void _onAnswerUpdated(AnswerUpdated event, Emitter<OnboardingState> emit) {
    final key = event.answer.keys.first;
    final value = event.answer.values.first;
    var currentData = state.onboardingData;

    switch (key) {
      case 'name':
        currentData = currentData.copyWith(name: value);
        break;
      case 'birthday':
        currentData = currentData.copyWith(birthday: value);
        break;
      case 'culture':
        currentData = currentData.copyWith(culture: value);
        break;
      case 'location':
        currentData = currentData.copyWith(location: value);
        break;
      case 'mindState':
        currentData = currentData.copyWith(mindState: value);
        break;
      case 'selfPerception':
        currentData = currentData.copyWith(selfPerception: value);
        break;
      case 'selfLike':
        currentData = currentData.copyWith(selfLike: value);
        break;
      case 'pickMeUp':
        currentData = currentData.copyWith(pickMeUp: value);
        break;
      case 'stuckPattern':
        currentData = currentData.copyWith(stuckPattern: value);
        break;
      case 'desiredFeeling':
        currentData = currentData.copyWith(desiredFeeling: value);
        break;
      case 'futureSelfVision':
        currentData = currentData.copyWith(futureSelfVision: value);
        break;
      case 'futureSelfAge':
        currentData = currentData.copyWith(futureSelfAge: int.tryParse(value));
        break;
      case 'dreamDay':
        currentData = currentData.copyWith(dreamDay: value);
        break;
      case 'ambition':
        currentData = currentData.copyWith(ambition: value);
        break;
      case 'photoPath':
        currentData = currentData.copyWith(photoPath: value);
        break;
      case 'trustedVibes':
        currentData = currentData.copyWith(trustedVibes: value);
        break;
      case 'messageLength':
        currentData = currentData.copyWith(messageLength: value);
        break;
      case 'messageFrequency':
        currentData = currentData.copyWith(messageFrequency: value);
        break;
      case 'personalityFlair':
        currentData = currentData.copyWith(personalityFlair: value);
        break;
      case 'lostCoping':
        currentData = currentData.copyWith(lostCoping: value);
        break;
    }

    emit(state.copyWith(onboardingData: currentData));
  }

  void _onOnboardingSubmitted(
      OnboardingSubmitted event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(status: OnboardingStatus.success));
    // Here you would typically send the data to a repository.
    print('Onboarding submitted!');
    // You can access the full data via state.onboardingData
  }
}
