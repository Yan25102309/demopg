class TweetComment {
  final int id;
  final int tweetId;
  final int? userId;
  final String username;
  final String content;
  final DateTime? createdAt;

  TweetComment({
    required this.id,
    required this.tweetId,
    required this.username,
    required this.content,
    this.userId,
    this.createdAt,
  });

  factory TweetComment.fromJson(Map<String, dynamic> json) {
    return TweetComment(
      id: json['id'] as int,
      tweetId: (json['tweetId'] as num).toInt(),
      userId: json['userId'] as int?,
      username: json['username'] as String? ?? 'Anónimo',
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
