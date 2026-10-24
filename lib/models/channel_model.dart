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
    final snippet = json['snippet'] as Map<String, dynamic>;
    final statistics = json['statistics'] as Map<String, dynamic>;
    final contentDetails = json['contentDetails'] as Map<String, dynamic>;

    return Channel(
      id: json['id'] as String,
      title: snippet['title'] as String? ?? '',
      description: snippet['description'] as String? ?? '',
      thumbnail: (snippet['thumbnails']?['high']?['url'] ?? 
                 snippet['thumbnails']?['default']?['url']) as String? ?? '',
      customUrl: snippet['customUrl'] as String? ?? '',
      subscriberCount: int.tryParse(statistics['subscriberCount'] as String? ?? '0') ?? 0,
      totalViews: int.tryParse(statistics['viewCount'] as String? ?? '0') ?? 0,
      videoCount: int.tryParse(statistics['videoCount'] as String? ?? '0') ?? 0,
      uploadsPlaylistId: contentDetails['relatedPlaylists']['uploads'] as String,
      publishedAt: DateTime.parse(snippet['publishedAt'] as String),
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