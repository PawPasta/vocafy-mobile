import 'package:flutter/material.dart';

import '../../config/routes/route_names.dart';
import '../../data/models/vocabulary.dart';
import '../../data/services/vocabulary_service.dart';
import '../enrollments/enrollments_screen.dart';
import 'vocabulary_detail_screen.dart';

class MyVocabularyScreen extends StatefulWidget {
  const MyVocabularyScreen({super.key});

  @override
  State<MyVocabularyScreen> createState() => _MyVocabularyScreenState();
}

class _MyVocabularyScreenState extends State<MyVocabularyScreen> {
  final ScrollController _scrollController = ScrollController();

  static const int _pageSize = 10;
  static const _primaryBlue = Color(0xFF4F6CFF);
  static const _primaryBlueDark = Color(0xFF3F5BFF);
  static const _surfaceBlue = Color(0xFFF5F7FF);

  List<Vocabulary> _items = <Vocabulary>[];
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  int _totalElements = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _refresh();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _items = <Vocabulary>[];
      _page = 0;
      _hasMore = true;
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

    final response = await vocabularyService.listMyVocabularies(
      page: _page,
      size: _pageSize,
    );

    if (!mounted) return;

    setState(() {
      if (reset) {
        _items = response.content;
      } else {
        _items.addAll(response.content);
      }
      _totalElements = response.totalElements;
      _hasMore = !response.isLast && response.content.isNotEmpty;
      _page = response.page + 1;
      _loading = false;
      _loadingMore = false;
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_loading || _loadingMore || !_hasMore) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 280) {
      _loadPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceBlue,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                color: _primaryBlue,
                onRefresh: _refresh,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    final subtitle = _totalElements > 0
        ? '$_totalElements saved words from extension'
        : 'Saved words from extension';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryBlueDark, _primaryBlue],
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
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'My Vocabulary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryBlue),
      );
    }

    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
        children: [
          Icon(Icons.menu_book_rounded, size: 72, color: Colors.blue.shade300),
          const SizedBox(height: 18),
          const Text(
            'No saved vocabulary yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use the browser extension to save words. Pull down to refresh.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      );
    }

    final itemCount = _items.length + (_loadingMore ? 1 : 0);
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: CircularProgressIndicator(
                color: _primaryBlue,
                strokeWidth: 2.5,
              ),
            ),
          );
        }
        return _buildVocabCard(_items[index]);
      },
    );
  }

  Widget _buildVocabCard(Vocabulary vocab) {
    final meaning = vocab.meanings.isNotEmpty ? vocab.meanings.first : null;
    final example = meaning?.exampleSentence?.trim() ?? '';
    final exampleTranslation = meaning?.exampleTranslation?.trim() ?? '';
    final note = vocab.note.trim();
    final partOfSpeech = (meaning?.partOfSpeech ?? '').trim();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VocabularyDetailScreen(vocabularyId: vocab.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDDE5FF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vocab.mainTerm.isEmpty ? '(No term)' : vocab.mainTerm,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      if (vocab.reading.isNotEmpty &&
                          vocab.reading != vocab.mainTerm) ...[
                        const SizedBox(height: 4),
                        Text(
                          vocab.reading,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (partOfSpeech.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EDFF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      partOfSpeech,
                      style: const TextStyle(
                        color: _primaryBlueDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
            if (vocab.mainMeaning.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                vocab.mainMeaning,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
            if (example.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '"$example"',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
            if (exampleTranslation.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                exampleTranslation,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
            if (note.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFECF1FF)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.sticky_note_2_outlined,
                      size: 16,
                      color: Colors.amber.shade800,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        note,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (vocab.imageUrl != null && vocab.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  vocab.imageUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: const Color(0xFFF1F5FF),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: Color(0xFF8DA2FF),
                    ),
                  ),
                ),
              ),
            ],
          ],
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

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label will be available soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
