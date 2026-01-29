import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/api/user_service.dart';
import '../../core/models/user_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  Widget _label(String text) => Text(text, style: const TextStyle(fontWeight: FontWeight.w600));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<UserModel?>(
          future: UserService.getMe(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final user = snapshot.data;

            return Column(
              children: [
                // Top bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text('Profile', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF5A4BFF),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
                  ),
                ),

                const SizedBox(height: 12),

                // Avatar and card
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    // Card
                    Container(
                      margin: const EdgeInsets.only(top: 56, left: 16, right: 16),
                      padding: const EdgeInsets.fromLTRB(16, 64, 16, 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF), // light pastel blue
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Upgrade box above Full name (right-aligned)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5A4BFF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF4639E6)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.star, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text('Upgrade', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Full name label on its own row, box + name on the row below
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  SizedBox(width: 100, child: _label('Full name')),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(width: 100),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: SizedBox(
                                      height: 56,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          // Gray box expanded to reach card edges (left offset = -(labelWidth + spacing))
                                          Positioned(
                                            left: -106,
                                            right: 0,
                                            child: Container(
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF6F7F9),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: const Color(0xFFE6E9EE)),
                                              ),
                                            ),
                                          ),
                                          // Name overlapping the gray box; shifted to have left padding inside the box
                                          Positioned(
                                            left: -94,
                                            top: 8,
                                            child: Text(
                                              user?.profile?.displayName ?? '',
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  SizedBox(width: 100, child: _label('Email')),
                                  const SizedBox(width: 6),
                                ],
                              ),
                              const SizedBox(height: 6),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Mail row with gray box behind
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 100,
                                child: _label('Mail'),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: SizedBox(
                                  height: 36,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Positioned(
                                        left: -106,
                                        right: 0,
                                        child: Container(
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF6F7F9),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: const Color(0xFFE6E9EE)),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: -94,
                                        right: 12,
                                        top: 0,
                                        bottom: 0,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 0.0),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              user?.email ?? '',
                                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),

                    // Avatar
                    Positioned(
                      top: 0,
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 56,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 52,
                              backgroundImage: user?.profile?.avatarUrl != null && user!.profile!.avatarUrl!.isNotEmpty
                                  ? NetworkImage(user.profile!.avatarUrl!)
                                  : null,
                              child: user?.profile?.avatarUrl == null || user!.profile!.avatarUrl!.isEmpty
                                  ? ClipOval(
                                      child: SvgPicture.asset(
                                        'lib/assets/icons/avatar_placeholder.svg',
                                        width: 104,
                                        height: 104,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Streak and daily goal area
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                          Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Streak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Row(children: [
                            // Gradient flame icon: light -> strong from top to bottom
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFFFE0CC), Color(0xFFFF4500)],
                              ).createShader(bounds),
                              child: const Icon(
                                Icons.local_fire_department,
                                size: 44,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${user?.streakCount ?? 0}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                          ])
                        ],
                      ),
                      const SizedBox(height: 8),
                      // White (now pastel blue) box under Streak containing 7 equal circles
                          Container(
                        height: 72,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE6E9EE)),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: List.generate(7, (index) {
                              const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    days[index],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFE6E9EE)),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Daily Goal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Slider(value: 30, min: 0, max: 60, onChanged: (_) {}),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
