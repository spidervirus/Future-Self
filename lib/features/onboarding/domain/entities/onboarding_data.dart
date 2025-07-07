class OnboardingData {
  final String? name;
  final DateTime? birthday;
  final String? culture;
  final String? location;
  final String? mindState;
  final String? selfPerception;
  final String? selfLike;
  final String? pickMeUp;
  final String? stuckPattern;
  final String? desiredFeeling;
  final String? futureSelfVision;
  final int? futureSelfAge;
  final String? dreamDay;
  final String? ambition;
  final String? photoPath;
  final String? trustedVibes;
  final String? messageLength;
  final String? messageFrequency;
  final String? personalityFlair;
  final String? lostCoping;

  OnboardingData({
    this.name,
    this.birthday,
    this.culture,
    this.location,
    this.mindState,
    this.selfPerception,
    this.selfLike,
    this.pickMeUp,
    this.stuckPattern,
    this.desiredFeeling,
    this.futureSelfVision,
    this.futureSelfAge,
    this.dreamDay,
    this.ambition,
    this.photoPath,
    this.trustedVibes,
    this.messageLength,
    this.messageFrequency,
    this.personalityFlair,
    this.lostCoping,
  });

  OnboardingData copyWith({
    String? name,
    DateTime? birthday,
    String? culture,
    String? location,
    String? mindState,
    String? selfPerception,
    String? selfLike,
    String? pickMeUp,
    String? stuckPattern,
    String? desiredFeeling,
    String? futureSelfVision,
    int? futureSelfAge,
    String? dreamDay,
    String? ambition,
    String? photoPath,
    String? trustedVibes,
    String? messageLength,
    String? messageFrequency,
    String? personalityFlair,
    String? lostCoping,
  }) {
    return OnboardingData(
      name: name ?? this.name,
      birthday: birthday ?? this.birthday,
      culture: culture ?? this.culture,
      location: location ?? this.location,
      mindState: mindState ?? this.mindState,
      selfPerception: selfPerception ?? this.selfPerception,
      selfLike: selfLike ?? this.selfLike,
      pickMeUp: pickMeUp ?? this.pickMeUp,
      stuckPattern: stuckPattern ?? this.stuckPattern,
      desiredFeeling: desiredFeeling ?? this.desiredFeeling,
      futureSelfVision: futureSelfVision ?? this.futureSelfVision,
      futureSelfAge: futureSelfAge ?? this.futureSelfAge,
      dreamDay: dreamDay ?? this.dreamDay,
      ambition: ambition ?? this.ambition,
      photoPath: photoPath ?? this.photoPath,
      trustedVibes: trustedVibes ?? this.trustedVibes,
      messageLength: messageLength ?? this.messageLength,
      messageFrequency: messageFrequency ?? this.messageFrequency,
      personalityFlair: personalityFlair ?? this.personalityFlair,
      lostCoping: lostCoping ?? this.lostCoping,
    );
  }
}
