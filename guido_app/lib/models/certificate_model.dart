class Certificate {
  final int id;
  final String certificateId;
  final String courseTitle;
  final String courseDifficulty;
  final DateTime issuedAt;
  final String downloadUrl;

  const Certificate({
    required this.id,
    required this.certificateId,
    required this.courseTitle,
    required this.courseDifficulty,
    required this.issuedAt,
    required this.downloadUrl,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) {
    final issuedAtRaw = (json['issued_at'] ?? '') as String;
    final issuedAt = DateTime.tryParse(issuedAtRaw) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

    return Certificate(
      id: (json['id'] as num?)?.toInt() ?? 0,
      certificateId: (json['certificate_id'] ?? '') as String,
      courseTitle: (json['course_title'] ?? '') as String,
      courseDifficulty: (json['course_difficulty'] ?? '') as String,
      issuedAt: issuedAt,
      downloadUrl: (json['download_url'] ?? '') as String,
    );
  }
}

