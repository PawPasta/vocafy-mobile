import 'package:flutter/material.dart';
import '../../data/services/syllabus_service.dart';
import '../../data/models/syllabus_detail.dart';
import '../../config/routes/route_names.dart';
import '../topic/topic_detail_screen.dart';

class SyllabusDetailScreen extends StatefulWidget {
  final int syllabusId;

  const SyllabusDetailScreen({Key? key, required this.syllabusId}) : super(key: key);

  @override
  State<SyllabusDetailScreen> createState() => _SyllabusDetailScreenState();
}

class _SyllabusDetailScreenState extends State<SyllabusDetailScreen> {
  late final Future<SyllabusDetail?> _detailFuture;

  static const _primaryBlue = Color(0xFF4F6CFF);
  static const _primaryBlueDark = Color(0xFF3F5BFF);

  @override
  void initState() {
    super.initState();
    _detailFuture = _load();
  }

  Future<SyllabusDetail?> _load() async {
    final map = await syllabusService.getSyllabusById(widget.syllabusId);
    if (map == null) return null;
    return SyllabusDetail.fromJson(map);
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
                              image: (s.imageBackground.isNotEmpty || s.imageIcon.isNotEmpty)
                                  ? DecorationImage(
                                      image: NetworkImage(s.imageBackground.isNotEmpty ? s.imageBackground : s.imageIcon),
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
                                  Colors.black.withOpacity(0.25),
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
                              backgroundColor: Colors.white.withOpacity(0.8),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () => Navigator.of(context).maybePop(),
                              ),
                            ),
                          ),
                          // Fire icon
                          Positioned(
                            right: 12,
                            top: 12,
                            child: CircleAvatar(
                              backgroundColor: Colors.white.withOpacity(0.8),
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
                                        const Icon(Icons.folder_open_outlined, size: 18, color: Color(0xFF1F2937)),
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
                                        const Icon(Icons.access_time_outlined, size: 18, color: Color(0xFF1F2937)),
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
                                        const Icon(Icons.bar_chart, size: 18, color: Color(0xFF1F2937)),
                                        const SizedBox(width: 8),
                                        Text(
                                          s.categoryName.isNotEmpty ? s.categoryName : 'General',
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
                                    style: const TextStyle(color: Colors.black87),
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Learn and Test buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      // TODO: Navigate to learning screen
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Bắt đầu học...')),
                                      );
                                    },
                                    icon: const Icon(Icons.school_outlined, size: 20),
                                    label: const Text('Study', style: TextStyle(fontWeight: FontWeight.w600)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      // TODO: Navigate to test screen
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Bắt đầu kiểm tra...')),
                                      );
                                    },
                                    icon: const Icon(Icons.quiz_outlined, size: 20),
                                    label: const Text('Test', style: TextStyle(fontWeight: FontWeight.w600)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Divider
                            Container(
                              height: 1,
                              color: Colors.grey.shade200,
                            ),
                            const SizedBox(height: 16),
                            const Text('Course >', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                // Topics/Courses list
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final topics = s.topics;
                      if (index >= topics.length) return null;
                      
                      final topic = topics[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => TopicDetailScreen(topicId: topic.id),
                            ));
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
                                  child: const Icon(Icons.topic_outlined, color: _primaryBlue),
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
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Menu and play buttons
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: _primaryBlueDark,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.more_horiz, color: Colors.white, size: 18),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: _primaryBlueDark,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: s.topics.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  int _countCourses(SyllabusDetail s) {
    int count = 0;
    for (final t in s.topics) {
      count += t.courses.length;
    }
    return count;
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
              _buildBottomItem(icon: Icons.home, label: 'Home', isActive: false, onTap: () {
                Navigator.of(context).pushNamedAndRemoveUntil(RouteNames.home, (route) => false);
              }),
              _buildBottomItem(icon: Icons.smart_toy_outlined, label: 'AI', isActive: false, onTap: () {}),
              _buildBottomItem(icon: Icons.book_outlined, label: 'Vocab', isActive: false, onTap: () {}),
              _buildBottomItem(icon: Icons.school_outlined, label: 'Course', isActive: true, onTap: () {}),
              _buildBottomItem(icon: Icons.person_outline, label: 'Profile', isActive: false, onTap: () {
                Navigator.of(context).pushNamed(RouteNames.profile);
              }),
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
