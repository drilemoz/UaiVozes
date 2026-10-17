import 'package:flutter/services.dart';

/// Leitura usando o mecanismo TTS configurado no Android.
/// Nao usa Internet/ElevenLabs pelo aplicativo, nao gera MP3 nem garante voz
/// offline: alguns mecanismos Android exigem instalar dados ou usar rede.
class AndroidSpeech {
  static const platform = MethodChannel('com.drilemoz.uaivozes/android_speech');

  AndroidSpeech({required this.onFinished, required this.onFailed}) {
    platform.setMethodCallHandler(_event);
  }

  final void Function() onFinished;
  final void Function() onFailed;

  Future<void> _event(MethodCall call) async {
    if (call.method == 'done' || call.method == 'stopped') onFinished();
    if (call.method == 'failure') onFailed();
  }

  static String languageTag(String language) => switch (language) {
    'pt' => 'pt-BR', 'en' => 'en-US', 'es' => 'es-ES',
    'fr' => 'fr-FR', 'de' => 'de-DE', 'it' => 'it-IT',
    'ja' => 'ja-JP', 'hi' => 'hi-IN',
    'all' => 'pt-BR',
    _ => language.contains('-') ? language : 'pt-BR',
  };

  Future<void> speak(String text, {required String language}) async {
    await platform.invokeMethod<bool>('speak', {
      'text': text,
      'language': languageTag(language),
    });
  }

  Future<void> stop() async {
    await platform.invokeMethod<bool>('stop');
  }

  void dispose() {
    platform.setMethodCallHandler(null);
  }
}
