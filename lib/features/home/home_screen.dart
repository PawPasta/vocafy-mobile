import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/category.dart';
import '../../data/models/syllabus.dart';
import '../../data/models/enrollment.dart';
import '../../data/services/category_service.dart';
import '../../data/services/enrollment_service.dart';
import '../../config/routes/route_names.dart';
import '../../data/services/syllabus_service.dart';
import '../syllabus/syllabus_detail_screen.dart';
import '../enrollments/enrollments_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<_ProfileData> _profileFuture;
  late final Future<List<Syllabus>> _trialSyllabiFuture;
  late final Future<List<AppCategory>> _categoriesFuture;
  late final Future<List<Enrollment>> _enrollmentsFuture;
  final PageController _categoryController = PageController();
  final PageController _bannerController = PageController(
    viewportFraction: 0.92,
  );
  Timer? _bannerTimer;
  int _currentBanner = 0;
  int _currentCategoryPage = 0;
  int _selectedIndex = 0;

  final List<String> _bannerImages = const [
    'https://i.pinimg.com/736x/cf/17/a2/cf17a21a1ccb69e4df352159e4e27736.jpg',
    'https://i.pinimg.com/736x/e0/0c/bd/e00cbd85d41eb2cc7b5ebd4e054fb518.jpg',
    'https://i.pinimg.com/1200x/f5/5a/52/f55a5271cbe4ee9fff695ccc1c4a1c0b.jpg',
  ];

  static const _primaryBlue = Color(0xFF4F6CFF);
  static const _primaryBlueDark = Color(0xFF3F5BFF);
  static const _chipBlue = Color(0xFFEAF0FF);
  static const _textDark = Color(0xFF1A1A1A);
  static const _textMuted = Color(0xFF6B7280);
  static const _headerIconShadow = Color(0x1A000000);
  static const _enrolledGreen = Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfile();
    _trialSyllabiFuture = syllabusService.listSyllabi(page: 0, size: 10);
    _categoriesFuture = categoryService.listCategories(page: 0, size: 10);
    _enrollmentsFuture = enrollmentService.listEnrollments(page: 0, size: 20);
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_bannerImages.isEmpty || !_bannerController.hasClients) return;
      final nextPage = (_currentBanner + 1) % _bannerImages.length;
      _bannerController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<_ProfileData> _fetchProfile() async {
    try {
      final response = await api.get(Api.profile);
      final data = response.data;
      if (data is Map && data['result'] is Map) {
        final result = data['result'] as Map;
        final displayName =
            (result['display_name'] ?? result['displayName'])?.toString() ??
            'User';
        final avatarUrl =
            (result['avatar_url'] ?? result['avatarUrl'])?.toString() ?? '';
        return _ProfileData(
          displayName: displayName.trim().isEmpty ? 'User' : displayName,
          avatarUrl: avatarUrl.trim(),
        );
      }
    } catch (_) {}
    return const _ProfileData(displayName: 'User', avatarUrl: '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategorySection(),
                    const SizedBox(height: 16),
                    _buildBannerCarousel(),
                    const SizedBox(height: 16),
                    _buildEnrolledSyllabusSection(),
                    _buildTrialCoursesSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return FutureBuilder<_ProfileData>(
      future: _profileFuture,
      builder: (context, snapshot) {
        final profile =
            snapshot.data ??
            const _ProfileData(displayName: 'User', avatarUrl: '');
        final photoUrl = profile.avatarUrl.isEmpty ? null : profile.avatarUrl;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          decoration: const BoxDecoration(
            color: _primaryBlue,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () =>
                        Navigator.of(context).pushNamed(RouteNames.profile),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _headerIconShadow,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.transparent,
                        backgroundImage: photoUrl == null
                            ? null
                            : NetworkImage(photoUrl),
                        child: photoUrl == null
                            ? const Icon(Icons.person, color: _primaryBlue)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Level 10',
                          style: TextStyle(
                            color: Color(0xFFDDE3FF),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildHeaderIconButton(Icons.notifications_none),
                ],
              ),
              const SizedBox(height: 14),
              _buildSearchBar(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderIconButton(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _headerIconShadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: _primaryBlue),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search course',
                      hintStyle: TextStyle(color: _textMuted),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(color: _textDark, fontSize: 14),
                  ),
                ),
                const Icon(Icons.search, size: 20, color: _primaryBlue),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Đăng xuất'),
                content: const Text('Bạn có chắc muốn đăng xuất không?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Hủy'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Đăng xuất'),
                  ),
                ],
              ),
            );
            if (ok != true) return;

            await authService.logout();
            if (!context.mounted) return;
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(RouteNames.login, (route) => false);
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _primaryBlueDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.logout, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category >',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<AppCategory>>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            final categories = snapshot.data ?? const <AppCategory>[];
            final pageCount = (categories.length / 4).ceil();

            if (snapshot.connectionState == ConnectionState.waiting &&
                categories.isEmpty) {
              return _buildCategoryLoadingRow();
            }

            if (categories.isEmpty) {
              return _buildFallbackCategoryPager();
            }

            return Column(
              children: [
                SizedBox(
                  height: 92,
                  child: PageView.builder(
                    controller: _categoryController,
                    itemCount: pageCount,
                    onPageChanged: (index) {
                      setState(() => _currentCategoryPage = index);
                    },
                    itemBuilder: (context, pageIndex) {
                      final start = pageIndex * 4;
                      final end = (start + 4) > categories.length
                          ? categories.length
                          : (start + 4);
                      final pageItems = categories.sublist(start, end);

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(4, (i) {
                          if (i < pageItems.length) {
                            return _buildCategoryFromApi(pageItems[i]);
                          }
                          return const SizedBox(width: 84);
                        }),
                      );
                    },
                  ),
                ),
                if (pageCount > 1) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      pageCount,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentCategoryPage == index ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentCategoryPage == index
                              ? _primaryBlue
                              : const Color(0xFFD7DEFF),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryLoadingRow() {
    return SizedBox(
      height: 92,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(4, (index) {
          return SizedBox(
            width: 84,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _chipBlue,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 64,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFallbackCategoryPager() {
    final icons = <IconData>[
      Icons.grid_view_rounded,
      Icons.monetization_on_outlined,
      Icons.science_outlined,
      Icons.favorite_border,
      Icons.play_circle_outline,
    ];
    final pageCount = (icons.length / 4).ceil();

    return SizedBox(
      height: 92,
      child: PageView.builder(
        itemCount: pageCount,
        itemBuilder: (context, pageIndex) {
          final start = pageIndex * 4;
          final end = (start + 4) > icons.length ? icons.length : (start + 4);
          final pageItems = icons.sublist(start, end);

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (i) {
              if (i < pageItems.length) {
                return _buildCategoryIcon(pageItems[i], size: 56);
              }
              return const SizedBox(width: 84);
            }),
          );
        },
      ),
    );
  }

  Widget _buildCategoryIcon(IconData icon, {double size = 48}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _chipBlue,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(icon, color: _primaryBlue, size: size * 0.55),
    );
  }

  Widget _buildEnrolledSyllabusSection() {
    return FutureBuilder<List<Enrollment>>(
      future: _enrollmentsFuture,
      builder: (context, snapshot) {
        final enrollments = snapshot.data ?? const <Enrollment>[];
        if (enrollments.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Syllabus đã Enrollment >',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EnrollmentsScreen(),
                      ),
                    );
                  },
                  child: const Text('Xem tất cả'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                for (int i = 0; i < enrollments.length && i < 3; i++) ...[
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SyllabusDetailScreen(
                            syllabusId: enrollments[i].syllabusId,
                            isEnrolled: true,
                          ),
                        ),
                      );
                    },
                    child: _buildEnrolledCard(
                      title: enrollments[i].syllabusTitle,
                      isFocused: enrollments[i].isFocused,
                    ),
                  ),
                  if (i < enrollments.length - 1 && i < 2)
                    const SizedBox(height: 12),
                ],
              ],
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildEnrolledCard({required String title, bool isFocused = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _enrolledGreen.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.school, color: Color(0xFF43A047)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isFocused)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star, color: Colors.white, size: 18),
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildTrialCoursesSection() {
    return FutureBuilder<List<Enrollment>>(
      future: _enrollmentsFuture,
      builder: (context, enrollSnapshot) {
        final enrolledIds = (enrollSnapshot.data ?? <Enrollment>[])
            .map((e) => e.syllabusId)
            .toSet();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Trial Syllabus >',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                TextButton(onPressed: () {}, child: const Text('See all')),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Syllabus>>(
              future: _trialSyllabiFuture,
              builder: (context, snapshot) {
                // Filter out enrolled syllabi
                final items = (snapshot.data ?? const <Syllabus>[])
                    .where((s) => !enrolledIds.contains(s.id))
                    .take(5)
                    .toList();

                if (snapshot.connectionState == ConnectionState.waiting &&
                    items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Không có syllabus thử mới.',
                      style: TextStyle(color: _textMuted),
                    ),
                  );
                }

                return Column(
                  children: [
                    for (int i = 0; i < items.length; i++) ...[
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  SyllabusDetailScreen(syllabusId: items[i].id),
                            ),
                          );
                        },
                        child: _buildCourseCard(
                          syllabusId: items[i].id,
                          title: items[i].title,
                          language: _displayLanguage(items[i].languageSet),
                        ),
                      ),
                      if (i != items.length - 1) const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  String _displayLanguage(String languageSet) {
    final v = languageSet.toUpperCase();
    if (v.contains('EN') && v.contains('JP')) return 'English • Japanese';
    if (v.contains('EN')) return 'English';
    if (v.contains('JP')) return 'Japanese';
    return languageSet.isEmpty ? 'Unknown' : languageSet;
  }

  Widget _buildBannerCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: _bannerImages.length,
            onPageChanged: (index) {
              setState(() => _currentBanner = index);
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(_bannerImages[index], fit: BoxFit.cover),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withAlpha(115),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 16,
                        bottom: 16,
                        child: Text(
                          '',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _bannerImages.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentBanner == index ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentBanner == index
                    ? _primaryBlue
                    : const Color(0xFFD7DEFF),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseCard({
    required int syllabusId,
    required String title,
    required String language,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _primaryBlue,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.book_outlined, color: _primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Row(children: [_buildCourseChip(language)]),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.play_circle_fill, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFromApi(AppCategory category) {
    return SizedBox(
      width: 84,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _chipBlue,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                _categoryAbbrev(category.name),
                style: const TextStyle(
                  color: _primaryBlue,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _categoryAbbrev(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';

    final words = trimmed
        .split(RegExp(r'\s+'))
        .where((w) => w.trim().isNotEmpty)
        .toList();
    if (words.length >= 2) {
      final a = words[0].substring(0, 1);
      final b = words[1].substring(0, 1);
      return ('$a$b').toUpperCase();
    }

    final upper = trimmed.toUpperCase();
    return upper.length >= 2 ? upper.substring(0, 2) : upper;
  }

  Widget _buildCourseChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _primaryBlueDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: _primaryBlue,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBottomItem(icon: Icons.home, label: 'Home', index: 0),
              _buildBottomItem(
                icon: Icons.smart_toy_outlined,
                label: 'AI',
                index: 1,
              ),
              _buildBottomItem(
                icon: Icons.school_outlined,
                label: 'Enrolled',
                index: 2,
              ),
              _buildBottomItem(
                icon: Icons.book_outlined,
                label: 'Vocab',
                index: 3,
              ),
              _buildBottomItem(
                icon: Icons.person_outline,
                label: 'Profile',
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        if (index == 2) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const EnrollmentsScreen()));
        } else if (index == 4) {
          Navigator.of(context).pushNamed(RouteNames.profile);
        }
      },
      child: Transform.translate(
        offset: Offset(0, isActive ? -8 : 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isActive)
              Transform.translate(
                offset: const Offset(0, -3),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: _primaryBlue, width: 2),
                  ),
                  child: Icon(icon, color: _primaryBlue, size: 28),
                ),
              )
            else
              Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileData {
  final String displayName;
  final String avatarUrl;

  const _ProfileData({required this.displayName, required this.avatarUrl});
}
