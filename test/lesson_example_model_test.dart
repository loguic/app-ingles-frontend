import 'package:app_ingles/models/lesson.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a stable lesson example identifier', () {
    final lesson = Lesson.fromJson({
      'id': 'a1-u1-l1',
      'title': 'Hello / Goodbye',
      'examples': [
        {
          'id': 'a1-u1-l1-e1',
          'en': 'Hello, I am John.',
          'es': 'Hola, soy John.',
          'pronunciations': [
            {
              'locale': 'en-US',
              'ipa': 'test ipa',
              'audio_asset': 'audio/test.wav',
            },
          ],
        },
      ],
    });

    final example = lesson.examples.single;

    expect(example.id, 'a1-u1-l1-e1');
    expect(example.en, 'Hello, I am John.');
    expect(example.es, 'Hola, soy John.');
    expect(example.pronunciations.single.locale, 'en-US');
  });
}
