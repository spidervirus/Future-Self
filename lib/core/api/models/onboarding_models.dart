// Onboarding API Models
// These models map to the backend onboarding API endpoints and schemas

class OnboardingStepUpdateRequest {
  final Map<String, dynamic> stepData;

  OnboardingStepUpdateRequest({required this.stepData});

  Map<String, dynamic> toJson() => {
        'step_data': stepData,
      };
}

class OnboardingProgress {
  final String userId;
  final int completedSteps;
  final bool isComplete;
  final double completionPercentage;
  final int? currentStep;
  final DateTime? completedAt;

  OnboardingProgress({
    required this.userId,
    required this.completedSteps,
    required this.isComplete,
    required this.completionPercentage,
    this.currentStep,
    this.completedAt,
  });

  factory OnboardingProgress.fromJson(Map<String, dynamic> json) {
    return OnboardingProgress(
      userId: json['user_id'],
      completedSteps: json['completed_steps'],
      isComplete: json['is_complete'],
      completionPercentage: (json['completion_percentage'] as num).toDouble(),
      currentStep: json['current_step'],
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }
}

class OnboardingDataResponse {
  final String userId;
  final String? name;
  final DateTime? birthday;
  final String? culturalHome;
  final String? currentLocation;
  final String? currentThoughts;
  final String? authenticPlace;
  final String? somethingYouLike;
  final String? reminderWhenDown;
  final String? changeYouWant;
  final String? feelingToExperience;
  final String? personYouWantToBe;
  final int? futureSelfAge;
  final String? dreamDay;
  final String? accomplishmentGoal;
  final String? futureSelfPhotoUrl;
  final String? trustedWordsVibes;
  final String? messageLengthPreference;
  final String? messageFrequency;
  final String? trustFactor;
  final String? whenFeelingLost;
  final int completedSteps;
  final bool isComplete;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  OnboardingDataResponse({
    required this.userId,
    this.name,
    this.birthday,
    this.culturalHome,
    this.currentLocation,
    this.currentThoughts,
    this.authenticPlace,
    this.somethingYouLike,
    this.reminderWhenDown,
    this.changeYouWant,
    this.feelingToExperience,
    this.personYouWantToBe,
    this.futureSelfAge,
    this.dreamDay,
    this.accomplishmentGoal,
    this.futureSelfPhotoUrl,
    this.trustedWordsVibes,
    this.messageLengthPreference,
    this.messageFrequency,
    this.trustFactor,
    this.whenFeelingLost,
    required this.completedSteps,
    required this.isComplete,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OnboardingDataResponse.fromJson(Map<String, dynamic> json) {
    return OnboardingDataResponse(
      userId: json['user_id'],
      name: json['name'],
      birthday:
          json['birthday'] != null ? DateTime.parse(json['birthday']) : null,
      culturalHome: json['cultural_home'],
      currentLocation: json['current_location'],
      currentThoughts: json['current_thoughts'],
      authenticPlace: json['authentic_place'],
      somethingYouLike: json['something_you_like'],
      reminderWhenDown: json['reminder_when_down'],
      changeYouWant: json['change_you_want'],
      feelingToExperience: json['feeling_to_experience'],
      personYouWantToBe: json['person_you_want_to_be'],
      futureSelfAge: json['future_self_age'],
      dreamDay: json['dream_day'],
      accomplishmentGoal: json['accomplishment_goal'],
      futureSelfPhotoUrl: json['future_self_photo_url'],
      trustedWordsVibes: json['trusted_words_vibes'],
      messageLengthPreference: json['message_length_preference'],
      messageFrequency: json['message_frequency'],
      trustFactor: json['trust_factor'],
      whenFeelingLost: json['when_feeling_lost'],
      completedSteps: json['completed_steps'],
      isComplete: json['is_complete'],
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class OnboardingStepResponse {
  final String message;
  final int stepNumber;
  final int completedSteps;
  final bool isStepComplete;
  final double completionPercentage;

  OnboardingStepResponse({
    required this.message,
    required this.stepNumber,
    required this.completedSteps,
    required this.isStepComplete,
    required this.completionPercentage,
  });

  factory OnboardingStepResponse.fromJson(Map<String, dynamic> json) {
    return OnboardingStepResponse(
      message: json['message'],
      stepNumber: json['step_number'],
      completedSteps: json['completed_steps'],
      isStepComplete: json['is_step_complete'],
      completionPercentage: (json['completion_percentage'] as num).toDouble(),
    );
  }
}

class OnboardingComplete {
  final String userId;
  final double completionPercentage;
  final DateTime completedAt;
  final String message;

  OnboardingComplete({
    required this.userId,
    required this.completionPercentage,
    required this.completedAt,
    required this.message,
  });

  factory OnboardingComplete.fromJson(Map<String, dynamic> json) {
    return OnboardingComplete(
      userId: json['user_id'],
      completionPercentage: (json['completion_percentage'] as num).toDouble(),
      completedAt: DateTime.parse(json['completed_at']),
      message: json['message'],
    );
  }
}

// Field mapping utility to convert Flutter field names to backend field names
class OnboardingFieldMapper {
  static Map<String, String> fieldNameMapping = {
    // Step 1: Let Me Meet You
    'name': 'name',
    'birthday': 'birthday',
    'culture': 'cultural_home',
    'location': 'current_location',

    // Step 2: Tell Me More About You
    'mindState': 'current_thoughts',
    'selfPerception': 'authentic_place',
    'selfLike': 'something_you_like',
    'pickMeUp': 'reminder_when_down',

    // Step 3: Moving from A to B
    'stuckPattern': 'change_you_want',
    'desiredFeeling': 'feeling_to_experience',
    'futureSelfVision': 'person_you_want_to_be',

    // Step 4: Tell Me About Your Future Self
    'futureSelfAge': 'future_self_age',
    'dreamDay': 'dream_day',
    'ambition': 'accomplishment_goal',
    'photoPath': 'future_self_photo_url',

    // Step 5: Communication Style Preferences
    'trustedVibes': 'trusted_words_vibes',
    'messageLength': 'message_length_preference',
    'messageFrequency': 'message_frequency',
    'personalityFlair': 'trust_factor',

    // Step 6: Additional Context
    'lostCoping': 'when_feeling_lost',
  };

  static Map<String, dynamic> mapToBackendFields(
      Map<String, dynamic> frontendData) {
    Map<String, dynamic> backendData = {};

    frontendData.forEach((key, value) {
      String? backendKey = fieldNameMapping[key];
      if (backendKey != null && value != null) {
        // Handle special cases
        if (key == 'birthday' && value is DateTime) {
          backendData[backendKey] =
              value.toIso8601String().split('T')[0]; // Date only
        } else if (key == 'messageLength') {
          // Convert Flutter values to backend enum values
          backendData[backendKey] = value.toLowerCase();
        } else if (key == 'messageFrequency') {
          // Map Flutter values to backend enum values
          switch (value.toLowerCase()) {
            case 'daily':
              backendData[backendKey] = 'daily';
              break;
            case 'weekly':
              backendData[backendKey] = 'weekly';
              break;
            case 'only when needed':
              backendData[backendKey] = 'as_needed';
              break;
            default:
              backendData[backendKey] = 'as_needed';
          }
        } else {
          backendData[backendKey] = value;
        }
      }
    });

    return backendData;
  }

  static int getStepForField(String fieldName) {
    switch (fieldName) {
      case 'name':
      case 'birthday':
      case 'culture':
      case 'location':
        return 1;
      case 'mindState':
      case 'selfPerception':
      case 'selfLike':
      case 'pickMeUp':
        return 2;
      case 'stuckPattern':
      case 'desiredFeeling':
      case 'futureSelfVision':
        return 3;
      case 'futureSelfAge':
      case 'dreamDay':
      case 'ambition':
      case 'photoPath':
        return 4;
      case 'trustedVibes':
      case 'messageLength':
      case 'messageFrequency':
      case 'personalityFlair':
        return 5;
      case 'lostCoping':
        return 6;
      default:
        return 1;
    }
  }
}
