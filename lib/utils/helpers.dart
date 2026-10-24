import 'package:intl/intl.dart';

class Helpers {
  // Format large numbers with K, M suffix
  static String formatNumber(int number) {
    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(1)}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return NumberFormat('#,##0').format(number);
  }

  // Format date as relative time
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 365) {
      final years = (diff.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (diff.inDays > 30) {
      final months = (diff.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // Format date as standard string
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  // Format date with time
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }

  // Parse YouTube duration (ISO 8601)
  static String formatDuration(String isoDuration) {
    if (isoDuration.isEmpty) return '0:00';

    final regex = RegExp(r'PT(\d+H)?(\d+M)?(\d+S)?');
    final match = regex.firstMatch(isoDuration);

    if (match == null) return '0:00';

    final hours = match.group(1);
    final minutes = match.group(2);
    final seconds = match.group(3);

    final h = hours != null ? int.parse(hours.replaceAll('H', '')) : 0;
    final m = minutes != null ? int.parse(minutes.replaceAll('M', '')) : 0;
    final s = seconds != null ? int.parse(seconds.replaceAll('S', '')) : 0;

    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    } else {
      return '$m:${s.toString().padLeft(2, '0')}';
    }
  }

  // Get engagement color based on rate
  static String getEngagementLevel(double? rate) {
    if (rate == null) return 'Unavailable (Likes hidden)';
    if (rate > 10) return 'Exceptional';
    if (rate > 5) return 'Very Good';
    if (rate > 2) return 'Good';
    if (rate > 1) return 'Average';
    return 'Below Average';
  }

  // Validate YouTube channel ID format
  static bool isValidChannelId(String channelId) {
    // YouTube channel IDs are typically 24 characters starting with UC
    if (channelId.startsWith('UC') && channelId.length == 24) {
      return true;
    }
    // Also check for custom URLs (starting with @)
    if (channelId.startsWith('@')) {
      return true;
    }
    return false;
  }

  // Extract channel ID from URL
  static String? extractChannelId(String input) {
    // If it's already a valid ID, return it
    if (isValidChannelId(input)) {
      return input;
    }

    // Try to extract from URL
    final patterns = [
      RegExp(r'youtube\.com/channel/([^/?]+)'),
      RegExp(r'youtube\.com/c/([^/?]+)'),
      RegExp(r'youtube\.com/user/([^/?]+)'),
      RegExp(r'youtube\.com/@([^/?]+)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(input);
      if (match != null) {
        return match.group(1);
      }
    }

    return null;
  }

  // Calculate percentage
  static double calculatePercentage(int part, int total) {
    if (total == 0) return 0;
    return (part / total) * 100;
  }

  // Get color for sentiment
  static String getSentimentEmoji(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return '😊';
      case 'negative':
        return '😞';
      case 'neutral':
      default:
        return '😐';
    }
  }
}