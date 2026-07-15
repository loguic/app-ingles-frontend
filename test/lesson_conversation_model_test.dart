import 'package:app_ingles/models/lesson.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses guided conversations and reuses pronunciation models', () {
    final lesson = Lesson.fromJson({
      'id': 'a1-u1-l1',
      'title': 'Hello / Goodbye',
      'conversations': [
        {
          'id': 'a1-u1-l1-c1',
          'title': 'Meeting someone',
          'context': 'Greet someone and introduce yourself.',
          'mode': 'guided',
          'turns': [
            {
              'id': 'a1-u1-l1-c1-t1',
              'speaker': 'partner',
              'en': 'Hello! What is your name?',
              'es': '¡Hola! ¿Cómo te llamas?',
            },
            {
              'id': 'a1-u1-l1-c1-t2',
              'speaker': 'learner',
              'en': 'Hello, I am John.',
              'es': 'Hola, soy John.',
              'pronunciations': [
                {
                  'locale': 'en-US',
                  'ipa': '/həˈloʊ, aɪ æm dʒɑːn/',
                  'audio_asset': 'audio/a1_u1_l1_hello_us.wav',
                },
              ],
            },
          ],
        },
      ],
    });

    expect(lesson.conversations, hasLength(1));

    final conversation = lesson.conversations.single;
    expect(conversation.id, 'a1-u1-l1-c1');
    expect(conversation.title, 'Meeting someone');
    expect(conversation.context, 'Greet someone and introduce yourself.');
    expect(conversation.mode, 'guided');
    expect(conversation.turns, hasLength(2));

    expect(conversation.turns.first.isPartner, isTrue);
    expect(conversation.turns.first.isLearner, isFalse);

    final learnerTurn = conversation.turns.last;
    expect(learnerTurn.isLearner, isTrue);
    expect(learnerTurn.pronunciations, hasLength(1));
    expect(learnerTurn.pronunciations.single.locale, 'en-US');
    expect(
      learnerTurn.pronunciations.single.audioAsset,
      'audio/a1_u1_l1_hello_us.wav',
    );
  });

  test('keeps lessons without conversations backward compatible', () {
    final lesson = Lesson.fromJson({
      'id': 'legacy-lesson',
      'title': 'Legacy lesson',
    });

    expect(lesson.conversations, isEmpty);
    expect(lesson.examples, isEmpty);
    expect(lesson.exercises, isEmpty);
  });
}
