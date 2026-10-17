import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uaivozes/src/android_speech.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Idioma brasileiro e alternativas sem vincular chave API', () {
    expect(AndroidSpeech.languageTag('pt'), 'pt-BR');
    expect(AndroidSpeech.languageTag('es'), 'es-ES');
    expect(AndroidSpeech.languageTag('all'), 'pt-BR');
  });

  test('Leitura nativa nao invoca endpoint de TTS ElevenLabs', () async {
    final messages = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(AndroidSpeech.platform, (call) async {
      messages.add(call);
      return true;
    });
    var finished = 0;
    var failed = 0;
    final speech = AndroidSpeech(
      onFinished: () => finished++, onFailed: () => failed++);
    await speech.speak('Teste gratuito', language: 'pt');
    await speech.stop();
    expect(messages.map((item) => item.method), ['speak', 'stop']);
    expect((messages.first.arguments as Map)['language'], 'pt-BR');
    expect((messages.first.arguments as Map)['text'], 'Teste gratuito');
    expect(finished, 0);
    expect(failed, 0);
    speech.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(AndroidSpeech.platform, null);
  });
}
