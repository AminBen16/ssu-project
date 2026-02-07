class SocialPost {
  final String? id;
  final String content;
  final List<String> platforms; // e.g., ['facebook', 'twitter']
  final String status; // e.g., 'scheduled', 'posted', 'failed'
  final String authorId;
  final DateTime scheduledTime;
  final DateTime createdAt;

  SocialPost({
    this.id,
    required this.content,
    required this.platforms,
    required this.status,
    required this.authorId,
    required this.scheduledTime,
    required this.createdAt,
  });

  /// Creates a SocialPost object from a map (typically from API response).
  factory SocialPost.fromMap(Map<String, dynamic> data) {
    return SocialPost(
      id: data['id'],
      content: data['content'] ?? '',
      platforms: List<String>.from(data['platforms'] ?? []),
      status: data['status'] ?? 'unknown',
      authorId: data['authorId'] ?? '',
      scheduledTime: DateTime.parse(
          data['scheduledTime'] ?? DateTime.now().toIso8601String()),
      createdAt:
          DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
