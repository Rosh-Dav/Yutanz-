import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:ytanalyzer/models/analytics_model.dart';
import '../models/channel_model.dart';
import '../models/video_model.dart';
import '../models/comment_model.dart';

class CacheService {
  final Box _cacheBox = Hive.box('cache');
  final Box _analyticsBox = Hive.box('analytics');

  // TTL constants (in hours)
  static const int channelTTL = 24;
  static const int videosTTL = 12;
  static const int commentsTTL = 6;

  // Save channel with timestamp
  void saveChannel(String channelId, Channel channel) {
    try {
      _cacheBox.put('channel_$channelId', {
        'data': jsonEncode(channel.toJson()),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      print('✅ Channel cached: $channelId');
    } catch (e) {
      print('❌ Error saving channel to cache: $e');
    }
  }

  // Get channel if cache is valid
  // Get channel if cache is valid
Channel? getChannel(String channelId) {
  try {
    final cached = _cacheBox.get('channel_$channelId');
    if (cached == null) {
      print('📭 No cached channel found for: $channelId');
      return null;
    }

    // Ensure cached is a Map
    if (cached is! Map) {
      print('⚠️ Invalid cache format for channel, clearing...');
      _cacheBox.delete('channel_$channelId');
      return null;
    }

    final Map<String, dynamic> cacheMap = Map<String, dynamic>.from(cached);
    
    if (!cacheMap.containsKey('timestamp') || !cacheMap.containsKey('data')) {
      print('⚠️ Invalid cache structure, clearing...');
      _cacheBox.delete('channel_$channelId');
      return null;
    }

    final timestamp = cacheMap['timestamp'];
    final data = cacheMap['data'];
    
    if (timestamp == null || data == null) {
      print('⚠️ Cache has null values, clearing...');
      _cacheBox.delete('channel_$channelId');
      return null;
    }

    if (_isValid(timestamp as int, channelTTL)) {
      print('✅ Using cached channel: $channelId');
      try {
        final decodedData = jsonDecode(data as String);
        return Channel.fromJson(decodedData);
      } catch (e) {
        print('⚠️ Error decoding channel data: $e');
        _cacheBox.delete('channel_$channelId');
        return null;
      }
    } else {
      print('⏰ Cache expired for channel: $channelId');
      _cacheBox.delete('channel_$channelId');
    }
  } catch (e) {
    print('❌ Error reading channel from cache: $e');
    _cacheBox.delete('channel_$channelId');
  }
  return null;
}

  // Save videos
  void saveVideos(String channelId, List<Video> videos) {
    try {
      _cacheBox.put('videos_$channelId', {
        'data': jsonEncode(videos.map((v) => v.toJson()).toList()),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      print('✅ Videos cached: ${videos.length} videos for $channelId');
    } catch (e) {
      print('❌ Error saving videos to cache: $e');
    }
  }

  // Get videos if cache is valid
  // Get videos if cache is valid
List<Video>? getVideos(String channelId) {
  try {
    final cached = _cacheBox.get('videos_$channelId');
    if (cached == null) {
      print('📭 No cached videos found for: $channelId');
      return null;
    }

    // Ensure cached is a Map
    if (cached is! Map) {
      print('⚠️ Invalid cache format for videos, clearing...');
      _cacheBox.delete('videos_$channelId');
      return null;
    }

    final Map<String, dynamic> cacheMap = Map<String, dynamic>.from(cached);
    
    if (!cacheMap.containsKey('timestamp') || !cacheMap.containsKey('data')) {
      print('⚠️ Invalid cache structure, clearing...');
      _cacheBox.delete('videos_$channelId');
      return null;
    }

    final timestamp = cacheMap['timestamp'];
    final data = cacheMap['data'];
    
    if (timestamp == null || data == null) {
      print('⚠️ Cache has null values, clearing...');
      _cacheBox.delete('videos_$channelId');
      return null;
    }

    if (_isValid(timestamp as int, videosTTL)) {
      print('✅ Using cached videos: $channelId');
      try {
        final List<dynamic> decodedData = jsonDecode(data as String);
        return decodedData.map((v) => Video.fromJson(v)).toList();
      } catch (e) {
        print('⚠️ Error decoding videos data: $e');
        _cacheBox.delete('videos_$channelId');
        return null;
      }
    } else {
      print('⏰ Cache expired for videos: $channelId');
      _cacheBox.delete('videos_$channelId');
    }
  } catch (e) {
    print('❌ Error reading videos from cache: $e');
    _cacheBox.delete('videos_$channelId');
  }
  return null;
}

  // Save comments
  void saveComments(String videoId, List<Comment> comments) {
    try {
      _cacheBox.put('comments_$videoId', {
        'data': jsonEncode(comments.map((c) => c.toJson()).toList()),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      print('✅ Comments cached: ${comments.length} comments for $videoId');
    } catch (e) {
      print('❌ Error saving comments to cache: $e');
    }
  }

  // Get comments if cache is valid
  // Get comments if cache is valid
List<Comment>? getComments(String videoId) {
  try {
    final cached = _cacheBox.get('comments_$videoId');
    if (cached == null) {
      print('📭 No cached comments found for: $videoId');
      return null;
    }

    // Ensure cached is a Map
    if (cached is! Map) {
      print('⚠️ Invalid cache format for comments, clearing...');
      _cacheBox.delete('comments_$videoId');
      return null;
    }

    final Map<String, dynamic> cacheMap = Map<String, dynamic>.from(cached);
    
    if (!cacheMap.containsKey('timestamp') || !cacheMap.containsKey('data')) {
      print('⚠️ Invalid cache structure, clearing...');
      _cacheBox.delete('comments_$videoId');
      return null;
    }

    final timestamp = cacheMap['timestamp'];
    final data = cacheMap['data'];
    
    // Check if timestamp and data are not null
    if (timestamp == null || data == null) {
      print('⚠️ Cache has null values, clearing...');
      _cacheBox.delete('comments_$videoId');
      return null;
    }

    if (_isValid(timestamp as int, commentsTTL)) {
      print('✅ Using cached comments: $videoId');
      try {
        final List<dynamic> decodedData = jsonDecode(data as String);
        return decodedData.map((v) => Comment.fromJson(v)).toList();
      } catch (e) {
        print('⚠️ Error decoding comments data: $e');
        _cacheBox.delete('comments_$videoId');
        return null;
      }
    } else {
      print('⏰ Cache expired for comments: $videoId');
      _cacheBox.delete('comments_$videoId');
    }
  } catch (e) {
    print('❌ Error reading comments from cache: $e');
    _cacheBox.delete('comments_$videoId');
  }
  return null;
}

  // Save analytics snapshot for growth tracking
  void saveAnalyticsSnapshot(String channelId, Map<String, dynamic> snapshot) {
    try {
      final key = 'snapshot_${channelId}_${DateTime.now().millisecondsSinceEpoch}';
      _analyticsBox.put(key, snapshot);
      print('✅ Analytics snapshot saved: $key');

      // Keep only last 60 snapshots
      _cleanOldSnapshots(channelId);
    } catch (e) {
      print('❌ Error saving analytics snapshot: $e');
    }
  }

  // Get analytics snapshots for growth calculation
  List<Map<String, dynamic>> getAnalyticsSnapshots(String channelId, {int days = 30}) {
    try {
      final cutoff = DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
      final snapshots = <Map<String, dynamic>>[];

      for (final key in _analyticsBox.keys) {
        if (key.toString().startsWith('snapshot_$channelId')) {
          final timestampStr = key.toString().split('_').last;
          final timestamp = int.tryParse(timestampStr) ?? 0;
          
          if (timestamp >= cutoff) {
            final data = _analyticsBox.get(key);
            if (data != null && data is Map) {
              snapshots.add(Map<String, dynamic>.from(data));
            }
          }
        }
      }

      print('📊 Found ${snapshots.length} analytics snapshots for $channelId');
      return snapshots;
    } catch (e) {
      print('❌ Error reading analytics snapshots: $e');
      return [];
    }
  }

  // Clear all cache
  void clearCache() {
    try {
      _cacheBox.clear();
      print('🗑️ Cache cleared');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  // Clear specific channel cache
  void clearChannelCache(String channelId) {
    try {
      _cacheBox.delete('channel_$channelId');
      _cacheBox.delete('videos_$channelId');
      print('🗑️ Channel cache cleared: $channelId');
    } catch (e) {
      print('❌ Error clearing channel cache: $e');
    }
  }

  // Check if cached data is still valid
  bool _isValid(int timestamp, int ttlHours) {
    final age = DateTime.now().millisecondsSinceEpoch - timestamp;
    return age < ttlHours * 3600 * 1000;
  }

  // Clean old snapshots
  void _cleanOldSnapshots(String channelId) {
    try {
      final keys = _analyticsBox.keys
          .where((k) => k.toString().startsWith('snapshot_$channelId'))
          .toList();

      if (keys.length > 60) {
        keys.sort();
        for (var i = 0; i < keys.length - 60; i++) {
          _analyticsBox.delete(keys[i]);
        }
        print('🗑️ Cleaned old snapshots, kept last 60');
      }
    } catch (e) {
      print('❌ Error cleaning old snapshots: $e');
    }
  }

  // Save sentiment analysis results
void saveSentimentAnalysis(String videoId, SentimentAnalysis analysis) {
  try {
    final data = analysis.toJson();
    data['timestamp'] = DateTime.now().millisecondsSinceEpoch;
    _cacheBox.put('sentiment_$videoId', data);
    print('✅ Sentiment analysis cached: $videoId');
  } catch (e) {
    print('❌ Error saving sentiment to cache: $e');
  }
}

// Get cached sentiment analysis
SentimentAnalysis? getSentimentAnalysis(String videoId) {
  try {
    final cached = _cacheBox.get('sentiment_$videoId');
    if (cached == null) {
      return null;
    }

    if (cached is! Map) {
      _cacheBox.delete('sentiment_$videoId');
      return null;
    }

    final Map<String, dynamic> cacheMap = Map<String, dynamic>.from(cached);
    
    if (!cacheMap.containsKey('timestamp')) {
      _cacheBox.delete('sentiment_$videoId');
      return null;
    }

    // Sentiment cache TTL: 24 hours
    if (_isValid(cacheMap['timestamp'] as int, 24)) {
      print('✅ Using cached sentiment analysis: $videoId');
      return SentimentAnalysis.fromJson(cacheMap);
    } else {
      print('⏰ Sentiment cache expired: $videoId');
      _cacheBox.delete('sentiment_$videoId');
    }
  } catch (e) {
    print('❌ Error reading sentiment from cache: $e');
    _cacheBox.delete('sentiment_$videoId');
  }
  return null;
}
}