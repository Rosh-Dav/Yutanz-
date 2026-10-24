import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ytanalyzer/screens/video_details_screen.dart';
import '../providers/channel_provider.dart';
import '../widgets/stat_card.dart';
import '../utils/page_transitions.dart';

class InsightsScreen extends StatefulWidget {
  final ChannelProvider provider;

  const InsightsScreen({Key? key, required this.provider}) : super(key: key);

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  String _selectedSortOption = 'engagement';

  @override
  Widget build(BuildContext context) {
    final analytics = widget.provider.analytics;

    if (analytics == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => widget.provider.refresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Engagement Overview
          const Text(
            'Engagement Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Avg Likes',
                  value: formatNumber(analytics.averageLikesPerVideo.toInt()),
                  icon: Icons.thumb_up,
                  color: Colors.orange,
                  subtitle: 'per video',
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideX(begin: -0.2, end: 0),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Avg Comments',
                  value: formatNumber(analytics.averageCommentsPerVideo.toInt()),
                  icon: Icons.comment,
                  color: Colors.purple,
                  subtitle: 'per video',
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideX(begin: -0.2, end: 0),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StatCard(
            title: 'Total Engagement',
            value: formatNumber(analytics.totalEngagement),
            icon: Icons.trending_up,
            color: Colors.green,
            subtitle: 'likes + comments across all videos',
          ),

          const SizedBox(height: 24),

          // Top Keywords
          _buildTopKeywords(analytics.topKeywords),

          const SizedBox(height: 24),

          // Upload Frequency
          _buildUploadFrequency(analytics.uploadFrequency),

          const SizedBox(height: 24),

          // Video Performance Distribution
          _buildPerformanceDistribution(),

          const SizedBox(height: 24),

          // Top Performing Videos
          _buildTopPerformingVideos(),
        ],
      ),
    );
  }

  Widget _buildTopKeywords(List<String> keywords) {
    if (keywords.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.label, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Top Keywords & Tags',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Most frequently used keywords across your videos',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: keywords.asMap().entries.map((entry) {
                final index = entry.key;
                final keyword = entry.value;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF0000).withOpacity(0.3),
                        const Color(0xFFFF0000).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFF0000).withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF0000),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        keyword,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Use these keywords in future content for better discoverability',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue[200],
                      ),
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

  Widget _buildUploadFrequency(Map<String, int> uploadFrequency) {
    if (uploadFrequency.isEmpty) {
      return const SizedBox.shrink();
    }

    // Convert week-based data to month-based for clarity
    final videos = widget.provider.videos;
    final Map<String, int> monthlyUploads = {};
    final monthNames = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    for (final video in videos) {
      final key = '${video.publishedAt.year}-${video.publishedAt.month.toString().padLeft(2, '0')}';
      monthlyUploads[key] = (monthlyUploads[key] ?? 0) + 1;
    }

    final sortedMonths = monthlyUploads.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Take last 12 months
    final recentMonths = sortedMonths.length > 12
        ? sortedMonths.sublist(sortedMonths.length - 12)
        : sortedMonths;

    final maxY = recentMonths.isEmpty
        ? 5.0
        : (recentMonths.map((e) => e.value).reduce((a, b) => a > b ? a : b) + 2).toDouble();

    final totalVideos = recentMonths.fold<int>(0, (sum, e) => sum + e.value);
    final avgPerMonth = recentMonths.isNotEmpty ? totalVideos / recentMonths.length : 0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.upload, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Upload Frequency',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Videos uploaded per month (last ${recentMonths.length} months)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 16),
            // Summary stats row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$totalVideos',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total Uploads',
                          style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${recentMonths.length}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Months Span',
                          style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          avgPerMonth.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Avg/Month',
                          style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceEvenly,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final entry = recentMonths[group.x.toInt()];
                        final parts = entry.key.split('-');
                        final monthIdx = int.parse(parts[1]);
                        final year = parts[0];
                        return BarTooltipItem(
                          '${monthNames[monthIdx]} $year\n${rod.toY.toInt()} videos',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  barGroups: recentMonths.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value.toDouble(),
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFF0000),
                              const Color(0xFFFF0000).withOpacity(0.6),
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: recentMonths.length > 8 ? 14 : 22,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value == value.roundToDouble()) {
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < recentMonths.length) {
                            final monthKey = recentMonths[value.toInt()].key;
                            final parts = monthKey.split('-');
                            final monthIdx = int.parse(parts[1]);
                            final year = parts[0].substring(2); // "26" from "2026"
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    monthNames[monthIdx],
                                    style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                                  ),
                                  Text(
                                    "'$year",
                                    style: TextStyle(fontSize: 8, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[800],
                        strokeWidth: 0.5,
                        dashArray: [4, 4],
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildPerformanceDistribution() {
    final videos = widget.provider.videos;
    
    // Categorize videos by views
    int viral = 0; // >100K views
    int highPerforming = 0; // 10K-100K views
    int moderate = 0; // 1K-10K views
    int low = 0; // <1K views

    for (final video in videos) {
      if (video.viewCount > 100000) {
        viral++;
      } else if (video.viewCount > 10000) {
        highPerforming++;
      } else if (video.viewCount > 1000) {
        moderate++;
      } else {
        low++;
      }
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Video Performance Distribution',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Videos categorized by view count',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 20),
            _buildPerformanceBar('Viral (>100K)', viral, videos.length, Colors.purple),
            const SizedBox(height: 12),
            _buildPerformanceBar('High (10K-100K)', highPerforming, videos.length, Colors.green),
            const SizedBox(height: 12),
            _buildPerformanceBar('Moderate (1K-10K)', moderate, videos.length, Colors.blue),
            const SizedBox(height: 12),
            _buildPerformanceBar('Low (<1K)', low, videos.length, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total) * 100 : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$count (${percentage.toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[800],
            color: color,
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildTopPerformingVideos() {
    final videos = List.from(widget.provider.videos);

    // Sort based on selected option
    switch (_selectedSortOption) {
      case 'views':
        videos.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
      case 'likes':
        videos.sort((a, b) {
          if (a.likesHidden && b.likesHidden) return 0;
          if (a.likesHidden) return 1;
          if (b.likesHidden) return -1;
          return b.likeCount.compareTo(a.likeCount);
        });
        break;
      case 'engagement':
      default:
        videos.sort((a, b) {
          if (a.likesHidden && b.likesHidden) return 0;
          if (a.likesHidden) return 1;
          if (b.likesHidden) return -1;
          final rateA = a.engagementRate ?? 0;
          final rateB = b.engagementRate ?? 0;
          return rateB.compareTo(rateA);
        });
        break;
    }

    final topVideos = videos.take(5).toList();

    if (topVideos.isEmpty) {
      return const SizedBox.shrink();
    }

    String subtitleText;
    switch (_selectedSortOption) {
      case 'views':
        subtitleText = 'Ranked by total view count';
        break;
      case 'likes':
        subtitleText = 'Ranked by total likes received';
        break;
      case 'engagement':
      default:
        subtitleText = 'Ranked by engagement rate (likes + comments / views)';
        break;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, size: 20, color: Colors.amber),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Top Performing Videos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Sort toggle buttons
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: [
                  _buildSortChip('Engagement', 'engagement', Icons.trending_up),
                  _buildSortChip('Views', 'views', Icons.visibility),
                  _buildSortChip('Likes', 'likes', Icons.thumb_up),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitleText,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 16),
            ...topVideos.asMap().entries.map((entry) {
              final index = entry.key;
              final video = entry.value;

              // Build the highlighted metric based on sort
              String metricValue;
              IconData metricIcon;
              Color metricColor;
              switch (_selectedSortOption) {
                case 'views':
                  metricValue = formatNumber(video.viewCount);
                  metricIcon = Icons.visibility;
                  metricColor = Colors.blue;
                  break;
                case 'likes':
                  metricValue = video.likesHidden ? 'Hidden' : formatNumber(video.likeCount);
                  metricIcon = Icons.thumb_up;
                  metricColor = video.likesHidden ? Colors.grey : Colors.pink;
                  break;
                case 'engagement':
                default:
                  metricValue = video.likesHidden
                      ? 'N/A'
                      : '${video.engagementRate!.toStringAsFixed(2)}%';
                  metricIcon = Icons.trending_up;
                  metricColor = video.likesHidden ? Colors.grey : Colors.green;
                  break;
              }

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    SlideRightRoute(page: VideoDetailsScreen(video: video)),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[850],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      // Rank badge
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber,
                              Colors.amber.shade700,
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Video info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.visibility, size: 12, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text(
                                  formatNumber(video.viewCount),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(metricIcon, size: 12, color: metricColor),
                                const SizedBox(width: 4),
                                Text(
                                  metricValue,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: metricColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Arrow icon
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, String value, IconData icon) {
    final isSelected = _selectedSortOption == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedSortOption = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF0000).withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFFFF0000).withOpacity(0.5) : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? const Color(0xFFFF0000) : Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
