import 'lesson.dart';

const visualDemoNotice =
    'Demostración visual · Contenido provisional · '
    'No representa el currículo A1 definitivo';

/// Local presentation content for the visual checkpoint only.
/// Contenido local de presentación exclusivo del checkpoint visual.
class VisualDemoContent {
  const VisualDemoContent({
    required this.id,
    required this.title,
    required this.situation,
    required this.objective,
    required this.hint,
    required this.transcript,
    required this.translation,
    required this.pronunciations,
    required this.conversation,
  });

  final String id;
  final String title;
  final String situation;
  final String objective;
  final String hint;
  final String transcript;
  final String translation;
  final List<LessonPronunciation> pronunciations;
  final Conversation conversation;
}

const visualDemoContent = VisualDemoContent(
  id: 'demo-visual-a1-brief-chat',
  title: 'Una charla breve',
  situation: 'Conoces a alguien en una cafetería y escuchas una pregunta.',
  objective: 'Explorar cómo LOGUIC combina escucha, voz y conversación.',
  hint: 'La pregunta busca saber de dónde eres.',
  transcript: 'Where are you from?',
  translation: '¿De dónde eres?',
  pronunciations: [
    LessonPronunciation(
      locale: 'en-US',
      ipa: '/wer ɑr ju frʌm/',
      audioAsset: 'audio/a1_u1_l2_c1_t1_us.wav',
    ),
    LessonPronunciation(
      locale: 'en-GB',
      ipa: '/weə ɑː ju frɒm/',
      audioAsset: 'audio/a1_u1_l2_c1_t1_uk.wav',
    ),
  ],
  conversation: Conversation(
    id: 'demo-visual-a1-conversation',
    title: 'Prueba una respuesta personal',
    context: 'Una interacción breve de demostración, sin evaluación.',
    mode: 'guided',
    audioFirstPolicy: AudioFirstPresentationPolicy(
      primaryPresentation: 'audio',
      audioReplayAllowed: true,
      transcriptInitiallyHidden: true,
      transcriptAccess: 'optional_demo_support',
      transcriptUseInterpretation: 'visual_demo_only',
      transcriptIsAnswerModel: false,
    ),
    turns: [
      ConversationTurn(
        id: 'demo-visual-a1-partner-turn',
        speaker: 'partner',
        en: 'Where are you from?',
        es: '¿De dónde eres?',
        pronunciations: [
          LessonPronunciation(
            locale: 'en-US',
            ipa: '/wer ɑr ju frʌm/',
            audioAsset: 'audio/a1_u1_l2_c1_t1_us.wav',
          ),
          LessonPronunciation(
            locale: 'en-GB',
            ipa: '/weə ɑː ju frɒm/',
            audioAsset: 'audio/a1_u1_l2_c1_t1_uk.wav',
          ),
        ],
        nextTurnId: 'demo-visual-a1-learner-turn',
      ),
      ConversationTurn(
        id: 'demo-visual-a1-learner-turn',
        speaker: 'learner',
        en: 'Responde con un lugar usando tus propias palabras.',
        productionPrompt: LearnerProductionPrompt(
          id: 'demo-visual-a1-response-prompt',
          acceptedModalities: ['voice'],
          primaryModality: 'voice',
          supportLevel: 'anchors',
          visibleSupport: ['I am from…', 'Madrid', 'Mexico'],
          allowFullAnswerModel: false,
        ),
      ),
    ],
  ),
);
