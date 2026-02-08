/// Centralized remote image URLs used across the app.
///
/// Keep all hard-coded image URLs here to avoid scattering strings.
class AppRemoteImages {
  AppRemoteImages._();

  // Branding
  static const String splashLogoPng =
      'https://res.cloudinary.com/dv6ibddcf/image/upload/v1769673745/ysqvhlodmvpf9wjjzyiq.png';
  static const String appIconPng =
      'https://res.cloudinary.com/dv6ibddcf/image/upload/v1769765008/zc55hvdwelu0cobfk3xv.png';

  // Onboarding illustrations
  static const String onboarding1Png =
      'https://res.cloudinary.com/dv6ibddcf/image/upload/v1770538074/qwtusgwqzzg7qisesb0e.png';
  static const String onboarding2Png =
      'https://res.cloudinary.com/dv6ibddcf/image/upload/v1770538075/grg34j1qasd5s1saduin.png';
  static const String onboarding3Png =
      'https://res.cloudinary.com/dv6ibddcf/image/upload/v1770538075/hukhtsifrnrgzevgqkd5.png';

  // Auth / Login
  static const String loginHeroPng =
      'https://res.cloudinary.com/dv6ibddcf/image/upload/v1770538075/bjadcsozkxuprlicv6nk.png';

  // Profile fallback avatar
  static const String defaultAvatarSvg =
      'https://res.cloudinary.com/dv6ibddcf/image/upload/v1770538281/lfygkafxrbtyub9gsmcy.svg';

  // Home banners (currently using external sample images)
  static const List<String> homeBannerImages = <String>[
    'https://i.pinimg.com/736x/cf/17/a2/cf17a21a1ccb69e4df352159e4e27736.jpg',
    'https://i.pinimg.com/736x/e0/0c/bd/e00cbd85d41eb2cc7b5ebd4e054fb518.jpg',
    'https://i.pinimg.com/1200x/f5/5a/52/f55a5271cbe4ee9fff695ccc1c4a1c0b.jpg',
  ];
}
