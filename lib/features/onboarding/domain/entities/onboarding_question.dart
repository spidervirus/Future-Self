enum QuestionType { text, date, dropdown, image, country }

class OnboardingQuestion {
  final String key;
  final String questionText;
  final QuestionType type;
  final List<String>? options;

  OnboardingQuestion({
    required this.key,
    required this.questionText,
    this.type = QuestionType.text,
    this.options,
  });
}

final List<OnboardingQuestion> onboardingQuestions = [
  // Section A: Let Me Meet You
  OnboardingQuestion(key: 'name', questionText: "What's your name?"),
  OnboardingQuestion(
      key: 'birthday',
      questionText: "When is your birthday?",
      type: QuestionType.date),
  OnboardingQuestion(
      key: 'culture',
      questionText: "What country or culture feels most like 'home' to you?",
      type: QuestionType.country),
  OnboardingQuestion(
      key: 'location',
      questionText: "Where in the world are you right now?",
      type: QuestionType.country),

  // Section B: Tell Me More About You
  OnboardingQuestion(
      key: 'mindState', questionText: "What's been on your mind lately?"),
  OnboardingQuestion(
      key: 'selfPerception',
      questionText: "Where do you feel most like yourself?"),
  OnboardingQuestion(
      key: 'selfLike',
      questionText: "What's something you like about yourself?"),
  OnboardingQuestion(
      key: 'pickMeUp',
      questionText:
          "What's one thing you wish someone would just remind you when you're feeling down?"),

  // Section C: Moving from A to B
  OnboardingQuestion(
      key: 'stuckPattern',
      questionText:
          "What's one thing you keep saying you'll change... but haven't yet?"),
  OnboardingQuestion(
      key: 'desiredFeeling',
      questionText: "What feeling do you want to experience more this year?"),
  OnboardingQuestion(
      key: 'futureSelfVision',
      questionText: "What kind of person do you want to be one day?"),

  // Section D: Tell Me About Your Future Self
  OnboardingQuestion(
    key: 'futureSelfAge',
    questionText: "How old is your Future Self in your mind?",
    type: QuestionType.dropdown,
    options: List.generate(20, (index) => (index + 18).toString()),
  ),
  OnboardingQuestion(
      key: 'dreamDay', questionText: "What would your dream day look like?"),
  OnboardingQuestion(
      key: 'ambition',
      questionText:
          "One day, you want to wake up and think: 'I actually did it.'"),
  OnboardingQuestion(
      key: 'photoPath',
      questionText: "Upload a photo if you'd like to imagine your Future Self",
      type: QuestionType.image),

  // Section E: Communication Style Preferences
  OnboardingQuestion(
      key: 'trustedVibes',
      questionText: "What are some words or vibes you always trust?"),
  OnboardingQuestion(
    key: 'messageLength',
    questionText:
        "Do you prefer long messages, or short and straight to the point?",
    type: QuestionType.dropdown,
    options: ['Long', 'Short'],
  ),
  OnboardingQuestion(
    key: 'messageFrequency',
    questionText: "How often do you like to be messaged?",
    type: QuestionType.dropdown,
    options: ['Daily', 'Weekly', 'Only when needed'],
  ),
  OnboardingQuestion(
      key: 'personalityFlair',
      questionText: "People trust those who a little..."),

  // Section F: Additional Context
  OnboardingQuestion(
      key: 'lostCoping',
      questionText: "What do you do when you're feeling lost? (Optional)"),
];
