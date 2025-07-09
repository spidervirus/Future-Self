import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:future_self/core/api/services/onboarding_service.dart';
import 'package:future_self/core/api/models/onboarding_models.dart';
import 'package:future_self/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:future_self/features/onboarding/presentation/bloc/onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final OnboardingService _onboardingService;

  OnboardingBloc({OnboardingService? onboardingService})
      : _onboardingService = onboardingService ?? OnboardingService(),
        super(OnboardingState.initial()) {
    on<PageChanged>(_onPageChanged);
    on<AnswerUpdated>(_onAnswerUpdated);
    on<OnboardingSubmitted>(_onOnboardingSubmitted);
    on<OnboardingStarted>(_onOnboardingStarted);
    on<StepSubmitted>(_onStepSubmitted);
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

  void _onOnboardingStarted(
      OnboardingStarted event, Emitter<OnboardingState> emit) async {
    emit(state.copyWith(status: OnboardingStatus.loading));

    try {
      await _onboardingService.startOnboarding();
      emit(state.copyWith(status: OnboardingStatus.inProgress));
    } catch (e) {
      emit(state.copyWith(
        status: OnboardingStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onStepSubmitted(
      StepSubmitted event, Emitter<OnboardingState> emit) async {
    try {
      // Convert the current step data to API format
      final stepData = _getStepData(event.stepNumber);
      if (stepData.isNotEmpty) {
        final mappedData = OnboardingFieldMapper.mapToBackendFields(stepData);
        await _onboardingService.updateStep(event.stepNumber, mappedData);
      }
    } catch (e) {
      emit(state.copyWith(
        status: OnboardingStatus.error,
        errorMessage: 'Failed to save step: ${e.toString()}',
      ));
    }
  }

  void _onOnboardingSubmitted(
      OnboardingSubmitted event, Emitter<OnboardingState> emit) async {
    emit(state.copyWith(status: OnboardingStatus.loading));

    try {
      // Convert all onboarding data to a map
      final allData = _convertOnboardingDataToMap(state.onboardingData);

      // Submit all the data using batch submission
      await _onboardingService.submitBatchData(allData);

      // Mark onboarding as complete
      await _onboardingService.completeOnboarding();

      emit(state.copyWith(status: OnboardingStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: OnboardingStatus.error,
        errorMessage: 'Failed to complete onboarding: ${e.toString()}',
      ));
    }
  }

  /// Get data for a specific step based on step number
  Map<String, dynamic> _getStepData(int stepNumber) {
    final data = state.onboardingData;

    switch (stepNumber) {
      case 1:
        return {
          if (data.name != null) 'name': data.name,
          if (data.birthday != null) 'birthday': data.birthday,
          if (data.culture != null) 'culture': data.culture,
          if (data.location != null) 'location': data.location,
        };
      case 2:
        return {
          if (data.mindState != null) 'mindState': data.mindState,
          if (data.selfPerception != null)
            'selfPerception': data.selfPerception,
          if (data.selfLike != null) 'selfLike': data.selfLike,
          if (data.pickMeUp != null) 'pickMeUp': data.pickMeUp,
        };
      case 3:
        return {
          if (data.stuckPattern != null) 'stuckPattern': data.stuckPattern,
          if (data.desiredFeeling != null)
            'desiredFeeling': data.desiredFeeling,
          if (data.futureSelfVision != null)
            'futureSelfVision': data.futureSelfVision,
        };
      case 4:
        return {
          if (data.futureSelfAge != null) 'futureSelfAge': data.futureSelfAge,
          if (data.dreamDay != null) 'dreamDay': data.dreamDay,
          if (data.ambition != null) 'ambition': data.ambition,
          if (data.photoPath != null) 'photoPath': data.photoPath,
        };
      case 5:
        return {
          if (data.trustedVibes != null) 'trustedVibes': data.trustedVibes,
          if (data.messageLength != null) 'messageLength': data.messageLength,
          if (data.messageFrequency != null)
            'messageFrequency': data.messageFrequency,
          if (data.personalityFlair != null)
            'personalityFlair': data.personalityFlair,
        };
      case 6:
        return {
          if (data.lostCoping != null) 'lostCoping': data.lostCoping,
        };
      default:
        return {};
    }
  }

  /// Convert OnboardingData to Map for API submission
  Map<String, dynamic> _convertOnboardingDataToMap(dynamic data) {
    return {
      if (data.name != null) 'name': data.name,
      if (data.birthday != null) 'birthday': data.birthday,
      if (data.culture != null) 'culture': data.culture,
      if (data.location != null) 'location': data.location,
      if (data.mindState != null) 'mindState': data.mindState,
      if (data.selfPerception != null) 'selfPerception': data.selfPerception,
      if (data.selfLike != null) 'selfLike': data.selfLike,
      if (data.pickMeUp != null) 'pickMeUp': data.pickMeUp,
      if (data.stuckPattern != null) 'stuckPattern': data.stuckPattern,
      if (data.desiredFeeling != null) 'desiredFeeling': data.desiredFeeling,
      if (data.futureSelfVision != null)
        'futureSelfVision': data.futureSelfVision,
      if (data.futureSelfAge != null) 'futureSelfAge': data.futureSelfAge,
      if (data.dreamDay != null) 'dreamDay': data.dreamDay,
      if (data.ambition != null) 'ambition': data.ambition,
      if (data.photoPath != null) 'photoPath': data.photoPath,
      if (data.trustedVibes != null) 'trustedVibes': data.trustedVibes,
      if (data.messageLength != null) 'messageLength': data.messageLength,
      if (data.messageFrequency != null)
        'messageFrequency': data.messageFrequency,
      if (data.personalityFlair != null)
        'personalityFlair': data.personalityFlair,
      if (data.lostCoping != null) 'lostCoping': data.lostCoping,
    };
  }
}
