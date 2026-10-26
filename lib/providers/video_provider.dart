import '../services/sentiment_api_service.dart';
import 'package:flutter/material.dart';
import '../models/video_model.dart';
import '../models/comment_model.dart';
import '../models/analytics_model.dart';
import '../services/youtube_api_service.dart';
import '../services/cache_service.dart';
import '../services/sentiment_service.dart';

class VideoProvider with ChangeNotifier {
  final YouTubeApiService _apiService = YouTubeApiService();
  final CacheService _cacheService = CacheService();
  final SentimentService _sentimentService = SentimentService();
  final SentimentApiService _sentimentApi = SentimentApiService();
  String _sentimentSource = '';
  String get sentimentSource => _sentimentSource;



  Video? _currentVideo;
  List<Comment> _comments = [];
  SentimentAnalysis? _sentimentAnalysis;
  Map<String, int> _wordFrequency = {};
  bool _isLoading = false;
  String? _error;

  Video? get currentVideo => _currentVideo;
  List<Comment> get comments => _comments;
  SentimentAnalysis? get sentimentAnalysis => _sentimentAnalysis;
  Map<String, int> get wordFrequency => _wordFrequency;
  bool get isLoading => _isLoading;
  String? get error => _error;

  SentimentService get sentimentService => _sentimentService;

  // Set current video
  void setCurrentVideo(Video video) {
    _currentVideo = video;
    notifyListeners();
  }

  // Load comments and analyze sentiment
// Load comments and analyze sentiment (with smart caching)
Future<void> loadCommentsAndAnalyze(String videoId, {bool forceRefresh = false}) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  print('🔍 Loading comments for video: $videoId');

  try {
    // 1. Check if sentiment is already cached
    if (!forceRefresh) {
      final cachedSentiment = _cacheService.getSentimentAnalysis(videoId);
      if (cachedSentiment != null) {
        // Load comments from cache
        final cachedComments = _cacheService.getComments(videoId);
        if (cachedComments != null && cachedComments.isNotEmpty) {
          print('✅ Using cached comments and sentiment (instant)');
          _comments = cachedComments;
          _sentimentSource = 'Cached result';
          
          // Reconstruct sentiment analysis from cache
          var sentiment = cachedSentiment;
          if (sentiment.topPositive.isEmpty && sentiment.topNegative.isEmpty && _comments.isNotEmpty) {
            // Fallback for older cache entries: extract top positive & negative from cached comments
            final localAnalysis = _sentimentService.analyzeSentiment(_comments);
            sentiment = SentimentAnalysis(
              positive: sentiment.positive,
              neutral: sentiment.neutral,
              negative: sentiment.negative,
              positivePercentage: sentiment.positivePercentage,
              neutralPercentage: sentiment.neutralPercentage,
              negativePercentage: sentiment.negativePercentage,
              topPositive: localAnalysis.topPositive,
              topNegative: localAnalysis.topNegative,
            );
            _cacheService.saveSentimentAnalysis(videoId, sentiment);
          }

          _sentimentAnalysis = sentiment;
          _wordFrequency = _sentimentService.getWordFrequency(_comments);
          
          _isLoading = false;
          notifyListeners();
          return;
        }
      }
    }

    // 2. Fetch comments from API
    print('📡 Fetching comments from API...');
    _comments = await _apiService.fetchComments(videoId, maxResults: 50);
    if (_comments.length > 50) {
      _comments = _comments.take(50).toList();
    }
    print('✅ Fetched ${_comments.length} comments');

    if (_comments.isEmpty) {
      _error = 'No comments found. Comments might be disabled for this video.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    _cacheService.saveComments(videoId, _comments);

    // 3. Analyze sentiment (backend with local fallback)
    print('🧠 Analyzing sentiment...');
    await _analyzeSentiment();
    
    // 4. Cache the sentiment results
    if (_sentimentAnalysis != null) {
      _cacheService.saveSentimentAnalysis(videoId, _sentimentAnalysis!);
    }
    
    print('✅ Sentiment analysis complete');
    print('   Positive: ${_sentimentAnalysis?.positive}');
    print('   Neutral: ${_sentimentAnalysis?.neutral}');
    print('   Negative: ${_sentimentAnalysis?.negative}');

    _isLoading = false;
    notifyListeners();
  } catch (e) {
    print('❌ Error loading comments: $e');
    _error = e.toString().replaceAll('Exception: ', '');
    _isLoading = false;
    notifyListeners();
  }
}

  // Analyze sentiment
  // Analyze sentiment (changed to async and uses backend)
Future<void> _analyzeSentiment() async {
  // Try backend API first (RoBERTa fine-tuned on YouTube comments)
  if (SentimentApiService.isConfigured) {
    try {
      debugPrint('🌐 Trying backend sentiment API...');
      _sentimentAnalysis = await _sentimentApi.analyze(_comments);
      _sentimentSource = 'RoBERTa AI (roshan050/yt-sentiment-roberta)';
      debugPrint('✅ Used backend sentiment analysis');
      _wordFrequency = _sentimentService.getWordFrequency(_comments);
      return;
    } catch (e) {
      debugPrint('⚠️ Backend API failed ($e), falling back to local analysis...');
    }
  }

  // Fallback: on-device rule-based analysis
  try {
    _sentimentAnalysis = _sentimentService.analyzeSentiment(_comments);
    _sentimentSource = 'Local (on-device)';
    print('✅ Used local sentiment analysis');
    _wordFrequency = _sentimentService.getWordFrequency(_comments);
  } catch (e) {
    print('❌ Sentiment analysis failed: $e');
  }
}

  // Clear data
  void clear() {
    _currentVideo = null;
    _comments = [];
    _sentimentAnalysis = null;
    _wordFrequency = {};
    _error = null;
    notifyListeners();
  }
}
