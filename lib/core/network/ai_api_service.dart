import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../errors/exceptions.dart';

/// AI API Service (via Supabase Edge Functions)
/// API key güvenli şekilde backend'de saklanır
class AiApiService {
  // This field is intentionally kept for future use (conversation history)
  // ignore: unused_field
  List<Map<String, dynamic>> _conversationHistory = [];
  String? _currentUserLevel;
  String? _currentTopic;

  AiApiService._();

  static final AiApiService instance = AiApiService._();

  /// Send a single message to AI via Supabase Edge Function
  Future<String> sendMessage(
    String message, {
    String? userLevel,
    String? topic,
    List<Map<String, String>>? conversationHistory,
  }) async {
    try {
      // Direct HTTP call with anon key (no session check needed)
      const anonKey =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdvaHJ4ZWhucmVvaGxqZ3N4bGlnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc5NjM2MDQsImV4cCI6MjA4MzUzOTYwNH0.OrIQIoxV2-9jUK2fNvv-scTuejetftm1RISB1bEZwl4';
      const url =
          'https://gohrxehnreohljgsxlig.supabase.co/functions/v1/ai-chat';

      debugPrint('🔍 Sending message to: $url');
      debugPrint('🔍 Message: $message');

      final httpResponse = await http
          .post(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $anonKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'message': message,
              'userLevel': userLevel ?? 'A1.1',
              'topic': topic ?? 'Genel',
              'conversationHistory': conversationHistory ?? [],
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw ApiException(
                'Sunucu yanıt vermiyor (timeout). Lütfen tekrar deneyin.',
              );
            },
          );

      debugPrint('🔍 Response status: ${httpResponse.statusCode}');
      debugPrint('🔍 Response body: ${httpResponse.body}');

      if (httpResponse.statusCode == 401) {
        throw ApiException('Oturum süresi dolmuş. Lütfen yeniden giriş yapın.');
      }

      if (httpResponse.statusCode != 200) {
        throw ApiException(
          'Sunucu hatası: ${httpResponse.statusCode} - ${httpResponse.body}',
        );
      }

      final data = jsonDecode(httpResponse.body) as Map<String, dynamic>;
      final responseText = data['response'] as String;

      // Update conversation history
      _conversationHistory = List<Map<String, dynamic>>.from(
        data['conversationHistory'] ?? [],
      );

      return responseText;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Bağlantı hatası: ${e.toString()}');
    }
  }

  /// Start a conversation with context (for German learning)
  Future<void> startConversation({
    required String userLevel,
    required String topic,
  }) async {
    _currentUserLevel = userLevel;
    _currentTopic = topic;
    _conversationHistory = [];

    // First message to initialize context
    await sendMessage('Merhaba!', userLevel: userLevel, topic: topic);
  }

  /// Start conversation without sending initial message
  void startConversationWithoutMessage({
    required String userLevel,
    required String topic,
  }) {
    _currentUserLevel = userLevel;
    _currentTopic = topic;
    _conversationHistory = [];
  }

  /// Reset conversation (clear history but keep context)
  void resetConversation() {
    _conversationHistory = [];
  }

  /// Send message in an existing conversation
  Future<String> sendChatMessage(String message) async {
    if (_currentUserLevel == null || _currentTopic == null) {
      throw ApiException('No active conversation. Start a conversation first.');
    }

    return await sendMessage(
      message,
      userLevel: _currentUserLevel,
      topic: _currentTopic,
    );
  }

  /// End current conversation
  void endConversation() {
    _conversationHistory = [];
    _currentUserLevel = null;
    _currentTopic = null;
  }

  /// Check if there's an active conversation
  bool get hasActiveConversation =>
      _currentUserLevel != null && _currentTopic != null;

  /// Get adaptive quiz from Edge Function (expects Gemini-based JSON schema)
  Future<Map<String, dynamic>> getAdaptiveQuiz(
    String topic,
    String level,
  ) async {
    try {
      const url =
          'https://gohrxehnreohljgsxlig.supabase.co/functions/v1/adaptive-quiz';

      // Retry with exponential backoff + jitter on transient failures (5xx/timeouts)
      http.Response? httpResponse;
      const int maxAttempts = 5;
      final rng = Random();

      for (int attempt = 1; attempt <= maxAttempts; attempt++) {
        debugPrint(
          '🔁 adaptive-quiz attempt $attempt/$maxAttempts for level=$level topic=$topic',
        );
        try {
          httpResponse = await http
              .post(
                Uri.parse(url),
                headers: {
                  // Authorization header removed — use Supabase secrets for deployed functions.
                  'Content-Type': 'application/json',
                },
                body: jsonEncode({'topic': topic, 'level': level}),
              )
              .timeout(
                const Duration(seconds: 30),
                onTimeout: () {
                  throw ApiException(
                    'Sunucu yanıt vermiyor. Lütfen tekrar deneyin.',
                  );
                },
              );
        } catch (e) {
          debugPrint('❌ adaptive-quiz attempt $attempt exception: $e');
          if (attempt == maxAttempts) {
            debugPrint(
              '⚠️ adaptive-quiz: max attempts reached after exception, returning fallback quiz',
            );
            return {
              'question': 'Sunucu şu anda kullanılamıyor — örnek soru',
              'options': ['A', 'B', 'C', 'D'],
              'correct_answer': 'A',
              'options_turkish': ['A', 'B', 'C', 'D'],
              'question_turkish':
                  'Sunucu şu anda kullanılamıyor. Bu örnek bir sorudur.',
              'difficulty': 'medium',
              'vocabulary': null,
              'curriculum': null,
            };
          }
          final backoffMs =
              (300 * pow(2, attempt - 1)).toInt() + rng.nextInt(200);
          debugPrint('⏳ Backing off for ${backoffMs}ms before retry');
          await Future.delayed(Duration(milliseconds: backoffMs));
          continue;
        }

        debugPrint('🔍 Response status: ${httpResponse.statusCode}');

        if (httpResponse.statusCode == 200) break;

        // If server error (5xx) then retry after backoff
        if (httpResponse.statusCode >= 500 && httpResponse.statusCode < 600) {
          debugPrint(
            '⚠️ Server error ${httpResponse.statusCode} - ${httpResponse.body}',
          );
          if (attempt == maxAttempts) {
            debugPrint(
              '⚠️ adaptive-quiz: max attempts reached, returning fallback quiz',
            );
            return {
              'question': 'Sunucu şu anda kullanılamıyor — örnek soru',
              'options': ['A', 'B', 'C', 'D'],
              'correct_answer': 'A',
              'options_turkish': ['A', 'B', 'C', 'D'],
              'question_turkish':
                  'Sunucu şu anda kullanılamıyor. Bu örnek bir sorudur.',
              'difficulty': 'medium',
              'vocabulary': null,
              'curriculum': null,
            };
          }
          final backoffMs =
              (300 * pow(2, attempt - 1)).toInt() + rng.nextInt(200);
          debugPrint('⏳ Backing off for ${backoffMs}ms before retry');
          await Future.delayed(Duration(milliseconds: backoffMs));
          continue;
        }

        // Non-retriable errors
        if (httpResponse.statusCode == 401) {
          throw ApiException(
            'Oturum süresi dolmuş. Lütfen yeniden giriş yapın.',
          );
        }

        throw ApiException(
          'Sunucu hatası: ${httpResponse.statusCode} - ${httpResponse.body}',
        );
      }

      if (httpResponse == null) {
        debugPrint(
          '⚠️ adaptive-quiz: httpResponse null — returning fallback quiz',
        );
        return {
          'question': 'Sunucu şu anda kullanılamıyor — örnek soru',
          'options': ['A', 'B', 'C', 'D'],
          'correct_answer': 'A',
          'options_turkish': ['A', 'B', 'C', 'D'],
          'question_turkish':
              'Sunucu şu anda kullanılamıyor. Bu örnek bir sorudur.',
          'difficulty': 'medium',
          'vocabulary': null,
          'curriculum': null,
        };
      }

      if (httpResponse.statusCode != 200) {
        // If server-side issue, return a safe fallback quiz instead of failing the whole flow
        if (httpResponse.statusCode >= 500 && httpResponse.statusCode < 600) {
          debugPrint(
            '⚠️ adaptive-quiz: server error ${httpResponse.statusCode} — returning fallback quiz',
          );
          return {
            'question': 'Sunucu şu anda kullanılamıyor — örnek soru',
            'options': ['A', 'B', 'C', 'D'],
            'correct_answer': 'A',
            'options_turkish': ['A', 'B', 'C', 'D'],
            'question_turkish':
                'Sunucu şu anda kullanılamıyor. Bu örnek bir sorudur.',
            'difficulty': 'medium',
            'vocabulary': null,
            'curriculum': null,
          };
        }

        throw ApiException('Sunucu hatası: ${httpResponse.statusCode}');
      }

      final data = jsonDecode(httpResponse.body) as Map<String, dynamic>;

      // Support both legacy 'quiz' shape and new Gemini schema
      if (data.containsKey('quiz') && data['quiz'] is Map<String, dynamic>) {
        final quizRaw = data['quiz'] as Map<String, dynamic>;
        final question = quizRaw['question'];
        final options = quizRaw['options'];
        final correct = quizRaw['correct_answer'];

        if (question == null || options == null || correct == null) {
          throw ApiException('Quiz verisi eksik.');
        }

        if (options is! List) {
          throw ApiException(
            'Quiz seçenekleri beklenenden farklı bir formatta.',
          );
        }

        final normalizedOptions = options.map((e) => e.toString()).toList();

        if (!normalizedOptions.contains(correct.toString())) {
          throw ApiException('Quiz: doğru cevap seçenekler arasında değil.');
        }

        return {
          'question': question.toString(),
          'options': normalizedOptions,
          'correct_answer': correct.toString(),
          'options_turkish': (quizRaw['options_turkish'] as List?)
              ?.map((e) => e.toString())
              .toList(),
          'question_turkish': quizRaw['question_turkish'] as String?,
          'difficulty': quizRaw['difficulty'] as String? ?? 'medium',
        };
      }

      // New Gemini schema
      if (data.containsKey('questions') && data['questions'] is List) {
        final questions = data['questions'] as List;
        if (questions.isEmpty) {
          throw ApiException('Quiz soruları boş.');
        }

        final first = questions.first as Map<String, dynamic>;
        final qText = first['question'] ?? first['text'] ?? first['prompt'];
        List options = first['options'] as List? ?? [];
        String? correctAnswer;

        // options may be list of maps {id,text,correct}
        if (options.isNotEmpty && options.first is Map<String, dynamic>) {
          final opts = options.map((e) => e as Map<String, dynamic>).toList();
          final correctOpt = opts.firstWhere(
            (m) => m['correct'] == true,
            orElse: () => <String, dynamic>{},
          );
          if (correctOpt.isNotEmpty)
            correctAnswer =
                correctOpt['id']?.toString() ?? correctOpt['text']?.toString();
          final normalizedOptions = opts
              .map((m) => m['id']?.toString() ?? m['text']?.toString() ?? '')
              .toList();

          if (correctAnswer == null && opts.isNotEmpty) {
            // fallback: if correct not marked, prefer first
            correctAnswer = normalizedOptions.first;
          }

          final vocabulary = (data['vocabulary'] as List?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList();
          final curriculum = (data['curriculum'] as List?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList();

          return {
            'question': qText.toString(),
            'options': normalizedOptions,
            'correct_answer': correctAnswer,
            'options_turkish': null,
            'question_turkish': null,
            'difficulty': (first['difficulty']?.toString()) ?? 'medium',
            'vocabulary': vocabulary,
            'curriculum': curriculum,
          };
        }

        // options may be simple list of strings
        if (options.isNotEmpty && options.first is String) {
          final opts = options.map((e) => e.toString()).toList();
          correctAnswer = first['correct']?.toString() ?? opts.first;
          if (!opts.contains(correctAnswer)) correctAnswer = opts.first;

          final vocabulary = (data['vocabulary'] as List?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList();
          final curriculum = (data['curriculum'] as List?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList();

          return {
            'question': qText.toString(),
            'options': opts,
            'correct_answer': correctAnswer,
            'options_turkish': null,
            'question_turkish': null,
            'difficulty': (first['difficulty']?.toString()) ?? 'medium',
            'vocabulary': vocabulary,
            'curriculum': curriculum,
          };
        }

        throw ApiException('Quiz seçenekleri beklenenden farklı formatta.');
      }

      throw ApiException('Quiz formatı beklenenden farklı.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Quiz yüklenemedi: ${e.toString()}');
    }
  }

  /// Save quiz result to local storage (RLS bypass)
  Future<void> saveQuizResult({
    required String topic,
    required String level,
    required String question,
    required String userAnswer,
    required String correctAnswer,
    required bool isCorrect,
    required String difficulty,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Quiz history kaydet
      final historyKey = 'quiz_history_${topic}_$level';
      List<String> history = prefs.getStringList(historyKey) ?? [];
      history.add(
        jsonEncode({
          'question': question,
          'user_answer': userAnswer,
          'correct_answer': correctAnswer,
          'is_correct': isCorrect,
          'difficulty': difficulty,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      await prefs.setStringList(historyKey, history);

      // Progress güncelle
      final progressKey = 'user_progress_${topic}_$level';
      final progressJson = prefs.getString(progressKey);

      Map<String, dynamic> progress;
      if (progressJson == null) {
        progress = {
          'topic': topic,
          'level': level,
          'total_score': isCorrect ? 1 : 0,
          'correct_answers': isCorrect ? 1 : 0,
          'wrong_answers': isCorrect ? 0 : 1,
          'last_study_date': DateTime.now().toIso8601String(),
        };
      } else {
        progress = jsonDecode(progressJson);
        progress['total_score'] =
            (progress['total_score'] ?? 0) + (isCorrect ? 1 : 0);
        progress['correct_answers'] =
            (progress['correct_answers'] ?? 0) + (isCorrect ? 1 : 0);
        progress['wrong_answers'] =
            (progress['wrong_answers'] ?? 0) + (isCorrect ? 0 : 1);
        progress['last_study_date'] = DateTime.now().toIso8601String();
      }

      await prefs.setString(progressKey, jsonEncode(progress));
    } catch (e) {
      throw ApiException('Failed to save quiz result: ${e.toString()}');
    }
  }

  /// Get user progress for a topic from local storage
  Future<Map<String, dynamic>?> getUserProgress(
    String topic,
    String level,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressKey = 'user_progress_${topic}_$level';
      final progressJson = prefs.getString(progressKey);

      if (progressJson == null) return null;

      return jsonDecode(progressJson) as Map<String, dynamic>;
    } catch (e) {
      throw ApiException('Failed to get progress: ${e.toString()}');
    }
  }

  /// Enrich vocabulary word with Gemini API (migrated from Groq)
  /// Returns artikel and two example sentences
  Future<Map<String, String>> enrichVocabulary(String word) async {
    try {
      const anonKey =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdvaHJ4ZWhucmVvaGxqZ3N4bGlnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc5NjM2MDQsImV4cCI6MjA4MzUzOTYwNH0.OrIQIoxV2-9jUK2fNvv-scTuejetftm1RISB1bEZwl4';
      const url =
          'https://gohrxehnreohljgsxlig.supabase.co/functions/v1/vocabulary-enricher';

      final httpResponse = await http
          .post(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $anonKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'word': word}),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw ApiException('Timeout - lütfen tekrar deneyin.');
            },
          );

      if (httpResponse.statusCode != 200) {
        throw ApiException('Sunucu hatası: ${httpResponse.statusCode}');
      }

      final data = jsonDecode(httpResponse.body) as Map<String, dynamic>;
      return {
        'word': data['word'] as String,
        'artikel': data['artikel'] as String,
        'example1': data['example1'] as String,
        'example2': data['example2'] as String,
      };
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Bağlantı hatası: ${e.toString()}');
    }
  }

  /// Validate word and suggest corrections
  /// Returns isCorrect and suggestions list
  Future<Map<String, dynamic>> validateAndSuggestWord(String word) async {
    try {
      const anonKey =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdvaHJ4ZWhucmVvaGxqZ3N4bGlnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc5NjM2MDQsImV4cCI6MjA4MzUzOTYwNH0.OrIQIoxV2-9jUK2fNvv-scTuejetftm1RISB1bEZwl4';
      const url =
          'https://gohrxehnreohljgsxlig.supabase.co/functions/v1/vocabulary-validator';

      final httpResponse = await http
          .post(
            Uri.parse(url),
            headers: {
              'Authorization': 'Bearer $anonKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'word': word}),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw ApiException('Timeout - lütfen tekrar deneyin.');
            },
          );

      if (httpResponse.statusCode != 200) {
        throw ApiException('Sunucu hatası: ${httpResponse.statusCode}');
      }

      final data = jsonDecode(httpResponse.body) as Map<String, dynamic>;
      return {
        'isCorrect': data['isCorrect'] as bool,
        'suggestions': data['suggestions'] as List<dynamic>?,
      };
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Bağlantı hatası: ${e.toString()}');
    }
  }
}
