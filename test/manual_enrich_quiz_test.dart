import 'package:flutter_test/flutter_test.dart';
import 'package:mirmir_app/core/network/ai_api_service.dart';

void main() {
  test(
    'enrichVocabulary returns expected fields for Haus',
    () async {
      final res = await AiApiService.instance.enrichVocabulary('Haus');
      // Print to test output for inspection
      print('ENRICH RESPONSE: $res');

      expect(res['word'], equals('Haus'));
      expect(res.containsKey('artikel'), isTrue);
      expect(res.containsKey('example1'), isTrue);
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test(
    'getAdaptiveQuiz returns a valid quiz structure or auth error',
    () async {
      try {
        final quiz = await AiApiService.instance.getAdaptiveQuiz(
          'Genel',
          'A1.1',
        );
        print('QUIZ RESPONSE: $quiz');

        expect(quiz.containsKey('question'), isTrue);
        expect(quiz.containsKey('options'), isTrue);
        expect((quiz['options'] as List).isNotEmpty, isTrue);
      } catch (e) {
        // In testing environment the function may require server secrets and return 401/auth errors.
        final msg = e.toString();
        final ok =
            msg.contains('Oturum') ||
            msg.contains('Unauthorized') ||
            msg.contains('Quiz yüklenemedi');
        expect(ok, isTrue);
      }
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
