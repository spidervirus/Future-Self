import 'package:dio/dio.dart';
import '../api_client.dart';
import '../models/onboarding_models.dart';
import '../../../features/onboarding/domain/entities/onboarding_data.dart';

class OnboardingService {
  final ApiClient _apiClient;

  OnboardingService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Start the onboarding process for the current user
  Future<Map<String, dynamic>> startOnboarding() async {
    try {
      final response = await _apiClient.post('/onboarding/start');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Update a specific onboarding step with data
  Future<OnboardingStepResponse> updateStep(
      int stepNumber, Map<String, dynamic> stepData) async {
    try {
      final request = OnboardingStepUpdateRequest(stepData: stepData);
      final response = await _apiClient.put(
        '/onboarding/step/$stepNumber',
        data: request.toJson(),
      );
      return OnboardingStepResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get current onboarding progress
  Future<OnboardingProgress> getProgress() async {
    try {
      final response = await _apiClient.get('/onboarding/progress');
      return OnboardingProgress.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get complete onboarding data
  Future<OnboardingDataResponse> getOnboardingData() async {
    try {
      final response = await _apiClient.get('/onboarding/data');
      return OnboardingDataResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Validate a specific step
  Future<Map<String, dynamic>> validateStep(int stepNumber) async {
    try {
      final response =
          await _apiClient.get('/onboarding/step/$stepNumber/validate');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Complete the onboarding process
  Future<OnboardingComplete> completeOnboarding() async {
    try {
      final response = await _apiClient.post('/onboarding/complete');
      return OnboardingComplete.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get next incomplete step
  Future<int?> getNextStep() async {
    try {
      final response = await _apiClient.get('/onboarding/next-step');
      return response.data['next_step'];
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get step summary with completion status
  Future<Map<String, dynamic>> getStepSummary() async {
    try {
      final response = await _apiClient.get('/onboarding/summary');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get onboarding questions structure from backend
  Future<Map<String, dynamic>> getOnboardingQuestions() async {
    try {
      final response = await _apiClient.get('/onboarding/questions');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Submit a batch of onboarding data (useful for completing multiple steps)
  Future<List<OnboardingStepResponse>> submitBatchData(
      Map<String, dynamic> allData) async {
    try {
      List<OnboardingStepResponse> responses = [];

      // Group data by step number
      Map<int, Map<String, dynamic>> stepGroups = {};

      allData.forEach((key, value) {
        if (value != null) {
          int stepNumber = OnboardingFieldMapper.getStepForField(key);
          if (!stepGroups.containsKey(stepNumber)) {
            stepGroups[stepNumber] = {};
          }
          stepGroups[stepNumber]![key] = value;
        }
      });

      // Submit each step
      for (int stepNumber in stepGroups.keys.toList()..sort()) {
        final stepData =
            OnboardingFieldMapper.mapToBackendFields(stepGroups[stepNumber]!);
        final response = await updateStep(stepNumber, stepData);
        responses.add(response);
      }

      return responses;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Convert Flutter onboarding data to submittable format
  Map<String, dynamic> prepareDataForSubmission(
      Map<String, dynamic> frontendData) {
    // Remove null values and apply field mapping
    Map<String, dynamic> cleanData = {};
    frontendData.forEach((key, value) {
      if (value != null) {
        cleanData[key] = value;
      }
    });

    return OnboardingFieldMapper.mapToBackendFields(cleanData);
  }

  /// Check if user has completed onboarding
  Future<bool> isOnboardingComplete() async {
    try {
      final progress = await getProgress();
      return progress.isComplete;
    } catch (e) {
      // If there's an error getting progress, assume onboarding is not complete
      return false;
    }
  }

  /// Load existing onboarding data and convert it to OnboardingData format
  Future<OnboardingData> loadOnboardingData() async {
    try {
      final onboardingDataResponse = await getOnboardingData();
      // Convert the API response back to OnboardingData format
      return _convertApiResponseToOnboardingData(onboardingDataResponse);
    } catch (e) {
      // If there's an error or no existing data, return initial empty data
      return _createEmptyOnboardingData();
    }
  }

  /// Convert API response to OnboardingData format
  OnboardingData _convertApiResponseToOnboardingData(
      OnboardingDataResponse response) {
    return OnboardingData(
      name: response.name,
      birthday: response.birthday,
      culture: response.culturalHome,
      location: response.currentLocation,
      mindState: response.currentThoughts,
      selfPerception: response.authenticPlace,
      selfLike: response.somethingYouLike,
      pickMeUp: response.reminderWhenDown,
      stuckPattern: response.changeYouWant,
      desiredFeeling: response.feelingToExperience,
      futureSelfVision: response.personYouWantToBe,
      futureSelfAge: response.futureSelfAge,
      dreamDay: response.dreamDay,
      ambition: response.accomplishmentGoal,
      photoPath: response.futureSelfPhotoUrl,
      trustedVibes: response.trustedWordsVibes,
      messageLength: response.messageLengthPreference,
      messageFrequency: response.messageFrequency,
      personalityFlair: response.trustFactor,
      lostCoping: response.whenFeelingLost,
    );
  }

  /// Create empty onboarding data structure
  OnboardingData _createEmptyOnboardingData() {
    return OnboardingData();
  }

  /// Handle API errors consistently
  Exception _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return Exception(
              'Connection timeout. Please check your internet connection.');

        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final message =
              error.response?.data?['detail'] ?? 'Unknown error occurred';

          switch (statusCode) {
            case 400:
              return Exception('Invalid request: $message');
            case 401:
              return Exception('Authentication required. Please log in again.');
            case 403:
              return Exception('Access denied: $message');
            case 404:
              return Exception('Resource not found: $message');
            case 422:
              return Exception('Validation error: $message');
            case 500:
              return Exception('Server error. Please try again later.');
            default:
              return Exception('Request failed: $message');
          }

        case DioExceptionType.cancel:
          return Exception('Request was cancelled');

        case DioExceptionType.unknown:
        default:
          return Exception('Network error. Please check your connection.');
      }
    }

    return Exception('Unexpected error: ${error.toString()}');
  }
}
