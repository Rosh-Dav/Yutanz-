class Channel {
  final String id;
  final String title;
  final String description;
  final String thumbnail;
  final String customUrl;
  final int subscriberCount;
  final int totalViews;
  final int videoCount;
  final String uploadsPlaylistId;
  final DateTime publishedAt;

  Channel({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.customUrl,
    required this.subscriberCount,
    required this.totalViews,
    required this.videoCount,
    required this.uploadsPlaylistId,
    required this.publishedAt,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    // 1. If loaded from cached/serialized data (flat structure from toJson)
    if (json.containsKey('subscriberCount') && !json.containsKey('snippet')) {
      return Channel(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        thumbnail: json['thumbnail'] as String? ?? '',
        customUrl: json['customUrl'] as String? ?? '',
        subscriberCount: json['subscriberCount'] is int
            ? json['subscriberCount'] as int
            : int.tryParse(json['subscriberCount']?.toString() ?? '0') ?? 0,
        totalViews: json['totalViews'] is int
            ? json['totalViews'] as int
            : int.tryParse(json['totalViews']?.toString() ?? '0') ?? 0,
        videoCount: json['videoCount'] is int
            ? json['videoCount'] as int
            : int.tryParse(json['videoCount']?.toString() ?? '0') ?? 0,
        uploadsPlaylistId: json['uploadsPlaylistId'] as String? ?? '',
        publishedAt: json['publishedAt'] != null
            ? (DateTime.tryParse(json['publishedAt'] as String) ?? DateTime.now())
            : DateTime.now(),
      );
    }

    // 2. Raw YouTube API structure (nested snippet, statistics, contentDetails)
    final snippet = json['snippet'] as Map<String, dynamic>? ?? {};
    final statistics = json['statistics'] as Map<String, dynamic>? ?? {};
    final contentDetails = json['contentDetails'] as Map<String, dynamic>? ?? {};
    final relatedPlaylists = contentDetails['relatedPlaylists'] as Map<String, dynamic>? ?? {};

    return Channel(
      id: json['id'] as String? ?? '',
      title: snippet['title'] as String? ?? '',
      description: snippet['description'] as String? ?? '',
      thumbnail: (snippet['thumbnails']?['high']?['url'] ?? 
                 snippet['thumbnails']?['medium']?['url'] ??
                 snippet['thumbnails']?['default']?['url']) as String? ?? '',
      customUrl: snippet['customUrl'] as String? ?? '',
      subscriberCount: int.tryParse(statistics['subscriberCount'] as String? ?? '0') ?? 0,
      totalViews: int.tryParse(statistics['viewCount'] as String? ?? '0') ?? 0,
      videoCount: int.tryParse(statistics['videoCount'] as String? ?? '0') ?? 0,
      uploadsPlaylistId: relatedPlaylists['uploads'] as String? ?? '',
      publishedAt: snippet['publishedAt'] != null
          ? (DateTime.tryParse(snippet['publishedAt'] as String) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnail': thumbnail,
      'customUrl': customUrl,
      'subscriberCount': subscriberCount,
      'totalViews': totalViews,
      'videoCount': videoCount,
      'uploadsPlaylistId': uploadsPlaylistId,
      'publishedAt': publishedAt.toIso8601String(),
    };
  }
}