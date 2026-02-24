import 'package:flutter/material.dart';
import '../../data/services/enrollment_service.dart';
import '../../data/models/enrollment.dart';
import '../../config/routes/route_names.dart';
import '../syllabus/syllabus_detail_screen.dart';

class EnrollmentsScreen extends StatefulWidget {
  const EnrollmentsScreen({super.key});

  @override
  State<EnrollmentsScreen> createState() => _EnrollmentsScreenState();
}

class _EnrollmentsScreenState extends State<EnrollmentsScreen> {
  List<Enrollment> _enrollments = [];
  bool _loadingEnrollments = false;

  final ScrollController _scrollController = ScrollController();
  int _page = 0;
  static const int _pageSize = 25;
  bool _hasMore = true;

  static const _primaryBlue = Color(0xFF4F6CFF);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadData();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _refreshEnrollments();
  }

  Future<void> _refreshEnrollments() async {
    _page = 0;
    _hasMore = true;
    setState(() {
      _enrollments = [];
    });
    await _loadNextPage(force: true);
  }

  Future<void> _loadNextPage({bool force = false}) async {
    if (_loadingEnrollments && !force) return;
    if (!_hasMore && !force) return;

    setState(() => _loadingEnrollments = true);
    try {
      final enrollments = await enrollmentService.listEnrollments(
        page: _page,
        size: _pageSize,
      );

      if (!mounted) return;

      setState(() {
        if (_page == 0) {
          _enrollments = enrollments;
        } else {
          _enrollments.addAll(enrollments);
        }

        _loadingEnrollments = false;
        if (enrollments.length < _pageSize) {
          _hasMore = false;
        } else {
          _page += 1;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingEnrollments = false);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_loadingEnrollments || !_hasMore) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      _loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final showEmptyState = !_loadingEnrollments && _enrollments.isEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 20, bottom: 24),
                  itemCount:
                      1 +
                      (showEmptyState ? 1 : _enrollments.length) +
                      (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildEnrolledSectionHeader();
                    }

                    if (showEmptyState && index == 1) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 56,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No courses enrolled',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Explore and enroll in courses from the home page',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final itemIndex = index - 1;
                    if (itemIndex < _enrollments.length) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: SizedBox(
                          height: 186,
                          child: _buildEnrollmentListCard(
                            _enrollments[itemIndex],
                          ),
                        ),
                      );
                    }

                    // Load-more indicator
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 26),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildEnrolledSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.library_books_outlined,
              color: _primaryBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'All Courses',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          if (_enrollments.isNotEmpty)
            Text(
              '${_enrollments.length}+ courses',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: const BoxDecoration(
        color: _primaryBlue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'My Courses',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.school_outlined, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollmentListCard(Enrollment enrollment) {
    // Reuse the existing carousel card UI but make it fit a vertical list.
    return _buildEnrollmentCarouselCard(enrollment);
  }

  Widget _buildEnrollmentCarouselCard(Enrollment enrollment) {
    final isFocused = enrollment.isFocused;
    final hasImage =
        enrollment.imageBackground.isNotEmpty ||
        enrollment.imageIcon.isNotEmpty;
    final imageUrl = enrollment.imageBackground.isNotEmpty
        ? enrollment.imageBackground
        : enrollment.imageIcon;

    return GestureDetector(
      onTap: () => _navigateToDetail(enrollment),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isFocused ? Colors.amber.shade400 : Colors.grey.shade200,
            width: isFocused ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: hasImage
                        ? Image.network(
                            imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildPlaceholderImage(),
                          )
                        : _buildPlaceholderImage(),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isFocused ? Colors.amber : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isFocused ? Icons.star : Icons.star_border,
                        color: isFocused ? Colors.white : Colors.amber,
                        size: 20,
                      ),
                    ),
                  ),
                  if (isFocused)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Focused',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      enrollment.syllabusTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${enrollment.totalDays} days',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const Spacer(),
                        if (enrollment.progress > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _primaryBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${enrollment.progress}%',
                              style: const TextStyle(
                                color: _primaryBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      color: _primaryBlue.withValues(alpha: 0.1),
      child: const Center(
        child: Icon(Icons.school_outlined, size: 40, color: _primaryBlue),
      ),
    );
  }

  void _navigateToDetail(Enrollment enrollment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SyllabusDetailScreen(
          syllabusId: enrollment.syllabusId,
          isEnrolled: true,
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
                isActive: false,
                onTap: () {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil(RouteNames.home, (route) => false);
                },
              ),
              _buildBottomItem(
                icon: Icons.smart_toy_outlined,
                label: 'AI',
                isActive: false,
                onTap: () {},
              ),
              _buildBottomItem(
                icon: Icons.school_outlined,
                label: 'Enrolled',
                isActive: true,
                onTap: () {},
              ),
              _buildBottomItem(
                icon: Icons.book_outlined,
                label: 'Vocab',
                isActive: false,
                onTap: () {},
              ),
              _buildBottomItem(
                icon: Icons.person_outline,
                label: 'Profile',
                isActive: false,
                onTap: () {
                  Navigator.of(context).pushNamed(RouteNames.profile);
                },
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
    required bool isActive,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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

