class LeaderboardEntry {
  final int rank;
  final int userId;
  final String username;
  final int points;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.points,
    required this.isCurrentUser,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      username: (json['username'] ?? '') as String,
      points: (json['points'] as num?)?.toInt() ?? 0,
      isCurrentUser: (json['is_current_user'] as bool?) ?? false,
    );
  }
}
