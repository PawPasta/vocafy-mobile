import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../data/models/syllabus.dart';
import '../../data/services/syllabus_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<_ProfileData> _profileFuture;
  late final Future<List<Syllabus>> _trialSyllabiFuture;
  final PageController _bannerController =
      PageController(viewportFraction: 0.92);
  Timer? _bannerTimer;
  int _currentBanner = 0;

  final List<String> _bannerImages = const [
    'https://images.unsplash.com/photo-1496307042754-b4aa456c4a2d?w=1200&q=80',
    'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?w=1200&q=80',
    'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=1200&q=80',
  ];

  static const _primaryBlue = Color(0xFF4F6CFF);
  static const _primaryBlueDark = Color(0xFF3F5BFF);
  static const _chipBlue = Color(0xFFEAF0FF);
  static const _textDark = Color(0xFF1A1A1A);
  static const _textMuted = Color(0xFF6B7280);
  static const _headerIconShadow = Color(0x1A000000);

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfile();
    _trialSyllabiFuture = syllabusService.listSyllabi(page: 0, size: 5);
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
        final profile = snapshot.data ??
            const _ProfileData(displayName: 'User', avatarUrl: '');
        final photoUrl = profile.avatarUrl.isEmpty ? null : profile.avatarUrl;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          decoration: const BoxDecoration(
            color: _primaryBlue,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
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
                      backgroundImage:
                          photoUrl == null ? null : NetworkImage(photoUrl),
                      child: photoUrl == null
                          ? const Icon(Icons.person, color: _primaryBlue)
                          : null,
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
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _primaryBlueDark,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.fullscreen_outlined,
              color: Colors.white, size: 24),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Category >',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildCategoryIcon(Icons.grid_view_rounded),
            _buildCategoryIcon(Icons.monetization_on_outlined),
            _buildCategoryIcon(Icons.science_outlined),
            _buildCategoryIcon(Icons.favorite_border),
            _buildCategoryIcon(Icons.play_circle_outline),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 46,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFDFE5FF),
              borderRadius: BorderRadius.circular(99),
            ),
            alignment: Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 6,
              decoration: BoxDecoration(
                color: _primaryBlue,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryIcon(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _chipBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: _primaryBlue),
    );
  }

  Widget _buildTrialCoursesSection() {
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
            TextButton(
              onPressed: () {},
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<Syllabus>>(
          future: _trialSyllabiFuture,
          builder: (context, snapshot) {
            final items = (snapshot.data ?? const <Syllabus>[]).take(5).toList();

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
                  'Chưa có syllabus thử.',
                  style: TextStyle(color: _textMuted),
                ),
              );
            }

            return Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  _buildCourseCard(
                    title: items[i].title,
                    language: _displayLanguage(items[i].languageSet),
                  ),
                  if (i != items.length - 1) const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ],
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
                      Image.network(
                        _bannerImages[index],
                        fit: BoxFit.cover,
                      ),
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
                          'Special offer for you',
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
                Row(
                  children: [
                    _buildCourseChip(language),
                  ],
                ),
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
              _buildBottomItem(
                icon: Icons.home,
                label: 'Home',
                isActive: true,
              ),
              _buildBottomItem(
                icon: Icons.smart_toy_outlined,
                label: 'AI',
              ),
              _buildBottomItem(
                icon: Icons.book_outlined,
                label: 'Vocab',
              ),
              _buildBottomItem(
                icon: Icons.school_outlined,
                label: 'Course',
              ),
              _buildBottomItem(
                icon: Icons.person_outline,
                label: 'Profile',
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
    bool isActive = false,
  }) {
    return Transform.translate(
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
    );
  }
}

class _ProfileData {
  final String displayName;
  final String avatarUrl;

  const _ProfileData({required this.displayName, required this.avatarUrl});
}
