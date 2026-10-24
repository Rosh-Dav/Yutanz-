import 'video_model.dart';
import 'comment_model.dart';

class ChannelAnalytics {
  final double averageLikesPerVideo;
  final double averageCommentsPerVideo;
  final double averageEngagementRate;
  final int totalEngagement;
  final List<String> topKeywords;
  final Map<String, int> uploadFrequency; // date -> count
  final Map<String, dynamic> growthData; // 7/30 day data

  ChannelAnalytics({
    required this.averageLikesPerVideo,
    required this.averageCommentsPerVideo,
    required this.averageEngagementRate,
    required this.totalEngagement,
    required this.topKeywords,
    required this.uploadFrequency,
    required this.growthData,
  });

  factory ChannelAnalytics.fromVideos(List<Video> videos) {
    if (videos.isEmpty) {
      return ChannelAnalytics(
        averageLikesPerVideo: 0,
        averageCommentsPerVideo: 0,
        averageEngagementRate: 0,
        totalEngagement: 0,
        topKeywords: [],
        uploadFrequency: {},
        growthData: {},
      );
    }

    final videosWithLikes = videos.where((v) => !v.likesHidden).toList();
    final totalLikes = videosWithLikes.fold<int>(0, (sum, v) => sum + v.likeCount);
    final totalComments = videos.fold<int>(0, (sum, v) => sum + v.commentCount);

    // Calculate average engagement rate using only videos that have visible likes
    // so hidden-like videos don't falsely drag the channel average down.
    final viewsForLikes = videosWithLikes.fold<int>(0, (sum, v) => sum + v.viewCount);
    final commentsForLikes = videosWithLikes.fold<int>(0, (sum, v) => sum + v.commentCount);

    final double avgEngagementRate;
    if (viewsForLikes > 0) {
      avgEngagementRate = ((totalLikes + commentsForLikes) / viewsForLikes) * 100;
    } else {
      // If all videos have hidden likes, fall back to comment rate across all views
      final totalViews = videos.fold<int>(0, (sum, v) => sum + v.viewCount);
      avgEngagementRate = totalViews > 0 ? (totalComments / totalViews) * 100 : 0;
    }

    return ChannelAnalytics(
      averageLikesPerVideo: videosWithLikes.isNotEmpty
          ? totalLikes / videosWithLikes.length
          : 0,
      averageCommentsPerVideo: videos.isNotEmpty ? totalComments / videos.length : 0,
      averageEngagementRate: avgEngagementRate,
      totalEngagement: totalLikes + totalComments,
      topKeywords: _extractTopKeywords(videos),
      uploadFrequency: _calculateUploadFrequency(videos),
      growthData: {},
    );
  }

  static List<String> _extractTopKeywords(List<Video> videos) {
    final Map<String, int> keywordCount = {};

    for (final video in videos) {
      // Extract from tags
      for (final tag in video.tags) {
        final normalized = tag.toLowerCase().trim();
        keywordCount[normalized] = (keywordCount[normalized] ?? 0) + 1;
      }

      // Extract from title (simple word extraction)
      final titleWords = video.title
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .split(' ')
          .where((w) => w.length > 3);
      
      for (final word in titleWords) {
        keywordCount[word] = (keywordCount[word] ?? 0) + 1;
      }
    }

    final sorted = keywordCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(10).map((e) => e.key).toList();
  }

  static Map<String, int> _calculateUploadFrequency(List<Video> videos) {
    final Map<String, int> frequency = {};

    for (final video in videos) {
      final weekKey = '${video.publishedAt.year}-W${_getWeekNumber(video.publishedAt)}';
      frequency[weekKey] = (frequency[weekKey] ?? 0) + 1;
    }

    return frequency;
  }

  static int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final diff = date.difference(firstDayOfYear).inDays;
    return (diff / 7).ceil();
  }
}

class SentimentAnalysis {
  final int positive;
  final int neutral;
  final int negative;
  final double positivePercentage;
  final double neutralPercentage;
  final double negativePercentage;
  final List<Comment> topPositive;
  final List<Comment> topNegative;

  SentimentAnalysis({
    required this.positive,
    required this.neutral,
    required this.negative,
    required this.positivePercentage,
    required this.neutralPercentage,
    required this.negativePercentage,
    required this.topPositive,
    required this.topNegative,
  });

  int get total => positive + neutral + negative;

  Map<String, dynamic> toJson() {
    return {
      'positive': positive,
      'neutral': neutral,
      'negative': negative,
      'positivePercentage': positivePercentage,
      'neutralPercentage': neutralPercentage,
      'negativePercentage': negativePercentage,
      'topPositive': topPositive.map((c) => c.toJson()).toList(),
      'topNegative': topNegative.map((c) => c.toJson()).toList(),
    };
  }

  factory SentimentAnalysis.fromJson(Map<String, dynamic> json) {
    return SentimentAnalysis(
      positive: json['positive'] as int? ?? 0,
      neutral: json['neutral'] as int? ?? 0,
      negative: json['negative'] as int? ?? 0,
      positivePercentage: (json['positivePercentage'] as num?)?.toDouble() ?? 0.0,
      neutralPercentage: (json['neutralPercentage'] as num?)?.toDouble() ?? 0.0,
      negativePercentage: (json['negativePercentage'] as num?)?.toDouble() ?? 0.0,
      topPositive: (json['topPositive'] as List<dynamic>?)
              ?.map((c) => Comment.fromJson(Map<String, dynamic>.from(c as Map)))
              .toList() ??
          [],
      topNegative: (json['topNegative'] as List<dynamic>?)
              ?.map((c) => Comment.fromJson(Map<String, dynamic>.from(c as Map)))
              .toList() ??
          [],
    );
  }
}