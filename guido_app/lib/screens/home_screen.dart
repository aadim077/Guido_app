import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/course_provider.dart';
import '../models/course_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadCourses();
      context.read<CourseProvider>().loadUserProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tabIndex,
        children: const [
          _HomeTab(),
          _PlaceholderTab(title: 'Learn', icon: Icons.menu_book_outlined),
          _PlaceholderTab(title: 'Code', icon: Icons.code_outlined),
          _PlaceholderTab(title: 'Profile', icon: Icons.person_outline),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Learn',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.code_outlined), activeIcon: Icon(Icons.code), label: 'Code'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final courseProvider = context.watch<CourseProvider>();

    final user = auth.user;
    final progress = courseProvider.userProgress;
    final courses = courseProvider.courses;

    final Course? featured = courses.isEmpty
        ? null
        : (courses.where((c) => c.isEnrolled).isNotEmpty ? courses.firstWhere((c) => c.isEnrolled) : courses.first);

    final moreCourses = courses.where((c) => featured == null || c.slug != featured.slug).toList();

    final isLoading = courseProvider.loadingCourses || courseProvider.loadingProgress;
    final error = courseProvider.error;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await courseProvider.loadCourses();
          await courseProvider.loadUserProgress();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            _Header(
              username: user?.username ?? 'there',
              subtitle: 'Ready to code today?',
              onLogout: () async {
                await context.read<AuthProvider>().logout();
                if (!context.mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
            const SizedBox(height: 18),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 22),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (error != null)
              _ErrorCard(
                message: error,
                onRetry: () async {
                  await courseProvider.loadCourses();
                  await courseProvider.loadUserProgress();
                },
              )
            else ...[
              _StatsRow(
                points: progress?.totalPoints ?? 0,
                percentage: progress?.overallProgressPercentage ?? 0,
                courses: progress?.enrolledCoursesCount ?? 0,
              ),
              const SizedBox(height: 22),
              _SectionHeader(
                title: 'Continue Learning',
                actionText: 'See All',
                onAction: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('See All coming soon')),
                ),
              ),
              const SizedBox(height: 12),
              if (featured == null)
                _EmptyCard(
                  title: 'No courses yet',
                  message: 'Browse courses and enroll to start learning.',
                )
              else
                _FeaturedCourseCard(course: featured),
              const SizedBox(height: 22),
              const _SectionHeader(title: 'More Courses'),
              const SizedBox(height: 10),
              if (moreCourses.isEmpty)
                const _EmptyListHint(text: 'No more courses to show right now.')
              else
                ...moreCourses.map((c) => _CourseListTile(course: c)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String username;
  final String subtitle;
  final VoidCallback onLogout;

  const _Header({
    required this.username,
    required this.subtitle,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $username! 👋',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onLogout,
          icon: const Icon(Icons.logout),
          tooltip: 'Logout',
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int points;
  final int percentage;
  final int courses;

  const _StatsRow({
    required this.points,
    required this.percentage,
    required this.courses,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            color: const Color(0xFF2563EB),
            icon: Icons.bolt,
            value: points.toString(),
            label: 'Points',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            color: const Color(0xFFF59E0B),
            icon: Icons.emoji_events,
            value: '$percentage%',
            label: 'Progress',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            color: const Color(0xFF16A34A),
            icon: Icons.menu_book,
            value: courses.toString(),
            label: 'Courses',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.color,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (actionText != null && onAction != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                actionText!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF2563EB),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FeaturedCourseCard extends StatelessWidget {
  final Course course;

  const _FeaturedCourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final c = course;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Featured',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward, color: Colors.white),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            c.title as String,
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            c.description as String,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.menu_book, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                '${c.totalLessons} lessons',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  (c.difficultyLabel as String).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CourseListTile extends StatelessWidget {
  final Course course;

  const _CourseListTile({required this.course});

  Color _difficultyDotColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return const Color(0xFF16A34A);
      case 'intermediate':
        return const Color(0xFFF59E0B);
      case 'advanced':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = course;

    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Course detail screen coming next: ${c.title}')),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _difficultyDotColor(c.difficulty as String),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.title as String,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${c.difficultyLabel} • ${c.totalLessons} lessons',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black45),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyCard({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.withValues(alpha: 0.10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(message, style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54)),
        ],
      ),
    );
  }
}

class _EmptyListHint extends StatelessWidget {
  final String text;

  const _EmptyListHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(text, style: const TextStyle(color: Colors.black54)),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
          const SizedBox(width: 10),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderTab({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: Colors.black38),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Coming soon', style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

