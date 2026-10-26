import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/video_model.dart';
import '../providers/channel_provider.dart';
import '../widgets/stat_card.dart';
import 'package:url_launcher/url_launcher.dart';
import 'sentiment_screen.dart';

class VideoDetailsScreen extends StatelessWidget {
  final Video video;

  const VideoDetailsScreen({Key? key, required this.video}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: const Text('Video Details'),
      actions: [
        IconButton(
          icon: const Icon(Icons.open_in_new),
          onPressed: () async {
            final youtubeUrl = 'https://www.youtube.com/watch?v=${video.id}';
            
            try {
              final uri = Uri.parse(youtubeUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication, // Opens in YouTube app or browser
                );
              } else {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Could not open YouTube'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          tooltip: 'Open in YouTube',
        ),
      ],
    ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Thumbnail
          Hero(
            tag: 'video_${video.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: video.thumbnail,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: Colors.grey[800],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: Colors.grey[800],
                  child: const Icon(Icons.error),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Title
          Text(
            video.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // Performance Stats
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics, size: 20, color: Colors.blue[300]),
                      const SizedBox(width: 8),
                      const Text(
                        'Performance Metrics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildMetricRow(
                    'Views',
                    formatNumber(video.viewCount),
                    Icons.visibility,
                    Colors.blue,
                  ),
                  const Divider(height: 24),
                  _buildMetricRow(
                    'Likes',
                    video.likesHidden ? 'Hidden by creator' : formatNumber(video.likeCount),
                    video.likesHidden ? Icons.thumb_up_off_alt : Icons.thumb_up,
                    video.likesHidden ? Colors.grey : Colors.green,
                  ),
                  const Divider(height: 24),
                  _buildMetricRow(
                    'Comments',
                    formatNumber(video.commentCount),
                    Icons.comment,
                    Colors.orange,
                  ),
                  const Divider(height: 24),
                  _buildMetricRow(
                    'Engagement Rate',
                    video.likesHidden
                        ? 'N/A (Likes Hidden)'
                        : '${video.engagementRate!.toStringAsFixed(2)}%',
                    Icons.trending_up,
                    _getEngagementColor(video.engagementRate),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 16),

          // Stats Cards Grid
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Views',
                  value: formatNumber(video.viewCount),
                  icon: Icons.visibility,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Likes',
                  value: video.likesHidden ? 'Hidden' : formatNumber(video.likeCount),
                  icon: video.likesHidden ? Icons.thumb_up_off_alt : Icons.thumb_up,
                  color: video.likesHidden ? Colors.grey : Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Comments',
                  value: formatNumber(video.commentCount),
                  icon: Icons.comment,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Engagement',
                  value: video.likesHidden ? 'N/A' : '${video.engagementRate!.toStringAsFixed(2)}%',
                  icon: Icons.trending_up,
                  color: _getEngagementColor(video.engagementRate),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Publishing Info
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 20, color: Colors.purple[300]),
                      const SizedBox(width: 8),
                      const Text(
                        'Publishing Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Published', _formatDate(video.publishedAt)),
                  const SizedBox(height: 12),
                  _buildInfoRow('Time Ago', _formatRelativeTime(video.publishedAt)),
                  if (video.duration.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow('Duration', _formatDuration(video.duration)),
                  ],
                ],
              ),
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 16),

          // Description
          if (video.description.isNotEmpty) ...[
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description, size: 20, color: Colors.amber[300]),
                        const SizedBox(width: 8),
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      video.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[300],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 16),
          ],

          // Tags
          if (video.tags.isNotEmpty) ...[
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.label, size: 20, color: Colors.pink[300]),
                        const SizedBox(width: 8),
                        const Text(
                          'Tags',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: video.tags.take(20).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey[700]!,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),
          ],

          const SizedBox(height: 16),

          // Performance Rating
          _buildPerformanceRating(video),

          const SizedBox(height: 16),

          // Analyze Sentiment Button
          _buildAnalyzeSentimentButton(context),

          const SizedBox(height: 12),

// Open in YouTube Button
SizedBox(
  width: double.infinity,
  height: 50,
  child: ElevatedButton.icon(
    onPressed: () async {
      final youtubeUrl = 'https://www.youtube.com/watch?v=${video.id}';
      
      try {
        final uri = Uri.parse(youtubeUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        } else {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open YouTube'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    },
    icon: const Icon(Icons.play_arrow, size: 28),
    label: const Text(
      'Watch on YouTube',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFFF0000),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
),

const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAnalyzeSentimentButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            debugPrint('🎯 Analyze Comment Sentiment tapped for video: ${video.id}');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(
                    title: const Text('Sentiment Analysis'),
                    backgroundColor: const Color(0xFF0B1220),
                  ),
                  backgroundColor: const Color(0xFF0B1220),
                  body: SentimentScreen(
                    preselectedVideo: video,
                  ),
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.insights_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Analyze Comment Sentiment',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Fine-tuned RoBERTa AI analysis',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceRating(Video video) {
    if (video.likesHidden) {
      return Card(
        color: Colors.blueGrey.withOpacity(0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.blueGrey.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline, color: Colors.blueGrey, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Performance Rating',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Rating Unavailable',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Likes are hidden on this video by the creator, so full engagement rate cannot be calculated accurately (Comment rate: ${video.commentRate.toStringAsFixed(2)}%).',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final rate = video.engagementRate ?? 0;
    String rating;
    Color color;
    IconData icon;

    if (rate > 10) {
      rating = 'Exceptional';
      color = Colors.purple;
      icon = Icons.stars;
    } else if (rate > 5) {
      rating = 'Excellent';
      color = Colors.green;
      icon = Icons.star;
    } else if (rate > 2) {
      rating = 'Good';
      color = Colors.blue;
      icon = Icons.thumb_up;
    } else if (rate > 1) {
      rating = 'Average';
      color = Colors.orange;
      icon = Icons.trending_flat;
    } else {
      rating = 'Below Average';
      color = Colors.red;
      icon = Icons.trending_down;
    }

    return Card(
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performance Rating',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rating,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEngagementColor(double? rate) {
    if (rate == null) return Colors.grey;
    if (rate > 10) return Colors.purple;
    if (rate > 5) return Colors.green;
    if (rate > 2) return Colors.blue;
    if (rate > 1) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMMM dd, yyyy').format(date);
  }

  String _formatRelativeTime(DateTime date) {
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
    }
    return 'Today';
  }

  String _formatDuration(String isoDuration) {
    if (isoDuration.isEmpty) return 'Unknown';

    final regex = RegExp(r'PT(\d+H)?(\d+M)?(\d+S)?');
    final match = regex.firstMatch(isoDuration);

    if (match == null) return 'Unknown';

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
}