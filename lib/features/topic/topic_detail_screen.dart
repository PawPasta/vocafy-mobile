import 'package:flutter/material.dart';
import '../../data/services/topic_service.dart';
import '../../data/services/learning_service.dart';
import '../../data/models/topic.dart';
import '../../config/routes/route_names.dart';
import '../course/course_detail_screen.dart';
import '../learning/flashcard_screen.dart';

class TopicDetailScreen extends StatefulWidget {
  final int topicId;

  const TopicDetailScreen({Key? key, required this.topicId}) : super(key: key);

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> {
  late final Future<Topic?> _topicFuture;

  static const _primaryBlue = Color(0xFF4F6CFF);
  static const _cardBackground = Color(0xFFF0F4FF);

  @override
  void initState() {
    super.initState();
    _topicFuture = topicService.getTopicById(widget.topicId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<Topic?>(
          future: _topicFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || snapshot.data == null) {
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
                    const Text('Không thể tải topic'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Quay lại'),
                    ),
                  ],
                ),
              );
            }

            final topic = snapshot.data!;

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
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'Courses',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ],
                  ),
                ),
                // Topic info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (topic.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          topic.description,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        '${topic.courses.length} lessons • ${topic.totalDays} days',
                        style: const TextStyle(
                          color: _primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Courses grid
                Expanded(
                  child: topic.courses.isEmpty
                      ? const Center(child: Text('Chưa có khóa học nào'))
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.9,
                              ),
                          itemCount: topic.courses.length,
                          itemBuilder: (context, index) {
                            final course = topic.courses[index];
                            return _buildCourseCard(course, topic.syllabusId);
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

  Widget _buildCourseCard(TopicCourse course, int? syllabusId) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                CourseDetailScreen(courseId: course.id, syllabusId: syllabusId),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: _cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder image area
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Center(
                  child: Icon(
                    Icons.book_outlined,
                    size: 40,
                    color: _primaryBlue,
                  ),
                ),
              ),
            ),
            // Course info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _primaryBlue,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Study button moved to SyllabusDetailScreen
                    const Text(
                      'Beginner',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
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

  Future<void> _startLearning(TopicCourse course, int? syllabusId) async {
    final learningSet = await learningService.startLearning(
      courseId: course.id,
      syllabusId: syllabusId ?? 0,
    );

    if (mounted) {
      if (learningSet != null && learningSet.cards.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FlashcardScreen(
              learningSet: learningSet,
              courseTitle: course.title,
              syllabusId: syllabusId,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không có từ vựng để học hoặc lỗi kết nối.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                isActive: false,
                onTap: () {},
              ),
              _buildBottomItem(
                icon: Icons.school_outlined,
                label: 'Course',
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
}
