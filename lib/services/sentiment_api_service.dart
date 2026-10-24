import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/comment_model.dart';
import '../models/analytics_model.dart';

/// Calls the Python backend (VADER + Naive Bayes) hosted on Hugging Face Spaces.
/// Set SENTIMENT_API_URL in .env, e.g. https://yourname-yt-sentiment.hf.space
class SentimentApiService {
  static String get baseUrl =>
      (dotenv.env['SENTIMENT_API_URL'] ?? '').trim().replaceAll(RegExp(r'/+$'), '');

  static bool get isConfigured => baseUrl.isNotEmpty;

  Future<SentimentAnalysis> analyze(List<Comment> comments) async {
    if (!isConfigured) {
      throw Exception('SENTIMENT_API_URL is not set in .env');
    }

    final payload =
        jsonEncode(comments.map((c) => {'id': c.id, 'text': c.text}).toList());

    // Step 1: submit the job to the Gradio API
    final submit = await http
        .post(
          Uri.parse('$baseUrl/gradio_api/call/analyze'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'data': [payload],
          }),
        )
        // Free hosting can take up to ~1 minute to wake up after being idle.
        .timeout(const Duration(seconds: 90));

    if (submit.statusCode != 200) {
      throw Exception('Sentiment server error: ${submit.statusCode}');
    }
    final eventId =
        (jsonDecode(submit.body) as Map<String, dynamic>)['event_id'] as String;

    // Step 2: read the result (server-sent event)
    final reply = await http
        .get(Uri.parse('$baseUrl/gradio_api/call/analyze/$eventId'))
        .timeout(const Duration(seconds: 90));

    if (reply.statusCode != 200) {
      throw Exception('Sentiment server error: ${reply.statusCode}');
    }

    String? event;
    String? dataLine;
    for (final line in const LineSplitter().convert(utf8.decode(reply.bodyBytes))) {
      if (line.startsWith('event:')) {
        event = line.substring(6).trim();
      } else if (line.startsWith('data:') && event == 'complete') {
        dataLine = line.substring(5).trim();
        break;
      }
    }
    if (dataLine == null) {
      throw Exception('Sentiment server returned no result');
    }

    final data = (jsonDecode(dataLine) as List).first as Map<String, dynamic>;
    final results = (data['results'] as List).cast<Map<String, dynamic>>();

    // Results come back in the same order as the comments we sent.
    final scored = <MapEntry<Comment, double>>[];
    var positive = 0, neutral = 0, negative = 0;

    for (var i = 0; i < results.length && i < comments.length; i++) {
      final label = results[i]['label'] as String;
      final score = (results[i]['score'] as num).toDouble();
      scored.add(MapEntry(comments[i], score));
      if (label == 'positive') {
        positive++;
      } else if (label == 'negative') {
        negative++;
      } else {
        neutral++;
      }
    }

    final total = positive + neutral + negative;
    double pct(int n) => total == 0 ? 0 : n * 100 / total;

    // Top comments by label, ranked by combined score
    final labels = results.map((r) => r['label'] as String).toList();
    final posList = <MapEntry<Comment, double>>[];
    final negList = <MapEntry<Comment, double>>[];
    for (var i = 0; i < scored.length; i++) {
      if (labels[i] == 'positive') posList.add(scored[i]);
      if (labels[i] == 'negative') negList.add(scored[i]);
    }
    posList.sort((a, b) => b.value.compareTo(a.value));
    negList.sort((a, b) => a.value.compareTo(b.value));

    return SentimentAnalysis(
      positive: positive,
      neutral: neutral,
      negative: negative,
      positivePercentage: pct(positive),
      neutralPercentage: pct(neutral),
      negativePercentage: pct(negative),
      topPositive: posList.take(5).map((e) => e.key).toList(),
      topNegative: negList.take(5).map((e) => e.key).toList(),
    );
  }
}