import 'package:flutter/material.dart';
import '../providers/channel_provider.dart';
import '../widgets/video_card.dart';
import '../models/video_model.dart';
import 'video_details_screen.dart';
import '../utils/page_transitions.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/stat_card.dart';

import '../utils/helpers.dart';

class VideosScreen extends StatefulWidget {
  final ChannelProvider provider;

  const VideosScreen({Key? key, required this.provider}) : super(key: key);

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen>
    with SingleTickerProviderStateMixin {
  String _sortBy = 'date';
  int _categoryIndex = 0; // 0: All, 1: Videos (Long-form), 2: Shorts

  static const _kCardBg = Color(0xFF0B1220);
  static const _kRedAccent = Color(0xFFFF0000);
  static const _kPurple = Color(0xFF6C63FF);

  @override
  Widget build(BuildContext context) {
    final allVideos = widget.provider.videos;
    final channel = widget.provider.channel;

    final longVideos = allVideos.where((v) => !v.isShort).toList();
    final shortsVideos = allVideos.where((v) => v.isShort).toList();

    final filteredVideos = switch (_categoryIndex) {
      1 => longVideos,
      2 => shortsVideos,
      _ => allVideos,
    };

    // Apply current sort to the already-filtered list
    final displayVideos = List<Video>.from(filteredVideos);
    _sortList(displayVideos, _sortBy);

    final showOldestDebut = _sortBy == 'oldest' && displayVideos.isNotEmpty;
    final hasDiscrepancy = channel != null && channel.videoCount > allVideos.length;

    return Column(
      children: [
        // ── Category Switcher ─────────────────────────────────────────────
        _buildCategoryTabs(allVideos.length, longVideos.length, shortsVideos.length),

        // ── Notice for private / deleted YouTube videos discrepancy ───────
        if (hasDiscrepancy)
          _buildDiscrepancyNotice(allVideos.length, channel.videoCount),

        // ── Sort Row ──────────────────────────────────────────────────────
        _buildSortRow(),

        // ── Oldest Video Spotlight (when Oldest is selected) ──────────────
        if (showOldestDebut)
          _buildOldestHighlightBanner(displayVideos.first),

        // ── Content ───────────────────────────────────────────────────────
        Expanded(
          child: displayVideos.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => widget.provider.refresh(),
                  color: _kRedAccent,
                  backgroundColor: _kCardBg,
                  child: _categoryIndex == 2
                      ? _buildShortsGrid(displayVideos)
                      : _buildVideoList(displayVideos),
                ),
        ),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _sortList(List<Video> list, String sortBy) {
    switch (sortBy) {
      case 'views':
        list.sort((a, b) => b.viewCount.compareTo(a.viewCount));
      case 'likes':
        list.sort((a, b) {
          if (a.likesHidden && b.likesHidden) return 0;
          if (a.likesHidden) return 1;
          if (b.likesHidden) return -1;
          return b.likeCount.compareTo(a.likeCount);
        });
      case 'engagement':
        list.sort((a, b) {
          if (a.likesHidden && b.likesHidden) return 0;
          if (a.likesHidden) return 1;
          if (b.likesHidden) return -1;
          final rateA = a.engagementRate ?? 0;
          final rateB = b.engagementRate ?? 0;
          return rateB.compareTo(rateA);
        });
      case 'oldest':
        list.sort((a, b) => a.publishedAt.compareTo(b.publishedAt));
      default: // 'date'
        list.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    }
  }

  // ── Category Tabs ─────────────────────────────────────────────────────────

  Widget _buildCategoryTabs(int all, int videos, int shorts) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTab(0, 'All', all, Icons.grid_view_rounded, _kPurple),
          _buildTab(1, 'Videos', videos, Icons.play_circle_outline_rounded, Colors.blue),
          _buildTab(2, 'Shorts', shorts, Icons.bolt_rounded, _kRedAccent),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.15, end: 0);
  }

  Widget _buildTab(int index, String label, int count, IconData icon, Color accent) {
    final isSelected = _categoryIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _categoryIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accent.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 15,
                    color: isSelected ? Colors.white : Colors.grey[500],
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey[400],
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.22)
                      : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sort Row ──────────────────────────────────────────────────────────────

  // ── Discrepancy & Oldest Banners ──────────────────────────────────────────

  Widget _buildDiscrepancyNotice(int publicCount, int channelCount) {
    final diff = channelCount - publicCount;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 14, color: Colors.blue[300]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing $publicCount public videos ($diff unavailable or private on YouTube)',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[300],
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOldestHighlightBanner(Video oldestVideo) {
    final formattedDate = Helpers.formatDate(oldestVideo.publishedAt);
    final relativeTime = Helpers.formatRelativeTime(oldestVideo.publishedAt);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF312E81).withOpacity(0.4),
            const Color(0xFF1E1B4B).withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF818CF8).withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_edu_rounded, color: Color(0xFFA5B4FC), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'CHANNEL DEBUT • FIRST UPLOAD',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFA5B4FC),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      relativeTime,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  oldestVideo.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Uploaded $formattedDate • ${Helpers.formatNumber(oldestVideo.viewCount)} views',
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: -0.1, end: 0);
  }

  // ── Sort Row ──────────────────────────────────────────────────────────────

  Widget _buildSortRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Text(
            'Sort by',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSortChip('Latest', 'date', Icons.schedule_rounded),
                  const SizedBox(width: 8),
                  _buildSortChip('Oldest', 'oldest', Icons.history_rounded),
                  const SizedBox(width: 8),
                  _buildSortChip('Popular', 'views', Icons.local_fire_department_rounded),
                  const SizedBox(width: 8),
                  _buildSortChip('Likes', 'likes', Icons.thumb_up_rounded),
                  const SizedBox(width: 8),
                  _buildSortChip('Engagement', 'engagement', Icons.trending_up_rounded),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value, IconData icon) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? _kRedAccent.withOpacity(0.18) : _kCardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? _kRedAccent.withOpacity(0.7)
                : Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isSelected ? _kRedAccent : Colors.grey[500],
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _kRedAccent : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Video List (long-form / all) ──────────────────────────────────────────

  Widget _buildVideoList(List<Video> videos) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final item = videos[index];
        return VideoCard(
          key: ValueKey(item.id),
          video: item,
          onTap: () => _showVideoDetails(item),
        )
            .animate()
            .fadeIn(
              delay: (index * 35).clamp(0, 300).ms,
              duration: 280.ms,
            )
            .slideX(begin: -0.04, end: 0);
      },
    );
  }

  // ── Shorts Grid ───────────────────────────────────────────────────────────

  Widget _buildShortsGrid(List<Video> shorts) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 9 / 16, // vertical/portrait Shorts aspect ratio
      ),
      itemCount: shorts.length,
      itemBuilder: (context, index) {
        final short = shorts[index];
        return _ShortCard(
          video: short,
          onTap: () => _showVideoDetails(short),
        )
            .animate()
            .fadeIn(
              delay: (index * 30).clamp(0, 300).ms,
              duration: 260.ms,
            )
            .scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1));
      },
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    final isShorts = _categoryIndex == 2;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _kCardBg,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.07)),
            ),
            child: Icon(
              isShorts ? Icons.bolt_rounded : Icons.video_library_outlined,
              size: 40,
              color: isShorts ? _kRedAccent.withOpacity(0.6) : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isShorts
                ? 'No Shorts on this channel'
                : (_categoryIndex == 1
                    ? 'No long-form videos found'
                    : 'No videos found'),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull down to refresh',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _showVideoDetails(Video video) {
    Navigator.push(
      context,
      SlideRightRoute(page: VideoDetailsScreen(video: video)),
    );
  }
}

// ── Shorts card (vertical 9:16 portrait card) ─────────────────────────────

class _ShortCard extends StatelessWidget {
  final Video video;
  final VoidCallback? onTap;

  const _ShortCard({required this.video, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail
            CachedNetworkImage(
              imageUrl: video.thumbnail,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: const Color(0xFF0B1220),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFFF0000),
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: const Color(0xFF0B1220),
                child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
              ),
            ),

            // Gradient overlay at bottom
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.75),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.45, 1.0],
                  ),
                ),
              ),
            ),

            // Shorts badge (top-left)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0000),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, size: 11, color: Colors.white),
                    SizedBox(width: 2),
                    Text(
                      'Short',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Duration pill (top-right)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _formatDuration(video.duration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Bottom info
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    video.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.visibility, size: 11, color: Colors.white70),
                      const SizedBox(width: 3),
                      Text(
                        formatNumber(video.viewCount),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: _engagementColor(video.engagementRate).withOpacity(0.25),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _engagementColor(video.engagementRate).withOpacity(0.5),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          video.likesHidden
                              ? 'N/A'
                              : (video.engagementRate != null
                                  ? '${video.engagementRate!.toStringAsFixed(1)}%'
                                  : 'N/A'),
                          style: TextStyle(
                            color: _engagementColor(video.engagementRate),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _engagementColor(double? rate) {
    if (rate == null) return Colors.grey;
    if (rate > 5) return Colors.green;
    if (rate > 2) return Colors.blue;
    return Colors.orange;
  }

  String _formatDuration(String isoDuration) {
    if (isoDuration.isEmpty) return '';
    final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
    final match = regex.firstMatch(isoDuration);
    if (match == null) return '';
    final h = int.tryParse(match.group(1) ?? '0') ?? 0;
    final m = int.tryParse(match.group(2) ?? '0') ?? 0;
    final s = int.tryParse(match.group(3) ?? '0') ?? 0;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
