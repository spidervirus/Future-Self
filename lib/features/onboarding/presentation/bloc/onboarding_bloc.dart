import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:future_self/core/api/services/onboarding_service.dart';
import 'package:future_self/core/api/models/onboarding_models.dart';
import 'package:future_self/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:future_self/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:future_self/features/onboarding/domain/entities/onboarding_question.dart';
import 'package:future_self/features/onboarding/domain/entities/onboarding_data.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final OnboardingService _onboardingService;

  OnboardingBloc({OnboardingService? onboardingService})
      : _onboardingService = onboardingService ?? OnboardingService(),
        super(OnboardingState.initial()) {
    on<PageChanged>(_onPageChanged);
    on<AnswerUpdated>(_onAnswerUpdated);
    on<OnboardingSubmitted>(_onOnboardingSubmitted);
    on<OnboardingStarted>(_onOnboardingStarted);
    on<OnboardingDataLoaded>(_onOnboardingDataLoaded);
    on<StepSubmitted>(_onStepSubmitted);
  }

  void _onPageChanged(PageChanged event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(currentPage: event.pageIndex));
  }

  void _onAnswerUpdated(
      AnswerUpdated event, Emitter<OnboardingState> emit) async {
    final key = event.answer.keys.first;
    final value = event.answer.values.first;
    var currentData = state.onboardingData;

    switch (key) {
      case 'name':
        currentData = currentData.copyWith(name: value);
        break;
      case 'birthday':
        DateTime? parsedBirthday;
        if (value != null && value.isNotEmpty) {
          try {
            // Try to parse as ISO date first
            parsedBirthday = DateTime.parse(value);
          } catch (e) {
            // If parsing fails, leave it as null
            parsedBirthday = null;
          }
        }
        currentData = currentData.copyWith(birthday: parsedBirthday);
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

    // Auto-save: Immediately save the updated data to the backend
    try {
      final stepNumber = _getStepNumberForField(key);
      final stepData = _getStepData(stepNumber);
      if (stepData.isNotEmpty) {
        final mappedData = OnboardingFieldMapper.mapToBackendFields(stepData);
        await _onboardingService.updateStep(stepNumber, mappedData);
      }
    } catch (e) {
      // Don't emit error state for auto-save failures, just log it
      print('Auto-save failed for field $key: $e');
    }
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

  void _onOnboardingDataLoaded(
      OnboardingDataLoaded event, Emitter<OnboardingState> emit) async {
    emit(state.copyWith(status: OnboardingStatus.loading));

    try {
      // Load existing onboarding data
      final onboardingData = await _onboardingService.loadOnboardingData();
      
      // Get progress to determine current page
      final progress = await _onboardingService.getProgress();
      
      // Calculate the current page based on completed steps
      int currentPage = _calculateCurrentPageFromProgress(onboardingData);
      
      emit(state.copyWith(
        onboardingData: onboardingData,
        currentPage: currentPage,
        status: OnboardingStatus.inProgress,
      ));
    } catch (e) {
      // If loading fails, start with empty data
      emit(state.copyWith(
        status: OnboardingStatus.inProgress,
        currentPage: 0,
      ));
    }
  }

  /// Calculate current page based on onboarding data completeness
  int _calculateCurrentPageFromProgress(OnboardingData data) {
    // Find the first incomplete question
    for (int i = 0; i < onboardingQuestions.length; i++) {
      final question = onboardingQuestions[i];
      final answer = _getAnswerForQuestion(data, question.key);
      
      // If this question is not answered, this is where we should start
      if (answer == null || answer.isEmpty) {
        return i;
      }
    }
    
    // If all questions are answered, go to the last page
    return onboardingQuestions.length - 1;
  }

  /// Get answer value for a specific question key from OnboardingData
  String? _getAnswerForQuestion(OnboardingData data, String key) {
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

  /// Get step number for a specific field
  int _getStepNumberForField(String fieldKey) {
    switch (fieldKey) {
      // Step 1: Let Me Meet You
      case 'name':
      case 'birthday':
      case 'culture':
      case 'location':
        return 1;

      // Step 2: Tell Me More About You
      case 'mindState':
      case 'selfPerception':
      case 'selfLike':
      case 'pickMeUp':
        return 2;

      // Step 3: Moving from A to B
      case 'stuckPattern':
      case 'desiredFeeling':
      case 'futureSelfVision':
        return 3;

      // Step 4: Tell Me About Your Future Self
      case 'futureSelfAge':
      case 'dreamDay':
      case 'ambition':
      case 'photoPath':
        return 4;

      // Step 5: Communication Style Preferences
      case 'trustedVibes':
      case 'messageLength':
      case 'messageFrequency':
      case 'personalityFlair':
        return 5;

      // Step 6: Additional Context
      case 'lostCoping':
        return 6;

      default:
        return 1; // Default to step 1 if field is not recognized
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
