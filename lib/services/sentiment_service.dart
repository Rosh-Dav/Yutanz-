import 'package:dart_sentiment/dart_sentiment.dart';
import '../models/comment_model.dart';
import '../models/analytics_model.dart';

class SentimentService {
  final Sentiment _sentiment = Sentiment();

  // Emoji sentiment mappings
  // Emoji sentiment mappings
static const Map<String, int> _emojiSentiments = {
  // Very Positive
  '😍': 3, '🥰': 3, '😘': 3, '❤️': 3, '💕': 3, '💖': 3, '🔥': 3, '✨': 2,
  '😊': 2, '😁': 2, '😃': 2, '😄': 2, '🤩': 3, '😎': 2, '👍': 2, '👏': 2,
  '🙌': 2, '💯': 3, '⭐': 2, '🌟': 2, '💪': 2, '🎉': 2, '🎊': 2, '🏆': 3,
  
  // Positive
  '🙂': 1, '😀': 1, '😌': 1, '😇': 1, '🤗': 1, '👌': 1, '✌️': 1, '💚': 1,
  
  // Negative
  '😢': -2, '😭': -2, '😞': -2, '😔': -2, '😟': -1, '😕': -1, '🙁': -1,
  
  // Very Negative
  '😡': -3, '😠': -3, '🤬': -3, '😤': -2, '💔': -2, '👎': -2, '🤮': -3,
  '💩': -3, '😒': -1, '🙄': -1, '😑': -1,  // Remove the second '😒' if it appears again below
  
  // Neutral
  '😐': 0, '😶': 0, '🤔': 0, '😮': 0, '😯': 0,
};

  // YouTube-specific positive keywords
  static const Map<String, int> _positiveKeywords = {
    'amazing': 3, 'awesome': 3, 'excellent': 3, 'perfect': 3, 'love': 3,
    'best': 3, 'great': 2, 'good': 2, 'nice': 2, 'cool': 2, 'beautiful': 2,
    'wonderful': 3, 'fantastic': 3, 'incredible': 3, 'epic': 3, 'legendary': 3,
    'helpful': 2, 'useful': 2, 'informative': 2, 'interesting': 2,
    'enjoyed': 2, 'enjoying': 2, 'favorite': 2, 'liked': 1, 'thanks': 1,
    'thank': 1, 'appreciate': 2, 'congratulations': 2, 'congrats': 2,
  };

  // YouTube-specific negative keywords
 // YouTube-specific negative keywords
static const Map<String, int> _negativeKeywords = {
  'terrible': -3, 'awful': -3, 'horrible': -3, 'worst': -3, 'hate': -3,
  'bad': -2, 'poor': -2, 'disappointed': -2, 'disappointing': -2,
  'boring': -2, 'useless': -2, 'waste': -2, 'sucks': -3, 'stupid': -2,
  'annoying': -2, 'irritating': -2, 'fake': -2, 'clickbait': -2,
  'dislike': -2, 'disliked': -2, 'crap': -3, 'trash': -3,  // Removed duplicate 'terrible'
  'misleading': -2, 'confusing': -1, 'wrong': -1,
};

  // Analyze sentiment for a list of comments
  SentimentAnalysis analyzeSentiment(List<Comment> comments) {
    if (comments.isEmpty) {
      return SentimentAnalysis(
        positive: 0,
        neutral: 0,
        negative: 0,
        positivePercentage: 0,
        neutralPercentage: 0,
        negativePercentage: 0,
        topPositive: [],
        topNegative: [],
      );
    }

    int positive = 0;
    int neutral = 0;
    int negative = 0;

    final List<MapEntry<Comment, double>> scoredComments = [];

    for (final comment in comments) {
      // Enhanced sentiment analysis
      final score = _analyzeCommentSentiment(comment.text);

      if (score > 1.5) {
        positive++;
      } else if (score < -1.5) {
        negative++;
      } else {
        neutral++;
      }

      scoredComments.add(MapEntry(comment, score));
    }

    final total = comments.length;

    // Get top positive and negative comments
    scoredComments.sort((a, b) => b.value.compareTo(a.value));
    final topPositive = scoredComments
        .where((e) => e.value > 1.5)
        .take(5)
        .map((e) => e.key)
        .toList();

    final topNegative = scoredComments
        .where((e) => e.value < -1.5)
        .toList()
        .reversed
        .take(5)
        .map((e) => e.key)
        .toList();

    return SentimentAnalysis(
      positive: positive,
      neutral: neutral,
      negative: negative,
      positivePercentage: (positive / total) * 100,
      neutralPercentage: (neutral / total) * 100,
      negativePercentage: (negative / total) * 100,
      topPositive: topPositive,
      topNegative: topNegative,
    );
  }

  // Enhanced sentiment analysis for a single comment
  double _analyzeCommentSentiment(String text) {
    double score = 0.0;

    // 1. Base sentiment analysis using dart_sentiment
    try {
      final result = _sentiment.analysis(text, emoji: false);
      score = ((result['score'] ?? 0) as num).toDouble();
    } catch (e) {
      // If dart_sentiment fails, continue with other methods
      score = 0.0;
    }

    // 2. Emoji analysis
    final emojiScore = _analyzeEmojis(text);
    score += emojiScore;

    // 3. YouTube-specific keyword analysis
    final keywordScore = _analyzeKeywords(text);
    score += keywordScore;

    // 4. Analyze caps and exclamation (enthusiasm indicators)
    final enthusiasmScore = _analyzeEnthusiasm(text);
    score += enthusiasmScore;

    // 5. Analyze negations (not good, not bad, etc.)
    score = _applyNegations(text, score);

    return score;
  }

  // Analyze emojis in text
  double _analyzeEmojis(String text) {
    double score = 0.0;
    int emojiCount = 0;

    for (final entry in _emojiSentiments.entries) {
      final count = entry.key.allMatches(text).length;
      if (count > 0) {
        score += entry.value * count;
        emojiCount += count;
      }
    }

    // Normalize if too many emojis (avoid spam boosting)
    if (emojiCount > 5) {
      score = score * (5.0 / emojiCount);
    }

    return score;
  }

  // Analyze YouTube-specific keywords
  double _analyzeKeywords(String text) {
    double score = 0.0;
    final lowerText = text.toLowerCase();

    // Check positive keywords
    for (final entry in _positiveKeywords.entries) {
      if (lowerText.contains(entry.key)) {
        score += entry.value;
      }
    }

    // Check negative keywords
    for (final entry in _negativeKeywords.entries) {
      if (lowerText.contains(entry.key)) {
        score += entry.value; // Already negative values
      }
    }

    return score;
  }

  // Analyze enthusiasm (caps, exclamation marks)
  double _analyzeEnthusiasm(String text) {
    double score = 0.0;

    // Exclamation marks (positive enthusiasm)
    final exclamationCount = '!'.allMatches(text).length;
    if (exclamationCount > 0 && exclamationCount <= 3) {
      score += exclamationCount * 0.5;
    }

    // Multiple caps words (can be positive or negative)
    final words = text.split(' ');
    final capsWords = words.where((w) => 
      w.length > 3 && 
      w == w.toUpperCase() && 
      RegExp(r'^[A-Z]+$').hasMatch(w)
    ).length;

    // Caps with positive context = enthusiasm
    // Caps with negative context = anger
    if (capsWords > 0 && capsWords <= 3) {
      // Determine context from surrounding words
      final hasPositive = _positiveKeywords.keys
          .any((k) => text.toLowerCase().contains(k));
      final hasNegative = _negativeKeywords.keys
          .any((k) => text.toLowerCase().contains(k));

      if (hasPositive && !hasNegative) {
        score += capsWords * 0.5;
      } else if (hasNegative && !hasPositive) {
        score -= capsWords * 0.5;
      }
    }

    return score;
  }

  // Apply negation detection (not good = bad)
  double _applyNegations(String text, double currentScore) {
    final lowerText = text.toLowerCase();
    
    final negations = ['not', 'no', 'never', 'dont', "don't", 'didnt', "didn't", 'cant', "can't"];
    final positiveWords = _positiveKeywords.keys.toList();
    final negativeWords = _negativeKeywords.keys.toList();

    for (final negation in negations) {
      // Check if negation appears before positive word
      for (final posWord in positiveWords) {
        if (lowerText.contains('$negation $posWord') || 
            lowerText.contains('$negation $posWord')) {
          currentScore -= 2; // Flip to negative
        }
      }

      // Check if negation appears before negative word (double negative = positive)
      for (final negWord in negativeWords) {
        if (lowerText.contains('$negation $negWord') || 
            lowerText.contains('$negation $negWord')) {
          currentScore += 1.5; // Flip to less negative or positive
        }
      }
    }

    return currentScore;
  }

  // Get word frequency from comments (improved)
  Map<String, int> getWordFrequency(List<Comment> comments, {int topN = 20}) {
    final Map<String, int> wordCount = {};
    
    // Expanded stop words
    final stopWords = {
      'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
      'of', 'is', 'it', 'this', 'that', 'with', 'from', 'by', 'as', 'be',
      'was', 'are', 'been', 'have', 'has', 'had', 'do', 'does', 'did',
      'will', 'would', 'could', 'should', 'can', 'may', 'i', 'you', 'he',
      'she', 'we', 'they', 'my', 'your', 'his', 'her', 'our', 'their',
      'just', 'so', 'than', 'very', 'can', 'get', 'like', 'what', 'when',
      'there', 'if', 'who', 'which', 'all', 'up', 'out', 'about', 'some',
    };

    for (final comment in comments) {
      // Remove URLs, mentions, emojis, and special characters
      final cleanText = comment.text
          .replaceAll(RegExp(r'https?://\S+'), '')
          .replaceAll(RegExp(r'@\w+'), '')
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .toLowerCase();

      final words = cleanText
          .split(RegExp(r'\s+'))
          .where((w) => w.length > 3 && !stopWords.contains(w));

      for (final word in words) {
        wordCount[word] = (wordCount[word] ?? 0) + 1;
      }
    }

    final sorted = wordCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sorted.take(topN));
  }

  // Get sentiment summary text
  String getSentimentSummary(SentimentAnalysis analysis) {
    if (analysis.total == 0) return 'No comments to analyze';

    final dominant = analysis.positivePercentage > analysis.negativePercentage
        ? 'Positive'
        : analysis.negativePercentage > analysis.positivePercentage
            ? 'Negative'
            : 'Neutral';

    final percentage = dominant == 'Positive'
        ? analysis.positivePercentage
        : dominant == 'Negative'
            ? analysis.negativePercentage
            : analysis.neutralPercentage;

    return 'Overall $dominant (${percentage.toStringAsFixed(1)}%)';
  }
}