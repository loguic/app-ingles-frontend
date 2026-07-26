import "package:app_ingles/services/speech_recognition_service.dart";
import "package:flutter_test/flutter_test.dart";

class FakeSpeechRecognitionController
    implements SpeechRecognitionController {
  SpeechRecognitionRequest? lastRequest;

  @override
  Future<SpeechRecognitionResult> recognize(
    SpeechRecognitionRequest request,
  ) async {
    lastRequest = request;

    return SpeechRecognitionResult(
      status: SpeechRecognitionStatus.recognized,
      transcript: "My name is John.",
      words: const ["My", "name", "is", "John"],
      languageCode: request.languageCode,
      locale: request.locale,
      userId: request.userId,
      levelId: request.levelId,
      unitId: request.unitId,
      lessonId: request.lessonId,
      conversationId: request.conversationId,
      turnId: request.turnId,
      promptId: request.promptId,
    );
  }
}

void main() {
  test("keeps speech recognition separate from pedagogical evaluation", () {
    const request = SpeechRecognitionRequest(
      audioPath: "/tmp/learner.wav",
      languageCode: "en",
      userId: "demo-user",
      levelId: "A1",
      unitId: "a1-u1",
      lessonId: "a1-u1-l1",
      conversationId: "a1-u1-l1-c3",
      turnId: "a1-u1-l1-c3-t2",
      promptId: "a1-u1-l1-c3-p1",
    );

    const result = SpeechRecognitionResult(
      status: SpeechRecognitionStatus.recognized,
      transcript: "My name is John.",
      words: ["My", "name", "is", "John"],
      languageCode: "en",
      userId: "demo-user",
      levelId: "A1",
      unitId: "a1-u1",
      lessonId: "a1-u1-l1",
      conversationId: "a1-u1-l1-c3",
      turnId: "a1-u1-l1-c3-t2",
      promptId: "a1-u1-l1-c3-p1",
    );

    expect(request.locale, isNull);
    expect(result.status, SpeechRecognitionStatus.recognized);
    expect(result.transcript, "My name is John.");
    expect(result.words, ["My", "name", "is", "John"]);
    expect(result.locale, isNull);
  });
  test("supports a deterministic recognition controller", () async {
    final controller = FakeSpeechRecognitionController();

    const request = SpeechRecognitionRequest(
      audioPath: "/tmp/learner.wav",
      languageCode: "en",
      userId: "demo-user",
      levelId: "A1",
      unitId: "a1-u1",
      lessonId: "a1-u1-l1",
      conversationId: "a1-u1-l1-c3",
      turnId: "a1-u1-l1-c3-t2",
      promptId: "a1-u1-l1-c3-p1",
    );

    final result = await controller.recognize(request);

    expect(controller.lastRequest, same(request));
    expect(result.status, SpeechRecognitionStatus.recognized);
    expect(result.transcript, "My name is John.");
    expect(result.words, ["My", "name", "is", "John"]);
    expect(result.promptId, request.promptId);
    expect(result.turnId, request.turnId);
  });

}
