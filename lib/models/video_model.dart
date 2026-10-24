class Video {
  final String id;
  final String title;
  final String description;
  final String thumbnail;
  final DateTime publishedAt;
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final List<String> tags;
  final String duration;
  final bool likesHidden;

  Video({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.publishedAt,
    required this.viewCount,
    required this.likeCount,
    required this.commentCount,
    required this.tags,
    required this.duration,
    this.likesHidden = false,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    final snippet = json['snippet'] as Map<String, dynamic>?;
    final statistics = json['statistics'] as Map<String, dynamic>? ?? {};
    final contentDetails = json['contentDetails'] as Map<String, dynamic>? ?? {};

    final bool likesHidden;
    final int likeCount;

    if (json.containsKey('likesHidden')) {
      // From cached/serialized data
      likesHidden = json['likesHidden'] as bool? ?? false;
      likeCount = json['likeCount'] as int? ?? 0;
    } else {
      // From YouTube API: likeCount property is only present if creator didn't disable likes
      final hasLikes = statistics.containsKey('likeCount') && statistics['likeCount'] != null;
      likesHidden = !hasLikes;
      likeCount = hasLikes ? (int.tryParse(statistics['likeCount'] as String? ?? '0') ?? 0) : 0;
    }

    final title = snippet != null ? (snippet['title'] as String? ?? '') : (json['title'] as String? ?? '');
    final description = snippet != null ? (snippet['description'] as String? ?? '') : (json['description'] as String? ?? '');
    final thumbnail = snippet != null
        ? ((snippet['thumbnails']?['high']?['url'] ?? 
            snippet['thumbnails']?['medium']?['url'] ??
            snippet['thumbnails']?['default']?['url']) as String? ?? '')
        : (json['thumbnail'] as String? ?? '');
    final publishedAtStr = snippet != null ? snippet['publishedAt'] as String : json['publishedAt'] as String;
    final publishedAt = DateTime.parse(publishedAtStr);
    final viewCount = snippet != null
        ? (int.tryParse(statistics['viewCount'] as String? ?? '0') ?? 0)
        : (json['viewCount'] as int? ?? 0);
    final commentCount = snippet != null
        ? (int.tryParse(statistics['commentCount'] as String? ?? '0') ?? 0)
        : (json['commentCount'] as int? ?? 0);
    final tags = snippet != null
        ? ((snippet['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [])
        : ((json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? []);
    final duration = snippet != null
        ? (contentDetails['duration'] as String? ?? '')
        : (json['duration'] as String? ?? '');

    return Video(
      id: json['id'] as String,
      title: title,
      description: description,
      thumbnail: thumbnail,
      publishedAt: publishedAt,
      viewCount: viewCount,
      likeCount: likeCount,
      commentCount: commentCount,
      tags: tags,
      duration: duration,
      likesHidden: likesHidden,
    );
  }

  int get durationInSeconds {
    if (duration.isEmpty) return 0;
    final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
    final match = regex.firstMatch(duration);
    if (match == null) return 0;
    final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
    final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;
    return hours * 3600 + minutes * 60 + seconds;
  }

  /// True if duration ≤ 180 seconds — YouTube's current Shorts definition (updated Oct 2024).
  /// A duration of 0 means metadata is missing; we treat those as long-form to be safe.
  bool get isShort => durationInSeconds > 0 && durationInSeconds <= 180;

  /// Full engagement rate = ((likes + comments) / views) * 100.
  /// Returns null if likes are hidden by the creator or views = 0,
  /// preventing misleading 0% or falsely low scores.
  double? get engagementRate {
    if (likesHidden || viewCount == 0) return null;
    return ((likeCount + commentCount) / viewCount) * 100;
  }

  /// Comment engagement rate based solely on comments
  double get commentRate {
    if (viewCount == 0) return 0;
    return (commentCount / viewCount) * 100;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnail': thumbnail,
      'publishedAt': publishedAt.toIso8601String(),
      'viewCount': viewCount,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'tags': tags,
      'duration': duration,
      'likesHidden': likesHidden,
    };
  }
}