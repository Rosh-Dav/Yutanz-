import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ytanalyzer/widgets/button_animator.dart';
import '../providers/channel_provider.dart';
import '../screens/insights_screen.dart';
import '../screens/sentiment_screen.dart';
import '../screens/videos_screen.dart';
import '../services/cache_service.dart';
import '../services/search_service.dart';
import '../utils/helpers.dart';
import '../widgets/channel_header.dart';
import '../widgets/stat_card.dart';
import '../widgets/video_card.dart';
import 'video_details_screen.dart';
import '../utils/page_transitions.dart';
import '../widgets/shimmer_loading.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _channelController = TextEditingController();
  int _selectedIndex = 0;

  @override
  void dispose() {
    _channelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChannelProvider(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0B1220),
          elevation: 0,
          actions: [
  Consumer<ChannelProvider>(
    builder: (context, provider, child) {
      return Row(
        children: [
          // Clear cache button (for debugging)
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              CacheService().clearCache();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            tooltip: 'Clear Cache',
          ),
          if (provider.channel != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                provider.clear();
                _channelController.clear();
              },
              tooltip: 'Clear Channel',
            ),
        ],
      );
    },
  ),
],
        ),
        body: _buildBody(),
        bottomNavigationBar: Consumer<ChannelProvider>(
          builder: (context, provider, child) {
            if (provider.channel == null) return const SizedBox.shrink();
    
            return Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                backgroundColor: const Color(0xFF0B1220),
                selectedItemColor: const Color(0xFFFF0000),
                unselectedItemColor: Colors.grey,
                type: BottomNavigationBarType.fixed,
                elevation: 0,
                selectedFontSize: 12,
                unselectedFontSize: 11,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard_outlined),
                    activeIcon: Icon(Icons.dashboard),
                    label: 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.video_library_outlined),
                    activeIcon: Icon(Icons.video_library),
                    label: 'Videos',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.sentiment_satisfied_outlined),
                    activeIcon: Icon(Icons.sentiment_satisfied),
                    label: 'Sentiment',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.insights_outlined),
                    activeIcon: Icon(Icons.insights),
                    label: 'Insights',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<ChannelProvider>(
      builder: (context, provider, child) {
        if (provider.channel == null) {
          return _buildChannelInput(context, provider);
        }

        return switch (_selectedIndex) {
          0 => _buildDashboard(provider),
          1 => VideosScreen(provider: provider),
          2 => SentimentScreen(provider: provider),
          3 => InsightsScreen(provider: provider),
          _ => _buildDashboard(provider),
        };
      },
    );
  }

  Widget _buildChannelInput(BuildContext context, ChannelProvider provider) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF0000).withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  'assets/app_icon.png',
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.youtube_searched_for,
                    size: 80,
                    color: const Color(0xFFFF0000).withOpacity(0.7),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Yutanz',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Analyze any YouTube channel with ease',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _channelController,
              decoration: InputDecoration(
                labelText: 'Search Channel',
                hintText: 'Channel name, @handle, ID, or URL...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _channelController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _channelController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _handleSearch(context, provider, value);
                }
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: // Example: Analyze Channel Button
                  ButtonAnimator(
                disabled: provider.isLoading || _channelController.text.isEmpty,
                onPressed: () {
                  _handleSearch(context, provider, _channelController.text);
                },
                builder: (isPressed) {
                  return ElevatedButton(
                    onPressed: () => _handleSearch(context, provider, _channelController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF0000),
                      foregroundColor: Colors.white,
                      elevation: provider.isLoading ? 0 : 4,
                      shadowColor: const Color(0xFFFF0000).withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: provider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Analyze Channel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ).animate(
                    target: provider.isLoading ? 0 : 1,
                  ).scale();
                },
              ),
            ),
            if (provider.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        provider.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            _buildSearchExamples(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchExamples() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    size: 20, color: Colors.amber[700]),
                const SizedBox(width: 8),
                const Text(
                  'Search Examples',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildExampleItem('Channel Name:', 'MrBeast, MKBHD'),
            _buildExampleItem('Handle:', '@LinusTechTips'),
            _buildExampleItem('Channel ID:', 'UCXuqSBlHAE6Xw-yeJA0Tunw'),
            _buildExampleItem('Channel URL:', 'youtube.com/c/LinusTechTips'),
            _buildExampleItem('Video URL:', 'youtube.com/watch?v=dQw4w9WgXcQ'),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleItem(String label, String example) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              example,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[300],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSearch(
      BuildContext context, ChannelProvider provider, String query) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Searching for channel...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final searchService = SearchService();

      if (!query.contains('youtube.com') &&
          !query.contains('youtu.be') &&
          !query.startsWith('UC') &&
          !query.startsWith('@')) {
        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
          _showChannelSearchResults(context, provider, query);
        }
      } else {
        final channelId = await searchService.getChannelIdFromInput(query);
        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog
          await provider.loadChannel(channelId);
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Show search results dialog
Future<void> _showChannelSearchResults(
  BuildContext context,
  ChannelProvider provider,
  String query,
) async {
  try {
    final searchService = SearchService();
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Searching channels...'),
              ],
            ),
          ),
        ),
      ),
    );

    final results = await searchService.searchChannels(query);

    if (!context.mounted) return;
    
    // Close loading dialog
    Navigator.pop(context);

    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No channels found'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Channel'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              final subscriberCount = int.tryParse(result['subscriberCount'] ?? '0') ?? 0;
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(result['thumbnail']!),
                  backgroundColor: Colors.grey[800],
                ),
                title: Text(
                  result['title']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${_formatSubscriberCount(subscriberCount)} subscribers',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[400],
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  provider.loadChannel(result['channelId']!);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    
    // Close loading dialog if open
    Navigator.of(context, rootNavigator: true).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Search error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// Helper method to format subscriber count
String _formatSubscriberCount(int count) {
  if (count >= 1000000) {
    return '${(count / 1000000).toStringAsFixed(1)}M';
  } else if (count >= 1000) {
    return '${(count / 1000).toStringAsFixed(1)}K';
  }
  return count.toString();
}

  Widget _buildDashboard(ChannelProvider provider) {
    if (provider.isLoading) {
      return Column(
        children: [
          Expanded(child: const ShimmerLoading()),
          if (provider.loadingStatus.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1220),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(0.06)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFF0000),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      provider.loadingStatus,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    final channel = provider.channel!;
    final analytics = provider.analytics;

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      color: const Color(0xFFFF0000),
      backgroundColor: const Color(0xFF0B1220),
      strokeWidth: 3,
      child: ListView(
        physics: const BouncingScrollPhysics(), // Add bouncy scroll
        padding: const EdgeInsets.all(16),
        children: [
          ChannelHeader(
            channel: channel,
            onRefresh: () => provider.refresh(),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total Views',
                  value: Helpers.formatNumber(channel.totalViews),
                  icon: Icons.visibility,
                  color: Colors.blue,
                ).animate().fadeIn(delay: 100.ms, duration: 300.ms).slideX(begin: -0.2, end: 0),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Total Videos',
                  value: provider.videos.isNotEmpty
                      ? provider.videos.length.toString()
                      : channel.videoCount.toString(),
                  icon: Icons.video_library,
                  color: Colors.purple,
                  subtitle: provider.videos.isNotEmpty && provider.videos.length < channel.videoCount
                      ? '${channel.videoCount} lifetime (${channel.videoCount - provider.videos.length} private/unlisted)'
                      : null,
                ).animate().fadeIn(delay: 200.ms, duration: 300.ms).slideX(begin: 0.2, end: 0),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Avg Engagement',
                  value: analytics != null
                      ? '${analytics.averageEngagementRate.toStringAsFixed(2)}%'
                      : '0%',
                  icon: Icons.trending_up,
                  color: Colors.green,
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideX(begin: -0.2, end: 0),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Avg Likes',
                  value: analytics != null && analytics.averageLikesPerVideo.isFinite
                      ? Helpers.formatNumber(analytics.averageLikesPerVideo.toInt())
                      : '0',
                  icon: Icons.thumb_up,
                  color: Colors.orange,
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideX(begin: 0.2, end: 0),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.analytics, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Quick Insights',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (analytics != null) ...[
                    _buildQuickInsightItem(
                      'Channel Started',
                      Helpers.formatDate(channel.publishedAt),
                      Icons.calendar_today,
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildQuickInsightItem(
                      'Avg Views/Video',
                      Helpers.formatNumber(
                          channel.videoCount > 0
                              ? (channel.totalViews / channel.videoCount).round()
                              : 0),
                      Icons.visibility,
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildQuickInsightItem(
                      'Total Engagement',
                      Helpers.formatNumber(analytics.totalEngagement),
                      Icons.favorite,
                      Colors.red,
                    ),
                  ],
                ],
              ),
            ),
          ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 16),
          // Recent Videos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Videos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
                child: const Text('View All'),
              ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
            ],
          ),
          const SizedBox(height: 8),
          ...provider.videos.take(5).toList().asMap().entries.map((entry) {
  final index = entry.key;
  final video = entry.value;
  return VideoCard(
    video: video,
    onTap: () {
      Navigator.push(
        context,
        SlideRightRoute(page: VideoDetailsScreen(video: video)),
      );
    },
  ).animate().fadeIn(
    delay: (100 * index).ms,
    duration: 300.ms,
  ).slideY(begin: 0.2, end: 0);
}),
        ],
      ),
    );
  }

  Widget _buildQuickInsightItem(
      String label, String value, IconData icon, Color color) {
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}