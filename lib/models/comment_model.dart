class Comment {
  final String id;
  final String text;
  final String authorName;
  final String authorProfileImage;
  final int likeCount;
  final DateTime publishedAt;

  Comment({
    required this.id,
    required this.text,
    required this.authorName,
    required this.authorProfileImage,
    required this.likeCount,
    required this.publishedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    try {
      // 1. If it's cached/serialized data (flat structure from toJson)
      if (json.containsKey('text') && json.containsKey('authorName')) {
        return Comment(
          id: json['id'] as String? ?? '',
          text: json['text'] as String? ?? '',
          authorName: json['authorName'] as String? ?? 'Unknown',
          authorProfileImage: json['authorProfileImage'] as String? ?? '',
          likeCount: json['likeCount'] as int? ?? 0,
          publishedAt: DateTime.parse(
              json['publishedAt'] as String? ?? DateTime.now().toIso8601String()),
        );
      }

      // 2. YouTube API commentThread structure
      final snippet = json['snippet']?['topLevelComment']?['snippet'] ?? json['snippet'];
      
      if (snippet == null) {
        throw Exception('Invalid comment structure');
      }
      
      return Comment(
        id: json['id'] as String? ?? '',
        text: snippet['textDisplay'] as String? ?? snippet['textOriginal'] as String? ?? '',
        authorName: snippet['authorDisplayName'] as String? ?? 'Unknown',
        authorProfileImage: snippet['authorProfileImageUrl'] as String? ?? '',
        likeCount: snippet['likeCount'] as int? ?? 0,
        publishedAt: DateTime.parse(snippet['publishedAt'] as String? ?? DateTime.now().toIso8601String()),
      );
    } catch (e) {
      print('⚠️ Error parsing comment: $e');
      // Return a default comment if parsing fails
      return Comment(
        id: json['id']?.toString() ?? '',
        text: 'Error parsing comment',
        authorName: 'Unknown',
        authorProfileImage: '',
        likeCount: 0,
        publishedAt: DateTime.now(),
      );
    }
  }

  /// Parse a reply comment (replies have a flat snippet, not nested under topLevelComment)
  factory Comment.fromReplyJson(Map<String, dynamic> json) {
    try {
      final snippet = json['snippet'] as Map<String, dynamic>?;
      
      if (snippet == null) {
        throw Exception('Invalid reply comment structure');
      }

      return Comment(
        id: json['id'] as String? ?? '',
        text: snippet['textDisplay'] as String? ?? snippet['textOriginal'] as String? ?? '',
        authorName: snippet['authorDisplayName'] as String? ?? 'Unknown',
        authorProfileImage: snippet['authorProfileImageUrl'] as String? ?? '',
        likeCount: snippet['likeCount'] as int? ?? 0,
        publishedAt: DateTime.parse(snippet['publishedAt'] as String? ?? DateTime.now().toIso8601String()),
      );
    } catch (e) {
      print('⚠️ Error parsing reply comment: $e');
      return Comment(
        id: json['id']?.toString() ?? '',
        text: 'Error parsing reply',
        authorName: 'Unknown',
        authorProfileImage: '',
        likeCount: 0,
        publishedAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'authorName': authorName,
      'authorProfileImage': authorProfileImage,
      'likeCount': likeCount,
      'publishedAt': publishedAt.toIso8601String(),
    };
  }
}