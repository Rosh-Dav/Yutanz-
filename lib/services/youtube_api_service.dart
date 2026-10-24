import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/channel_model.dart';
import '../models/video_model.dart';
import '../models/comment_model.dart';

class YouTubeApiService {
  final String _apiKey = dotenv.env['YOUTUBE_API_KEY'] ?? '';
  static const String _baseUrl = 'www.googleapis.com';

  // Fetch channel details
  Future<Channel> fetchChannel(String channelId) async {
    try {
      final uri = Uri.https(_baseUrl, '/youtube/v3/channels', {
        'part': 'snippet,statistics,contentDetails',
        'id': channelId,
        'key': _apiKey,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final items = json['items'] as List;
        
        if (items.isEmpty) {
          throw Exception('Channel not found');
        }

        return Channel.fromJson(items[0]);
      } else if (response.statusCode == 403) {
        throw Exception('API quota exceeded. Please try again later.');
      } else if (response.statusCode == 404) {
        throw Exception('Channel not found');
      } else {
        throw Exception('Failed to load channel: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching channel: $e');
    }
  }

  // Fetch ALL video IDs from uploads playlist (paginates through all pages)
  Future<List<String>> fetchVideoIds(String playlistId, {int maxResults = 50}) async {
    try {
      final List<String> allVideoIds = [];
      String? nextPageToken;

      do {
        final params = <String, String>{
          'part': 'contentDetails',
          'playlistId': playlistId,
          'maxResults': '50', // API max per page is always 50
          'key': _apiKey,
        };
        if (nextPageToken != null) {
          params['pageToken'] = nextPageToken;
        }

        final uri = Uri.https(_baseUrl, '/youtube/v3/playlistItems', params);
        final response = await http.get(uri);

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final items = json['items'] as List;

          allVideoIds.addAll(
            items.map((item) => item['contentDetails']['videoId'] as String),
          );

          // nextPageToken is null when we're on the last page
          nextPageToken = json['nextPageToken'] as String?;
        } else if (response.statusCode == 403) {
          throw Exception('API quota exceeded');
        } else {
          throw Exception('Failed to fetch videos: ${response.statusCode}');
        }
      } while (nextPageToken != null);

      return allVideoIds;
    } catch (e) {
      throw Exception('Error fetching video IDs: $e');
    }
  }

  // Fetch video statistics (batch)
  Future<List<Video>> fetchVideosStats(List<String> videoIds) async {
    if (videoIds.isEmpty) return [];

    try {
      // YouTube API allows max 50 IDs per request
      final batches = <List<String>>[];
      for (var i = 0; i < videoIds.length; i += 50) {
        batches.add(videoIds.sublist(
          i,
          i + 50 > videoIds.length ? videoIds.length : i + 50,
        ));
      }

      final List<Video> allVideos = [];

      for (final batch in batches) {
        final idParam = batch.join(',');
        final uri = Uri.https(_baseUrl, '/youtube/v3/videos', {
          'part': 'snippet,statistics,contentDetails',
          'id': idParam,
          'key': _apiKey,
        });

        final response = await http.get(uri);

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final items = json['items'] as List;
          
          allVideos.addAll(
            items.map((item) => Video.fromJson(item)).toList(),
          );
        } else if (response.statusCode == 403) {
          throw Exception('API quota exceeded');
        } else {
          throw Exception('Failed to fetch video stats: ${response.statusCode}');
        }
      }

      return allVideos;
    } catch (e) {
      throw Exception('Error fetching video stats: $e');
    }
  }

  // Fetch comments for a video
  Future<List<Comment>> fetchComments(String videoId, {int maxResults = 50}) async {
    try {
      final uri = Uri.https(_baseUrl, '/youtube/v3/commentThreads', {
        'part': 'snippet,replies',
        'videoId': videoId,
        'maxResults': maxResults.toString(),
        'textFormat': 'plainText',
        'order': 'relevance',
        'key': _apiKey,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final items = json['items'] as List;
        
        final List<Comment> allComments = [];
        
        for (final item in items) {
          // Add the top-level comment
          allComments.add(Comment.fromJson(item));
          if (allComments.length >= maxResults) break;
          
          // Add replies if present
          final replies = item['replies'] as Map<String, dynamic>?;
          if (replies != null) {
            final replyList = replies['comments'] as List? ?? [];
            for (final reply in replyList) {
              allComments.add(Comment.fromReplyJson(reply));
              if (allComments.length >= maxResults) break;
            }
          }
          if (allComments.length >= maxResults) break;
        }
        
        return allComments;
      } else if (response.statusCode == 403) {
        // Comments might be disabled or quota exceeded
        if (response.body.contains('commentsDisabled')) {
          throw Exception('Comments are disabled for this video');
        }
        throw Exception('API quota exceeded');
      } else {
        throw Exception('Failed to fetch comments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching comments: $e');
    }
  }

  // Search channels by query (limited use)
  Future<List<Map<String, String>>> searchChannels(String query, {int maxResults = 5}) async {
    try {
      final uri = Uri.https(_baseUrl, '/youtube/v3/search', {
        'part': 'snippet',
        'q': query,
        'type': 'channel',
        'maxResults': maxResults.toString(),
        'key': _apiKey,
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final items = json['items'] as List;
        
        return items.map((item) {
          final snippet = item['snippet'];
          return {
            'channelId': item['id']['channelId'] as String,
            'title': snippet['title'] as String,
            'description': snippet['description'] as String,
            'thumbnail': snippet['thumbnails']['default']['url'] as String,
          };
        }).toList();
      } else if (response.statusCode == 403) {
        throw Exception('API quota exceeded');
      } else {
        throw Exception('Failed to search: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching channels: $e');
    }
  }
}