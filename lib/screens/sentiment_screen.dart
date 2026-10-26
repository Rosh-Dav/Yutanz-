import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/channel_provider.dart';
import '../providers/video_provider.dart';
import '../models/video_model.dart';
import '../models/comment_model.dart';
import '../models/analytics_model.dart';

class SentimentScreen extends StatefulWidget {
  final ChannelProvider? provider;
  // When launched from VideoDetailsScreen, this video is pre-selected.
  final Video? preselectedVideo;

  const SentimentScreen({
    Key? key,
    this.provider,
    this.preselectedVideo,
  }) : super(key: key);

  @override
  State<SentimentScreen> createState() => _SentimentScreenState();
}

class _SentimentScreenState extends State<SentimentScreen> {
  late VideoProvider _videoProvider;

  @override
  void initState() {
    super.initState();
    _videoProvider = VideoProvider();
    // If a video was passed in, kick off analysis immediately.
    if (widget.preselectedVideo != null) {
      _videoProvider.setCurrentVideo(widget.preselectedVideo!);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _videoProvider.loadCommentsAndAnalyze(widget.preselectedVideo!.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _videoProvider,
      child: Consumer<VideoProvider>(
        builder: (context, videoProvider, child) {
          // Launched from VideoDetailsScreen with a pre-selected video
          if (widget.preselectedVideo != null) {
            return _buildResultView(videoProvider);
          }
          // Launched from bottom nav tab — show guide
          return _buildNoVideoGuide();
        },
      ),
    );
  }

  // ── Guide shown on the nav tab (no video pre-selected) ──────────────────
  Widget _buildNoVideoGuide() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.insights_rounded, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 28),
            const Text(
              'Comment Sentiment Analysis',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Discover how your audience feels about any video using AI-powered RoBERTa sentiment detection (fine-tuned on YouTube comments).',
              style: TextStyle(fontSize: 14, color: Colors.grey[400], height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            _buildStep(
              icon: Icons.video_library_rounded,
              label: 'Browse your videos',
              sublabel: 'Go to the Videos tab',
            ),
            _buildStep(
              icon: Icons.touch_app_rounded,
              label: 'Open any video',
              sublabel: 'Tap a video to see its details',
            ),
            _buildStep(
              icon: Icons.bar_chart_rounded,
              label: 'Tap "Analyze Sentiment"',
              sublabel: 'Instant AI-powered results',
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required IconData icon,
    required String label,
    required String sublabel,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: Colors.white),
              ),
              if (!isLast)
                Container(width: 2, height: 32, color: Colors.grey[800]),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(sublabel,
                      style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Result view (pre-selected video) ───────────────────────────────────
  Widget _buildResultView(VideoProvider videoProvider) {
    if (videoProvider.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 20),
            Text(
              videoProvider.comments.isEmpty
                  ? 'Fetching comments…'
                  : 'Analyzing ${videoProvider.comments.length} comments…',
              style: TextStyle(color: Colors.grey[400], fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              'Powered by fine-tuned RoBERTa AI (initial start may take ~30s)',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      );
    }
    if (videoProvider.error != null) return _buildErrorState(videoProvider.error!);
    if (videoProvider.sentimentAnalysis == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return _buildSentimentAnalysis(videoProvider);
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(error, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                if (widget.preselectedVideo != null) {
                  _videoProvider.loadCommentsAndAnalyze(
                      widget.preselectedVideo!.id, forceRefresh: true);
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentimentAnalysis(VideoProvider provider) {
    final sentiment = provider.sentimentAnalysis!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Video title sub-header
        if (widget.preselectedVideo != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              widget.preselectedVideo!.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: Colors.grey[400], height: 1.4),
            ),
          ),

        // Summary Card with gradient
        _buildSummaryCard(sentiment, provider),
        const SizedBox(height: 20),

        // Pie Chart
        _buildPieChart(sentiment),
        const SizedBox(height: 20),

        // Stats Cards
        Row(
          children: [
            Expanded(
              child: _buildSentimentCard(
                  'Positive', sentiment.positive, sentiment.positivePercentage, Colors.green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSentimentCard(
                  'Neutral', sentiment.neutral, sentiment.neutralPercentage, Colors.blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSentimentCard(
                  'Negative', sentiment.negative, sentiment.negativePercentage, Colors.red),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Bar Chart
        _buildBarChart(sentiment),
        const SizedBox(height: 20),

        if (sentiment.topPositive.isNotEmpty)
          _buildCommentSection('Top Positive Comments', sentiment.topPositive, Colors.green),
        const SizedBox(height: 20),

        if (sentiment.topNegative.isNotEmpty)
          _buildCommentSection('Top Negative Comments', sentiment.topNegative, Colors.red),
        const SizedBox(height: 20),

        _buildWordFrequency(provider.wordFrequency),
        const SizedBox(height: 16),

        // Source badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6C63FF).withOpacity(0.15),
                const Color(0xFF3ECFCF).withOpacity(0.10),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.smart_toy_rounded, color: Color(0xFF6C63FF), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.sentimentSource,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6C63FF),
                      ),
                    ),
                    Text(
                      'Based on ${provider.comments.length} comments',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSummaryCard(SentimentAnalysis sentiment, VideoProvider provider) {
    final color = _getSentimentColor(sentiment);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.18), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(_getSentimentIcon(sentiment), size: 52, color: color),
          const SizedBox(height: 12),
          Text(
            provider.sentimentService.getSentimentSummary(sentiment),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Based on ${sentiment.total} comments',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  IconData _getSentimentIcon(SentimentAnalysis sentiment) {
    if (sentiment.positivePercentage > sentiment.negativePercentage &&
        sentiment.positivePercentage > sentiment.neutralPercentage) {
      return Icons.sentiment_very_satisfied;
    } else if (sentiment.negativePercentage > sentiment.positivePercentage &&
        sentiment.negativePercentage > sentiment.neutralPercentage) {
      return Icons.sentiment_very_dissatisfied;
    }
    return Icons.sentiment_neutral;
  }

  Color _getSentimentColor(SentimentAnalysis sentiment) {
    if (sentiment.positivePercentage > sentiment.negativePercentage &&
        sentiment.positivePercentage > sentiment.neutralPercentage) {
      return Colors.green;
    } else if (sentiment.negativePercentage > sentiment.positivePercentage &&
        sentiment.negativePercentage > sentiment.neutralPercentage) {
      return Colors.red;
    }
    return Colors.blue;
  }

  Widget _buildPieChart(SentimentAnalysis sentiment) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sentiment Distribution',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 240,
              child: PieChart(
                PieChartData(
                  sections: [
                    if (sentiment.positive > 0)
                      PieChartSectionData(
                        value: sentiment.positive.toDouble(),
                        title: '${sentiment.positivePercentage.toStringAsFixed(1)}%',
                        color: Colors.green,
                        radius: 60,
                        titlePositionPercentageOffset: 1.6,
                        titleStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    if (sentiment.neutral > 0)
                      PieChartSectionData(
                        value: sentiment.neutral.toDouble(),
                        title: '${sentiment.neutralPercentage.toStringAsFixed(1)}%',
                        color: Colors.blue,
                        radius: 60,
                        titlePositionPercentageOffset: 1.6,
                        titleStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    if (sentiment.negative > 0)
                      PieChartSectionData(
                        value: sentiment.negative.toDouble(),
                        title: '${sentiment.negativePercentage.toStringAsFixed(1)}%',
                        color: Colors.red,
                        radius: 60,
                        titlePositionPercentageOffset: 1.6,
                        titleStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                  ],
                  sectionsSpace: 3,
                  centerSpaceRadius: 45,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(Colors.green, 'Positive'),
                const SizedBox(width: 16),
                _legendDot(Colors.blue, 'Neutral'),
                const SizedBox(width: 16),
                _legendDot(Colors.red, 'Negative'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(children: [
      Container(width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
    ]);
  }

  Widget _buildBarChart(SentimentAnalysis sentiment) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comment Count',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceEvenly,
                  maxY: sentiment.total.toDouble() * 1.2,
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: sentiment.positive.toDouble(),
                          color: Colors.green,
                          width: 40,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: sentiment.neutral.toDouble(),
                          color: Colors.blue,
                          width: 40,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: sentiment.negative.toDouble(),
                          color: Colors.red,
                          width: 40,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
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
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return const Text('Positive');
                            case 1:
                              return const Text('Neutral');
                            case 2:
                              return const Text('Negative');
                            default:
                              return const Text('');
                          }
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentimentCard(String label, int count, double percentage, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection(String title, List<Comment> comments, Color color) {
    if (comments.isEmpty) return const SizedBox.shrink();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...comments.map((comment) => _buildCommentItem(comment, color)),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(Comment comment, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                comment.authorName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.thumb_up, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    comment.likeCount.toString(),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordFrequency(Map<String, int> wordFrequency) {
    if (wordFrequency.isEmpty) return const SizedBox.shrink();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Most Frequent Words',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: wordFrequency.entries.take(15).map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          entry.value.toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoProvider.dispose();
    super.dispose();
  }
}