import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/comment_model.dart';
import '../models/analytics_model.dart';

/// Single prediction entry returned from the sentiment model.
class SentimentPrediction {
  final String label; // 'positive', 'neutral', 'negative'
  final Map<String, double> scores;

  const SentimentPrediction({
    required this.label,
    required this.scores,
  });

  double get confidence => scores[label] ?? 0.0;
}

/// Client for the fine-tuned RoBERTa sentiment analysis Gradio 6 Space
/// (roshan050/sentiment-analysis-gradio, base model cardiffnlp/twitter-roberta-base-sentiment-latest).
class SentimentApiService {
  static const int maxBatchSize = 200;

  final http.Client _client;
  final String? _customBaseUrl;
  final Duration timeout;
  final int maxRetries;
  final Duration initialRetryDelay;

  SentimentApiService({
    http.Client? client,
    String? baseUrl,
    this.timeout = const Duration(seconds: 90),
    this.maxRetries = 2,
    this.initialRetryDelay = const Duration(seconds: 2),
  })  : _client = client ?? http.Client(),
        _customBaseUrl = baseUrl;

  static String get baseUrl =>
      (dotenv.env['SENTIMENT_API_URL'] ?? '').trim().replaceAll(RegExp(r'/+$'), '');

  static bool get isConfigured => baseUrl.isNotEmpty;

  String get effectiveBaseUrl =>
      (_customBaseUrl ?? baseUrl).trim().replaceAll(RegExp(r'/+$'), '');

  bool get isReady => effectiveBaseUrl.isNotEmpty;

  /// Splits a list into chunks of at most [chunkSize], keeping original order.
  static List<List<T>> chunkList<T>(List<T> list, int chunkSize) {
    if (list.isEmpty) return [];
    if (chunkSize <= 0) return [list];
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += chunkSize) {
      final end = (i + chunkSize < list.length) ? i + chunkSize : list.length;
      chunks.add(list.sublist(i, end));
    }
    return chunks;
  }

  /// Defensively parses the JSON list returned by Gradio into [SentimentPrediction] objects.
  static List<SentimentPrediction> parsePredictions(dynamic raw) {
    if (raw is! List) return [];
    final predictions = <SentimentPrediction>[];

    for (final item in raw) {
      if (item is Map) {
        final rawLabel = (item['label'] ?? 'neutral').toString().toLowerCase().trim();
        final label = (rawLabel == 'positive' || rawLabel == 'negative') ? rawLabel : 'neutral';

        final scores = <String, double>{
          'negative': 0.0,
          'neutral': 0.0,
          'positive': 0.0,
        };

        final rawScores = item['scores'];
        if (rawScores is Map) {
          for (final key in ['negative', 'neutral', 'positive']) {
            final val = rawScores[key];
            if (val is num) {
              scores[key] = val.toDouble();
            }
          }
        } else {
          // If scores map is missing, assign 1.0 confidence to the predicted label
          scores[label] = 1.0;
        }

        predictions.add(SentimentPrediction(label: label, scores: scores));
      } else {
        // Fallback for an unparsable item
        predictions.add(const SentimentPrediction(
          label: 'neutral',
          scores: {'negative': 0.0, 'neutral': 1.0, 'positive': 0.0},
        ));
      }
    }

    return predictions;
  }

  /// Analyzes a list of YouTube comments using the fine-tuned RoBERTa model.
  Future<SentimentAnalysis> analyze(List<Comment> comments) async {
    if (!isReady) {
      throw Exception('SENTIMENT_API_URL is not set in .env');
    }

    if (comments.isEmpty) {
      return SentimentAnalysis(
        positive: 0,
        neutral: 0,
        negative: 0,
        positivePercentage: 0.0,
        neutralPercentage: 0.0,
        negativePercentage: 0.0,
        topPositive: [],
        topNegative: [],
      );
    }

    // Split comments into chunks of at most 200 (server limit)
    final chunks = chunkList(comments, maxBatchSize);
    final allPredictions = <SentimentPrediction>[];

    for (final chunk in chunks) {
      final chunkTexts = chunk.map((c) => c.text).toList();
      final chunkPredictions = await _predictChunkWithRetry(chunkTexts);
      allPredictions.addAll(chunkPredictions);
    }

    // Aggregate statistics and top positive/negative comments
    var positive = 0, neutral = 0, negative = 0;
    final scoredPos = <MapEntry<Comment, double>>[];
    final scoredNeg = <MapEntry<Comment, double>>[];

    for (var i = 0; i < comments.length && i < allPredictions.length; i++) {
      final comment = comments[i];
      final pred = allPredictions[i];

      if (pred.label == 'positive') {
        positive++;
        final conf = pred.scores['positive'] ?? pred.confidence;
        scoredPos.add(MapEntry(comment, conf));
      } else if (pred.label == 'negative') {
        negative++;
        final conf = pred.scores['negative'] ?? pred.confidence;
        scoredNeg.add(MapEntry(comment, conf));
      } else {
        neutral++;
      }
    }

    // Account for any remaining items if server response count differed
    if (allPredictions.length < comments.length) {
      neutral += (comments.length - allPredictions.length);
    }

    final total = positive + neutral + negative;
    double pct(int count) => total == 0 ? 0.0 : (count * 100.0) / total;

    // Rank top positive comments by positive confidence score
    scoredPos.sort((a, b) => b.value.compareTo(a.value));
    // Rank top negative comments by negative confidence score
    scoredNeg.sort((a, b) => b.value.compareTo(a.value));

    return SentimentAnalysis(
      positive: positive,
      neutral: neutral,
      negative: negative,
      positivePercentage: pct(positive),
      neutralPercentage: pct(neutral),
      negativePercentage: pct(negative),
      topPositive: scoredPos.take(5).map((e) => e.key).toList(),
      topNegative: scoredNeg.take(5).map((e) => e.key).toList(),
    );
  }

  /// Retries transient failures with exponential backoff.
  Future<List<SentimentPrediction>> _predictChunkWithRetry(List<String> chunkTexts) async {
    int attempt = 0;
    Duration currentDelay = initialRetryDelay;

    while (true) {
      attempt++;
      try {
        return await _predictChunk(chunkTexts);
      } catch (e) {
        final isLast = attempt > maxRetries;
        if (isLast || !_isRetryableError(e)) {
          rethrow;
        }
        await Future.delayed(currentDelay);
        currentDelay *= 2;
      }
    }
  }

  bool _isRetryableError(dynamic error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('quota') || msg.contains('429')) {
      return false; // Do not retry quota errors immediately
    }
    return error is TimeoutException ||
        error is SocketException ||
        error is http.ClientException ||
        msg.contains('502') ||
        msg.contains('503') ||
        msg.contains('504') ||
        msg.contains('cold start') ||
        msg.contains('connection');
  }

  /// Calls the Gradio 6 Space `/predict` endpoint via the two-step REST SSE protocol.
  Future<List<SentimentPrediction>> _predictChunk(List<String> texts) async {
    final base = effectiveBaseUrl;
    final submitUri = Uri.parse('$base/gradio_api/call/predict');

    // Step 1: Submit job to Gradio endpoint
    http.Response submit;
    try {
      submit = await _client
          .post(
            submitUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'data': [texts],
            }),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw Exception('Sentiment service request timed out during submission. The model may be cold-starting; please retry shortly.');
    } on SocketException catch (e) {
      throw Exception('Cannot connect to sentiment service ($e). Please check your internet connection.');
    } catch (e) {
      throw Exception('Failed to connect to sentiment service: $e');
    }

    if (submit.statusCode == 429) {
      throw Exception('Sentiment service rate limit or usage quota exceeded. Please wait a moment before trying again.');
    } else if (submit.statusCode == 502 || submit.statusCode == 503 || submit.statusCode == 504) {
      throw Exception('Sentiment service is currently waking up or experiencing high load (HTTP ${submit.statusCode}). Retrying...');
    } else if (submit.statusCode != 200) {
      throw Exception('Sentiment server error on submission: HTTP ${submit.statusCode} - ${submit.body}');
    }

    final Map<String, dynamic> submitJson;
    try {
      submitJson = jsonDecode(submit.body) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Invalid submission response from sentiment service: ${submit.body}');
    }

    final eventId = submitJson['event_id'] as String?;
    if (eventId == null || eventId.isEmpty) {
      throw Exception('Sentiment server did not return a valid event_id.');
    }

    // Step 2: Stream result from SSE endpoint
    final streamUri = Uri.parse('$base/gradio_api/call/predict/$eventId');
    http.Response reply;
    try {
      reply = await _client.get(streamUri).timeout(timeout);
    } on TimeoutException {
      throw Exception('Sentiment service timed out waiting for results. Cold start may take up to a minute; please retry.');
    } catch (e) {
      throw Exception('Failed to retrieve sentiment analysis results: $e');
    }

    if (reply.statusCode == 429) {
      throw Exception('Sentiment service quota exceeded during result retrieval.');
    } else if (reply.statusCode != 200) {
      throw Exception('Sentiment server error during result retrieval: HTTP ${reply.statusCode}');
    }

    // Step 3: Parse SSE output
    String? currentEvent;
    String? dataLine;
    String? errorMessage;

    for (final line in const LineSplitter().convert(utf8.decode(reply.bodyBytes))) {
      final trimmed = line.trim();
      if (trimmed.startsWith('event:')) {
        currentEvent = trimmed.substring(6).trim();
      } else if (trimmed.startsWith('data:')) {
        final payload = trimmed.substring(5).trim();
        if (currentEvent == 'error') {
          errorMessage = payload;
          break;
        } else if (currentEvent == 'complete') {
          dataLine = payload;
          break;
        }
      }
    }

    if (errorMessage != null) {
      throw Exception('Sentiment server reported an error: $errorMessage');
    }

    if (dataLine == null) {
      throw Exception('Sentiment server returned an empty or incomplete response.');
    }

    dynamic decodedData;
    try {
      decodedData = jsonDecode(dataLine);
    } catch (e) {
      throw Exception('Failed to decode sentiment response: $e');
    }

    // Gradio returns [ output_0, output_1, ... ]
    final dynamic predictionsRaw = (decodedData is List && decodedData.isNotEmpty)
        ? decodedData.first
        : decodedData;

    return parsePredictions(predictionsRaw);
  }
}