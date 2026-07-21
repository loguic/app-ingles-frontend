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
                  'ipa': 'həˈloʊ',
                  'audio_asset': 'audio/a1_u1_l1_hello_us.wav',
                },
              ],
            },
          ],
        },
      ],
    });

    final conversation = lesson.conversations.single;
    expect(conversation.id, 'a1-u1-l1-c1');
    expect(conversation.title, 'Meeting someone');
    expect(conversation.context, 'Greet someone and introduce yourself.');
    expect(conversation.mode, 'guided');
    expect(conversation.startTurnId, isNull);
    expect(conversation.turns, hasLength(2));
    expect(conversation.initialTurn, same(conversation.turns.first));

    expect(conversation.turns.first.isPartner, isTrue);
    expect(conversation.turns.first.isLearner, isFalse);
    expect(conversation.turns.first.nextTurnId, isNull);
    expect(conversation.turns.first.choices, isEmpty);

    final learnerTurn = conversation.turns.last;
    expect(learnerTurn.isLearner, isTrue);
    expect(learnerTurn.pronunciations, hasLength(1));
    expect(learnerTurn.pronunciations.single.locale, 'en-US');
    expect(
      learnerTurn.pronunciations.single.audioAsset,
      'audio/a1_u1_l1_hello_us.wav',
    );
  });

  test('parses branching conversations with stable graph references', () {
    final conversation = Conversation.fromJson({
      'id': 'a1-u1-l1-c2',
      'title': 'How are you?',
      'mode': 'branching',
      'start_turn_id': 'partner-start',
      'turns': [
        {
          'id': 'partner-start',
          'speaker': 'partner',
          'en': 'Hello! How are you?',
          'next_turn_id': 'learner-choice',
        },
        {
          'id': 'learner-choice',
          'speaker': 'learner',
          'en': 'Choose your answer.',
          'choices': [
            {
              'id': 'choice-fine',
              'en': "I'm fine, thank you.",
              'es': 'Estoy bien, gracias.',
              'next_turn_id': 'partner-fine',
              'pronunciations': [
                {
                  'locale': 'en-GB',
                  'ipa': 'aɪm faɪn',
                  'audio_asset': 'audio/fine-uk.wav',
                },
              ],
            },
            {
              'id': 'choice-tired',
              'en': "I'm tired today.",
              'next_turn_id': 'partner-tired',
            },
          ],
        },
        {
          'id': 'partner-fine',
          'speaker': 'partner',
          'en': 'Great!',
          'next_turn_id': 'learner-end',
        },
        {
          'id': 'partner-tired',
          'speaker': 'partner',
          'en': 'I hope you rest.',
          'next_turn_id': 'learner-end',
        },
        {'id': 'learner-end', 'speaker': 'learner', 'en': 'Thank you.'},
      ],
    });

    expect(conversation.mode, 'branching');
    expect(conversation.startTurnId, 'partner-start');
    expect(conversation.initialTurn?.id, 'partner-start');
    expect(conversation.turnById('missing-turn'), isNull);

    final partnerStart = conversation.turnById('partner-start')!;
    expect(partnerStart.nextTurnId, 'learner-choice');

    final learnerChoice = conversation.turnById('learner-choice')!;
    expect(learnerChoice.hasChoices, isTrue);
    expect(learnerChoice.choices, hasLength(2));

    final fineChoice = learnerChoice.choices.first;
    expect(fineChoice.id, 'choice-fine');
    expect(fineChoice.es, 'Estoy bien, gracias.');
    expect(fineChoice.nextTurnId, 'partner-fine');
    expect(fineChoice.pronunciations.single.locale, 'en-GB');
    expect(fineChoice.pronunciations.single.audioAsset, 'audio/fine-uk.wav');

    expect(learnerChoice.choices.last.nextTurnId, 'partner-tired');
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
