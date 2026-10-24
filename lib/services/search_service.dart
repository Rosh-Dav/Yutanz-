import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SearchService {
  final String _apiKey = dotenv.env['YOUTUBE_API_KEY'] ?? '';
  static const String _baseUrl = 'www.googleapis.com';

  // Main search function that handles all input types
  Future<String> getChannelIdFromInput(String input) async {
    final trimmedInput = input.trim();

    // 1. Check if it's already a valid channel ID (starts with UC and 24 chars)
    if (_isChannelId(trimmedInput)) {
      return trimmedInput;
    }

    // 2. Check if it's a handle (@username)
    if (trimmedInput.startsWith('@')) {
      return await _searchByHandle(trimmedInput);
    }

    // 3. Check if it's a URL
    if (trimmedInput.contains('youtube.com') || trimmedInput.contains('youtu.be')) {
      return await _extractChannelFromUrl(trimmedInput);
    }

    // 4. Otherwise, treat it as a search query (channel name or keyword)
    return await _searchChannelByName(trimmedInput);
  }

  // Check if string is a valid channel ID
  bool _isChannelId(String input) {
    return input.startsWith('UC') && input.length == 24;
  }

  // Search by handle (@username)
  Future<String> _searchByHandle(String handle) async {
    try {
      // Remove @ if present
      final cleanHandle = handle.replaceFirst('@', '');
      
      // Search for the handle
      final uri = Uri.https(_baseUrl, '/youtube/v3/search', {
        'part': 'snippet',
        'q': cleanHandle,
        'type': 'channel',
        'maxResults': '1',
        'key': _apiKey,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final items = json['items'] as List;

        if (items.isNotEmpty) {
          return items[0]['id']['channelId'] as String;
        }
      }

      throw Exception('Channel not found with handle: $handle');
    } catch (e) {
      throw Exception('Error searching by handle: $e');
    }
  }

  // Extract channel ID from URL
  Future<String> _extractChannelFromUrl(String url) async {
    try {
      // Pattern 1: youtube.com/channel/CHANNEL_ID
      final channelPattern = RegExp(r'youtube\.com/channel/([^/?#]+)');
      final channelMatch = channelPattern.firstMatch(url);
      if (channelMatch != null) {
        return channelMatch.group(1)!;
      }

      // Pattern 2: youtube.com/@handle
      final handlePattern = RegExp(r'youtube\.com/@([^/?#]+)');
      final handleMatch = handlePattern.firstMatch(url);
      if (handleMatch != null) {
        return await _searchByHandle('@${handleMatch.group(1)}');
      }

      // Pattern 3: youtube.com/c/customname or youtube.com/user/username
      final customPattern = RegExp(r'youtube\.com/(?:c|user)/([^/?#]+)');
      final customMatch = customPattern.firstMatch(url);
      if (customMatch != null) {
        return await _searchChannelByName(customMatch.group(1)!);
      }

      // Pattern 4: Video URL - extract video ID and get channel from it
      final videoPatterns = [
        RegExp(r'youtube\.com/watch\?v=([^&]+)'),
        RegExp(r'youtu\.be/([^?]+)'),
      ];

      for (final pattern in videoPatterns) {
        final match = pattern.firstMatch(url);
        if (match != null) {
          final videoId = match.group(1)!;
          return await _getChannelFromVideoId(videoId);
        }
      }

      throw Exception('Could not extract channel from URL');
    } catch (e) {
      throw Exception('Error extracting channel from URL: $e');
    }
  }

  // Get channel ID from video ID
  Future<String> _getChannelFromVideoId(String videoId) async {
    try {
      final uri = Uri.https(_baseUrl, '/youtube/v3/videos', {
        'part': 'snippet',
        'id': videoId,
        'key': _apiKey,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final items = json['items'] as List;

        if (items.isNotEmpty) {
          return items[0]['snippet']['channelId'] as String;
        }
      }

      throw Exception('Video not found');
    } catch (e) {
      throw Exception('Error getting channel from video: $e');
    }
  }

  // Search channel by name/keyword
  Future<String> _searchChannelByName(String query) async {
    try {
      final uri = Uri.https(_baseUrl, '/youtube/v3/search', {
        'part': 'snippet',
        'q': query,
        'type': 'channel',
        'maxResults': '5',
        'key': _apiKey,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final items = json['items'] as List;

        if (items.isEmpty) {
          throw Exception('No channels found for: $query');
        }

        // Return results for user to choose
        return items[0]['id']['channelId'] as String;
      } else if (response.statusCode == 403) {
        throw Exception('API quota exceeded');
      }

      throw Exception('Search failed');
    } catch (e) {
      throw Exception('Error searching channel: $e');
    }
  }

  // Get multiple search results for user selection (with subscriber count)
Future<List<Map<String, String>>> searchChannels(String query) async {
  try {
    final uri = Uri.https(_baseUrl, '/youtube/v3/search', {
      'part': 'snippet',
      'q': query,
      'type': 'channel',
      'maxResults': '10',
      'key': _apiKey,
    });

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final items = json['items'] as List;

      // Get channel IDs to fetch statistics
      final channelIds = items.map((item) => item['id']['channelId'] as String).toList();
      
      // Fetch channel statistics (subscriber counts)
      final channelStats = await _getChannelStatistics(channelIds);

      return items.map((item) {
        final snippet = item['snippet'];
        final channelId = item['id']['channelId'] as String;
        final stats = channelStats[channelId];
        
        return {
          'channelId': channelId,
          'title': snippet['title'] as String,
          'description': snippet['description'] as String,
          'thumbnail': snippet['thumbnails']['default']['url'] as String,
          'subscriberCount': stats?['subscriberCount'] ?? '0',
          'videoCount': stats?['videoCount'] ?? '0',
        };
      }).toList();
    } else if (response.statusCode == 403) {
      throw Exception('API quota exceeded');
    }

    throw Exception('Search failed');
  } catch (e) {
    throw Exception('Error searching channels: $e');
  }
}

// Helper method to get channel statistics
Future<Map<String, Map<String, String>>> _getChannelStatistics(List<String> channelIds) async {
  try {
    final idParam = channelIds.join(',');
    final uri = Uri.https(_baseUrl, '/youtube/v3/channels', {
      'part': 'statistics',
      'id': idParam,
      'key': _apiKey,
    });

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final items = json['items'] as List;

      final Map<String, Map<String, String>> statsMap = {};
      
      for (final item in items) {
        final channelId = item['id'] as String;
        final statistics = item['statistics'];
        
        statsMap[channelId] = {
          'subscriberCount': statistics['subscriberCount'] as String? ?? '0',
          'videoCount': statistics['videoCount'] as String? ?? '0',
          'viewCount': statistics['viewCount'] as String? ?? '0',
        };
      }

      return statsMap;
    }

    return {};
  } catch (e) {
    print('Error fetching channel statistics: $e');
    return {};
  }
}
}