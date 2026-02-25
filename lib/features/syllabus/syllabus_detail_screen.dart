import 'package:flutter/material.dart';
import '../../data/services/syllabus_service.dart';
import '../../data/services/enrollment_service.dart';
import '../../data/services/learning_service.dart';
import '../../data/models/syllabus_detail.dart';
import '../topic/topic_detail_screen.dart';
import '../enrollments/enrollments_screen.dart';
import '../learning/flashcard_screen.dart';
import '../learning/quiz_screen.dart';

class SyllabusDetailScreen extends StatefulWidget {
  final int syllabusId;
  final bool isEnrolled;
  final bool showTestGlow;

  const SyllabusDetailScreen({
    required this.syllabusId,
    this.isEnrolled = false,
    this.showTestGlow = false,
    super.key,
  });

  @override
  State<SyllabusDetailScreen> createState() => _SyllabusDetailScreenState();
}

class _SyllabusDetailScreenState extends State<SyllabusDetailScreen>
    with SingleTickerProviderStateMixin {
  late final Future<SyllabusDetail?> _detailFuture;
  bool _isEnrolling = false;
  bool _isStartingLearning = false;
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  static const _primaryBlue = Color(0xFF4F6CFF);

  @override
  void initState() {
    super.initState();
    _detailFuture = _load();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    if (widget.showTestGlow) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<SyllabusDetail?> _load() async {
    final map = await syllabusService.getSyllabusById(widget.syllabusId);
    if (map == null) return null;
    return SyllabusDetail.fromJson(map);
  }

  Future<void> _enrollSyllabus() async {
    if (_isEnrolling) return;

    final selectedLanguage = await _showTargetLanguageDialog();
    if (selectedLanguage == null) return;

    setState(() => _isEnrolling = true);

    final success = await enrollmentService.enrollSyllabus(
      widget.syllabusId,
      preferredTargetLanguage: selectedLanguage,
    );

    if (mounted) {
      setState(() => _isEnrolling = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enrollment successful!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to enrollments screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const EnrollmentsScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to enroll. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showTargetLanguageDialog() {
    String selectedLanguage = 'EN';

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Preferred Learning Language'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: EnrollmentService.supportedTargetLanguages.map((
                  lang,
                ) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ChoiceChip(
                      label: Text(_targetLanguageLabel(lang)),
                      selected: selectedLanguage == lang,
                      onSelected: (_) =>
                          setDialogState(() => selectedLanguage = lang),
                    ),
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(selectedLanguage),
                  child: const Text('Enroll'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _targetLanguageLabel(String code) {
    switch (code) {
      case 'EN':
        return 'EN - English';
      case 'VI':
        return 'VI - Vietnamese';
      case 'JA':
        return 'JA - Japanese';
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<SyllabusDetail?>(
          future: _detailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || snapshot.data == null) {
              return Center(child: Text('Error loading syllabus'));
            }

            final s = snapshot.data!;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with background image
                      Stack(
                        children: [
                          Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              image:
                                  (s.imageBackground.isNotEmpty ||
                                      s.imageIcon.isNotEmpty)
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        s.imageBackground.isNotEmpty
                                            ? s.imageBackground
                                            : s.imageIcon,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              color: Colors.blueGrey.shade100,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                          ),
                          // Gradient overlay
                          Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.25),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          // Back button
                          Positioned(
                            left: 12,
                            top: 12,
                            child: CircleAvatar(
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.8,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                              ),
                            ),
                          ),
                          // Fire icon
                          Positioned(
                            right: 12,
                            top: 12,
                            child: CircleAvatar(
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.8,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.local_fire_department),
                                onPressed: () {},
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          s.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Stats column
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.folder_open_outlined,
                                          size: 18,
                                          color: Color(0xFF1F2937),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${_countCourses(s)} courses',
                                          style: const TextStyle(
                                            color: Color(0xFF1F2937),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time_outlined,
                                          size: 18,
                                          color: Color(0xFF1F2937),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${s.totalDays} days',
                                          style: const TextStyle(
                                            color: Color(0xFF1F2937),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.bar_chart,
                                          size: 18,
                                          color: Color(0xFF1F2937),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          s.categoryName.isNotEmpty
                                              ? s.categoryName
                                              : 'General',
                                          style: const TextStyle(
                                            color: Color(0xFF1F2937),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 20),
                                // Description
                                Expanded(
                                  child: Text(
                                    s.description,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Divider
                            Container(height: 1, color: Colors.grey.shade200),
                            const SizedBox(height: 16),
                            const Text(
                              'Course >',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                // Topics/Courses list
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final topics = s.topics;
                    if (index >= topics.length) return null;

                    final topic = topics[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  TopicDetailScreen(topicId: topic.id),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _primaryBlue,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              // Icon container
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.topic_outlined,
                                  color: _primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Text content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      topic.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${topic.courses.length} lessons',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Arrow icon to indicate navigation
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.white,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }, childCount: s.topics.length),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: widget.isEnrolled
          ? _buildEnrolledButtons()
          : _buildBottomNav(),
    );
  }

  Future<void> _startLearning() async {
    if (_isStartingLearning) return;
    setState(() => _isStartingLearning = true);

    final learningSet = await learningService.startLearning(
      syllabusId: widget.syllabusId,
    );

    if (mounted) {
      setState(() => _isStartingLearning = false);

      if (learningSet != null && learningSet.cards.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FlashcardScreen(
              learningSet: learningSet,
              courseTitle: 'Vocabulary Study',
              syllabusId: widget.syllabusId,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No vocabulary to learn or a connection error.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int _countCourses(SyllabusDetail s) {
    int count = 0;
    for (final t in s.topics) {
      count += t.courses.length;
    }
    return count;
  }

  Widget _buildEnrolledButtons() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            // Study button
            Expanded(
              child: GestureDetector(
                onTap: _isStartingLearning ? null : _startLearning,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isStartingLearning
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.school_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Study',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Test button
            Expanded(
              child: AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return GestureDetector(
                    onTap: () {
                      _glowController.stop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(
                            syllabusId: widget.syllabusId,
                            syllabusTitle: 'Vocabulary Quiz',
                          ),
                        ),
                      );
                    },
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: widget.showTestGlow
                            ? [
                                BoxShadow(
                                  color: Colors.orange.withValues(
                                    alpha: _glowAnimation.value * 0.6,
                                  ),
                                  blurRadius: 20 * _glowAnimation.value,
                                  spreadRadius: 4 * _glowAnimation.value,
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.orange.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.quiz_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Quiz',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
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
        child: GestureDetector(
          onTap: _isEnrolling ? null : _enrollSyllabus,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: _primaryBlue,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: _isEnrolling
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Enroll Now',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
