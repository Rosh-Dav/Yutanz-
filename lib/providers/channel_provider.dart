import 'package:flutter/material.dart';
import '../models/channel_model.dart';
import '../models/video_model.dart';
import '../models/analytics_model.dart';
import '../services/youtube_api_service.dart';
import '../services/cache_service.dart';

class ChannelProvider with ChangeNotifier {
  final YouTubeApiService _apiService = YouTubeApiService();
  final CacheService _cacheService = CacheService();

  Channel? _channel;
  List<Video> _videos = [];
  ChannelAnalytics? _analytics;
  bool _isLoading = false;
  String? _error;
  String _loadingStatus = '';

  Channel? get channel => _channel;
  List<Video> get videos => _videos;
  ChannelAnalytics? get analytics => _analytics;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get loadingStatus => _loadingStatus;

  // Load channel data
  Future<void> loadChannel(String channelId, {bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try cache first
      if (!forceRefresh) {
        final cachedChannel = _cacheService.getChannel(channelId);
        final cachedVideos = _cacheService.getVideos(channelId);

        if (cachedChannel != null && cachedVideos != null) {
          _channel = cachedChannel;
          _videos = cachedVideos;
          _analytics = ChannelAnalytics.fromVideos(_videos);
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      // Fetch from API
      _loadingStatus = 'Fetching channel info…';
      notifyListeners();
      _channel = await _apiService.fetchChannel(channelId);
      _cacheService.saveChannel(channelId, _channel!);

      // Save analytics snapshot for growth tracking
      _cacheService.saveAnalyticsSnapshot(channelId, {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'subscribers': _channel!.subscriberCount,
        'views': _channel!.totalViews,
        'videos': _channel!.videoCount,
      });

      // Fetch ALL videos (paginated — no limit)
      _loadingStatus = 'Loading all videos (this may take a moment)…';
      notifyListeners();
      final videoIds = await _apiService.fetchVideoIds(
        _channel!.uploadsPlaylistId,
      );

      _loadingStatus = 'Fetching details for ${videoIds.length} videos…';
      notifyListeners();
      _videos = await _apiService.fetchVideosStats(videoIds);
      _cacheService.saveVideos(channelId, _videos);

      // Calculate analytics
      _loadingStatus = 'Calculating analytics…';
      notifyListeners();
      _analytics = ChannelAnalytics.fromVideos(_videos);

      _loadingStatus = '';
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _loadingStatus = '';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sort videos by views
  void sortVideosByViews() {
    _videos.sort((a, b) => b.viewCount.compareTo(a.viewCount));
    notifyListeners();
  }

  // Sort videos by likes
  void sortVideosByLikes() {
    _videos.sort((a, b) {
      if (a.likesHidden && b.likesHidden) return 0;
      if (a.likesHidden) return 1;
      if (b.likesHidden) return -1;
      return b.likeCount.compareTo(a.likeCount);
    });
    notifyListeners();
  }

  // Sort videos by date (most recent)
  void sortVideosByDate() {
    _videos.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    notifyListeners();
  }

  // Sort videos by date (oldest first)
  void sortVideosByOldest() {
    _videos.sort((a, b) => a.publishedAt.compareTo(b.publishedAt));
    notifyListeners();
  }

  // Sort videos by engagement rate
  void sortVideosByEngagement() {
    _videos.sort((a, b) {
      if (a.likesHidden && b.likesHidden) return 0;
      if (a.likesHidden) return 1;
      if (b.likesHidden) return -1;
      final rateA = a.engagementRate ?? 0;
      final rateB = b.engagementRate ?? 0;
      return rateB.compareTo(rateA);
    });
    notifyListeners();
  }

  // Get growth data for last N days
  Map<String, dynamic> getGrowthData(int days) {
    if (_channel == null) return {};

    final snapshots = _cacheService.getAnalyticsSnapshots(_channel!.id, days: days);
    
    if (snapshots.length < 2) {
      return {
        'subscriberGrowth': 0,
        'viewGrowth': 0,
        'videoGrowth': 0,
      };
    }

    snapshots.sort((a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));
    final oldest = snapshots.first;
    final newest = snapshots.last;

    return {
      'subscriberGrowth': (newest['subscribers'] as int) - (oldest['subscribers'] as int),
      'viewGrowth': (newest['views'] as int) - (oldest['views'] as int),
      'videoGrowth': (newest['videos'] as int) - (oldest['videos'] as int),
      'snapshots': snapshots,
    };
  }

  // Clear data
  void clear() {
    _channel = null;
    _videos = [];
    _analytics = null;
    _error = null;
    notifyListeners();
  }

  // Refresh data
  Future<void> refresh() async {
    if (_channel != null) {
      await loadChannel(_channel!.id, forceRefresh: true);
    }
  }
}