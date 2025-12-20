/// Model class representing a single onboarding page
class OnboardingModel {
  final String title;
  final String description;
  final String imagePath;

  const OnboardingModel({
    required this.title,
    required this.description,
    required this.imagePath,
  });

  /// Static list of all onboarding pages
  static const List<OnboardingModel> pages = [
    OnboardingModel(
      title: 'Expand Your Professional\nVocabulary',
      description: 'Learn industry-specific words and phrases that boost your communication and confidence in your chosen field',
      imagePath: 'lib/assets/images/intro_img_1.png',
    ),
    OnboardingModel(
      title: 'Study on Your Own Time',
      description: 'AI creates a learning plan that matches your free time and daily routine, so you can learn effectively without stress',
      imagePath: 'lib/assets/images/intro_img_2.png',
    ),
    OnboardingModel(
      title: 'Remember Longer\nwith Smart Review',
      description: 'Revisit words at the perfect time with AI-powered spaced repetition, helping you retain knowledge effortlessly',
      imagePath: 'lib/assets/images/intro_img_3.png',
    ),
  ];
}
