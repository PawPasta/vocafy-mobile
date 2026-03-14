import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/routes/route_names.dart';
import '../../core/data/models/feedback_item.dart';
import '../../core/data/services/feedback_service.dart';
import '../enrollments/enrollments_screen.dart';

const _feedbackPrimaryBlue = Color(0xFF4F6CFF);
const _feedbackPrimaryBlueDark = Color(0xFF3F5BFF);
const _feedbackSurfaceBlue = Color(0xFFF5F7FF);
const _softErrorOrange = Color(0xFFF4A261);

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final GlobalKey<_FeedbackListSectionState> _myFeedbacksKey =
      GlobalKey<_FeedbackListSectionState>();
  final GlobalKey<_FeedbackListSectionState> _allFeedbacksKey =
      GlobalKey<_FeedbackListSectionState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openCreateFeedbackSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateFeedbackSheet(),
    );

    if (created == true && mounted) {
      _myFeedbacksKey.currentState?.refresh();
      _allFeedbacksKey.currentState?.refresh();
      _tabController.animateTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _feedbackSurfaceBlue,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabs(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _FeedbackListSection(
                    key: _myFeedbacksKey,
                    mineOnly: true,
                    emptyTitle: 'You have not submitted any feedback yet',
                    emptySubtitle:
                        'Tap the Feedback button to add a new review.',
                  ),
                  _FeedbackListSection(
                    key: _allFeedbacksKey,
                    mineOnly: false,
                    emptyTitle: 'No feedback yet',
                    emptySubtitle:
                        'The list will appear when users submit feedback.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateFeedbackSheet,
        backgroundColor: _feedbackPrimaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.rate_review_outlined),
        label: const Text(
          'Feedback',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_feedbackPrimaryBlueDark, _feedbackPrimaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Feedback',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Track ratings and admin replies in a conversation view.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE5FF)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: _feedbackPrimaryBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF1F2937),
        tabs: const [
          Tab(text: 'Mine'),
          Tab(text: 'All'),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 16),
        child: Container(
          height: 76,
          decoration: BoxDecoration(
            color: _feedbackPrimaryBlue,
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
                onTap: () => _showComingSoon('AI'),
              ),
              _buildBottomItem(
                icon: Icons.school_outlined,
                label: 'Enrolled',
                isActive: false,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EnrollmentsScreen(),
                    ),
                  );
                },
              ),
              _buildBottomItem(
                icon: Icons.book_outlined,
                label: 'Vocab',
                isActive: false,
                onTap: () {
                  Navigator.of(context).pushNamed(RouteNames.myVocabulary);
                },
              ),
              _buildBottomItem(
                icon: Icons.rate_review_outlined,
                label: 'Feedback',
                isActive: true,
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
        offset: Offset(0, isActive ? -6 : 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isActive)
              Transform.translate(
                offset: const Offset(0, -2),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: _feedbackPrimaryBlue, width: 2),
                  ),
                  child: Icon(icon, color: _feedbackPrimaryBlue, size: 22),
                ),
              )
            else
              Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is in development.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _CreateFeedbackSheet extends StatefulWidget {
  const _CreateFeedbackSheet();

  @override
  State<_CreateFeedbackSheet> createState() => _CreateFeedbackSheetState();
}

class _CreateFeedbackSheetState extends State<_CreateFeedbackSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  int _rating = 5;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both title and content.')),
      );
      return;
    }

    setState(() => _submitting = true);
    final result = await feedbackService.createFeedback(
      rating: _rating,
      title: title,
      content: content,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? Colors.green : _softErrorOrange,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (result.success) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            14,
            16,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Add feedback',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Rate the app and share suggestions so the team can improve.',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 13.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Rating',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) {
                    final selected = index < _rating;
                    return IconButton(
                      onPressed: _submitting
                          ? null
                          : () => setState(() => _rating = index + 1),
                      icon: Icon(
                        selected
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: selected ? Colors.amber.shade700 : Colors.grey,
                        size: 32,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  enabled: !_submitting,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'Example: THE APP NEEDS MORE DETAIL',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contentController,
                  enabled: !_submitting,
                  minLines: 4,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: 'Content',
                    hintText: 'Describe your feedback in detail...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _feedbackPrimaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.2,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      _submitting ? 'Submitting...' : 'Submit feedback',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackListSection extends StatefulWidget {
  final bool mineOnly;
  final String emptyTitle;
  final String emptySubtitle;

  const _FeedbackListSection({
    super.key,
    required this.mineOnly,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  State<_FeedbackListSection> createState() => _FeedbackListSectionState();
}

class _FeedbackListSectionState extends State<_FeedbackListSection> {
  static const int _pageSize = 10;

  final ScrollController _scrollController = ScrollController();
  List<AppFeedback> _items = <AppFeedback>[];
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  int _totalElements = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    refresh();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    setState(() {
      _loading = true;
      _items = <AppFeedback>[];
      _hasMore = true;
      _page = 0;
      _totalElements = 0;
    });
    await _loadPage(reset: true);
  }

  Future<void> _loadPage({bool reset = false}) async {
    if (_loadingMore && !reset) return;
    if (!_hasMore && !reset) return;

    if (reset) {
      _loading = true;
    } else {
      _loadingMore = true;
    }
    if (mounted) setState(() {});

    final pageData = widget.mineOnly
        ? await feedbackService.listMyFeedbacks(page: _page, size: _pageSize)
        : await feedbackService.listFeedbacks(page: _page, size: _pageSize);

    if (!mounted) return;

    setState(() {
      if (reset) {
        _items = pageData.content;
      } else {
        _items.addAll(pageData.content);
      }
      _page = pageData.page + 1;
      _totalElements = pageData.totalElements;
      _hasMore = !pageData.isLast && pageData.content.isNotEmpty;
      _loading = false;
      _loadingMore = false;
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_loading || _loadingMore || !_hasMore) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 260) {
      _loadPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: _feedbackPrimaryBlue,
      onRefresh: refresh,
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 170),
          Center(child: CircularProgressIndicator(color: _feedbackPrimaryBlue)),
        ],
      );
    }

    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 120),
        children: [
          const Icon(Icons.forum_outlined, size: 72, color: Color(0xFF9CA3AF)),
          const SizedBox(height: 16),
          Text(
            widget.emptyTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.emptySubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          ),
        ],
      );
    }

    final itemCount = _items.length + (_loadingMore ? 1 : 0);
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      itemCount: itemCount + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '$_totalElements feedback',
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

        final itemIndex = index - 1;
        if (itemIndex >= _items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: CircularProgressIndicator(
                color: _feedbackPrimaryBlue,
                strokeWidth: 2.4,
              ),
            ),
          );
        }

        return _FeedbackThreadCard(
          item: _items[itemIndex],
          showUserName: !widget.mineOnly,
        );
      },
    );
  }
}

class _FeedbackThreadCard extends StatelessWidget {
  final AppFeedback item;
  final bool showUserName;

  const _FeedbackThreadCard({required this.item, required this.showUserName});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.78;
    final createdAt = _formatDate(item.createdAt);
    final repliedAt = _formatDate(item.repliedAt);

    final displayName = item.userDisplayName.trim().isNotEmpty
        ? item.userDisplayName.trim()
        : (item.userEmail.trim().isNotEmpty ? item.userEmail.trim() : 'User');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showUserName)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                displayName,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: width),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EDFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title.isEmpty ? 'No title' : item.title,
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _RatingBadge(rating: item.rating),
                      ],
                    ),
                    if (item.content.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.content.trim(),
                        style: const TextStyle(
                          color: Color(0xFF374151),
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                    if (createdAt.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        createdAt,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (item.hasAdminReply)
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDDE5FF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Admin',
                        style: TextStyle(
                          color: _feedbackPrimaryBlue,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.adminReply.trim(),
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                      if (repliedAt.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          repliedAt,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            )
          else
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 2),
                child: Text(
                  'No admin reply yet',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime.toLocal());
  }
}

class _RatingBadge extends StatelessWidget {
  final int rating;

  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          final selected = index < rating;
          return Icon(
            selected ? Icons.star_rounded : Icons.star_border_rounded,
            color: selected ? Colors.amber.shade700 : const Color(0xFF9CA3AF),
            size: 14,
          );
        }),
      ),
    );
  }
}
