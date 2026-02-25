import 'package:flutter/material.dart';
import '../../data/services/course_service.dart';
import '../../data/services/vocabulary_service.dart';
import '../../data/services/learning_service.dart';
import '../../data/models/course.dart';
import '../../data/models/vocabulary.dart';
import '../../config/routes/route_names.dart';
import '../vocabulary/vocabulary_detail_screen.dart';
import '../learning/flashcard_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final int courseId;
  final int? syllabusId;

  const CourseDetailScreen({Key? key, required this.courseId, this.syllabusId})
    : super(key: key);

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late final Future<_CourseData> _dataFuture;
  bool _isStartingLearning = false;

  static const _primaryBlue = Color(0xFF4F6CFF);

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<_CourseData> _loadData() async {
    // Load course and vocabularies in parallel for better performance
    final results = await Future.wait([
      courseService.getCourseById(widget.courseId),
      vocabularyService.listVocabulariesByCourse(widget.courseId),
    ]);
    return _CourseData(
      course: results[0] as Course?,
      vocabularies: results[1] as List<Vocabulary>,
    );
  }

  Future<void> _startLearning(Course course) async {
    if (_isStartingLearning) return;

    setState(() => _isStartingLearning = true);

    // Get syllabusId from widget or course's topic relationship
    final syllabusId = widget.syllabusId ?? 0;

    final learningSet = await learningService.startLearning(
      syllabusId: syllabusId,
    );

    if (mounted) {
      setState(() => _isStartingLearning = false);

      if (learningSet != null && learningSet.cards.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FlashcardScreen(
              learningSet: learningSet,
              courseTitle: course.title,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<_CourseData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || snapshot.data?.course == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text('Unable to load course'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go back'),
                    ),
                  ],
                ),
              );
            }

            final course = snapshot.data!.course!;
            final vocabularies = snapshot.data!.vocabularies;

            return Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
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
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              course.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Study button moved to SyllabusDetailScreen
                          // const SizedBox(width: 12),
                          // GestureDetector(
                          //   onTap: () => _startLearning(course),
                          //   child: Container(...),
                          // ),
                        ],
                      ),
                      if (course.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          course.description,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Vocabulary count
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.library_books_outlined,
                        color: _primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${vocabularies.length} words',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                // Vocabulary list
                Expanded(
                  child: vocabularies.isEmpty
                      ? const Center(child: Text('No vocabulary yet'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: vocabularies.length,
                          itemBuilder: (context, index) {
                            final vocab = vocabularies[index];
                            return _buildVocabCard(vocab);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildVocabCard(Vocabulary vocab) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VocabularyDetailScreen(vocabularyId: vocab.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E7FF)),
        ),
        child: Row(
          children: [
            // Image or placeholder
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: vocab.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        vocab.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.text_fields, color: _primaryBlue),
                      ),
                    )
                  : const Icon(Icons.text_fields, color: _primaryBlue),
            ),
            const SizedBox(width: 12),
            // Vocab info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vocab.mainTerm,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  if (vocab.reading.isNotEmpty &&
                      vocab.reading != vocab.mainTerm) ...[
                    const SizedBox(height: 2),
                    Text(
                      vocab.reading,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    vocab.mainMeaning,
                    style: const TextStyle(color: _primaryBlue, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _primaryBlue),
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
                onTap: () {},
              ),
              _buildBottomItem(
                icon: Icons.book_outlined,
                label: 'Vocab',
                isActive: true,
                onTap: () {
                  Navigator.of(context).pushNamed(RouteNames.myVocabulary);
                },
              ),
              _buildBottomItem(
                icon: Icons.school_outlined,
                label: 'Course',
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

class _CourseData {
  final Course? course;
  final List<Vocabulary> vocabularies;

  _CourseData({this.course, required this.vocabularies});
}
