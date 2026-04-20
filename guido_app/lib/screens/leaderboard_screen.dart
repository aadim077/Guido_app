import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/leaderboard_model.dart';
import '../providers/course_provider.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          _buildBody(context),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFF0F172A),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFBBF24), size: 28),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Leaderboard',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Top learners by total points',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final provider = context.watch<CourseProvider>();

    if (provider.loadingLeaderboard) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF2563EB)),
        ),
      );
    }

    if (provider.error != null && provider.leaderboard.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, color: Colors.white38, size: 56),
                const SizedBox(height: 16),
                Text(
                  provider.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => provider.loadLeaderboard(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (provider.leaderboard.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Text(
            'No entries yet. Start learning to appear here!',
            style: TextStyle(color: Colors.white54),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final entries = provider.leaderboard;
    final top3 = entries.take(3).toList();
    final rest = entries.skip(3).toList();

    return SliverList(
      delegate: SliverChildListDelegate([
        // Top 3 podium
        _Podium(top3: top3),
        const SizedBox(height: 8),
        // Divider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Divider(color: Colors.white.withValues(alpha: 0.08), thickness: 1),
        ),
        const SizedBox(height: 8),
        // Rank 4+
        ...rest.map((e) => _LeaderboardTile(entry: e)),
        const SizedBox(height: 32),
      ]),
    );
  }
}

// ─── Podium ──────────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  final List<LeaderboardEntry> top3;

  const _Podium({required this.top3});

  @override
  Widget build(BuildContext context) {
    // Arrange: 2nd | 1st | 3rd
    final first = top3.isNotEmpty ? top3[0] : null;
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          Expanded(child: _PodiumCard(entry: second, position: 2, height: 130)),
          const SizedBox(width: 8),
          // 1st place
          Expanded(child: _PodiumCard(entry: first, position: 1, height: 168)),
          const SizedBox(width: 8),
          // 3rd place
          Expanded(child: _PodiumCard(entry: third, position: 3, height: 110)),
        ],
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final LeaderboardEntry? entry;
  final int position;
  final double height;

  const _PodiumCard({
    required this.entry,
    required this.position,
    required this.height,
  });

  Color get _medalColor {
    switch (position) {
      case 1:
        return const Color(0xFFFBBF24);
      case 2:
        return const Color(0xFF94A3B8);
      case 3:
        return const Color(0xFFCA8A04);
      default:
        return Colors.grey;
    }
  }

  Color get _bgColor {
    switch (position) {
      case 1:
        return const Color(0xFF1E3A8A);
      case 2:
        return const Color(0xFF1E293B);
      case 3:
        return const Color(0xFF1C1F2E);
      default:
        return const Color(0xFF1E293B);
    }
  }

  String get _medal {
    switch (position) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (entry == null) return SizedBox(height: height);

    final highlight = entry!.isCurrentUser;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? _medalColor.withValues(alpha: 0.8) : _medalColor.withValues(alpha: 0.3),
          width: highlight ? 2 : 1,
        ),
        boxShadow: position == 1
            ? [
                BoxShadow(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_medal, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          CircleAvatar(
            radius: position == 1 ? 22 : 18,
            backgroundColor: _medalColor.withValues(alpha: 0.2),
            child: Text(
              entry!.username.isNotEmpty ? entry!.username[0].toUpperCase() : '?',
              style: TextStyle(
                color: _medalColor,
                fontWeight: FontWeight.w800,
                fontSize: position == 1 ? 18 : 14,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              entry!.isCurrentUser ? 'You' : entry!.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: position == 1 ? 13 : 11,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${entry!.points} pts',
            style: TextStyle(
              color: _medalColor,
              fontWeight: FontWeight.w800,
              fontSize: position == 1 ? 13 : 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── List tile (rank 4+) ──────────────────────────────────────────────────────

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;

  const _LeaderboardTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isMe = entry.isCurrentUser;
    final rankColor = isMe ? const Color(0xFF60A5FA) : Colors.white38;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isMe
            ? const Color(0xFF1E3A8A).withValues(alpha: 0.6)
            : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: isMe
            ? Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.7), width: 1.5)
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '#${entry.rank}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: rankColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF334155),
              child: Text(
                entry.username.isNotEmpty ? entry.username[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        title: Text(
          isMe ? '${entry.username} (You)' : entry.username,
          style: TextStyle(
            color: isMe ? const Color(0xFF93C5FD) : Colors.white,
            fontWeight: isMe ? FontWeight.w700 : FontWeight.w600,
            fontSize: 14,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isMe
                ? const Color(0xFF2563EB).withValues(alpha: 0.3)
                : const Color(0xFF334155),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${entry.points} pts',
            style: TextStyle(
              color: isMe ? const Color(0xFF60A5FA) : Colors.white70,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
