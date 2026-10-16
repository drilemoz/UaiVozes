import 'dart:convert';

import 'package:uaivozes/src/eleven_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('Top 10 encaminha idioma e usa dados reais da API', () async {
    final api = ElevenApi(() async => 'segredo', client: MockClient((request) async {
      expect(request.url.path, '/v1/shared-voices');
      expect(request.url.queryParameters['language'], 'pt');
      expect(request.url.queryParameters['sort'], 'usage_character_count_1y');
      expect(request.url.queryParameters['descriptives'], 'calm');
      expect(request.headers['xi-api-key'], 'segredo');
      return http.Response(jsonEncode({'voices': [
        {'voice_id': 'a', 'name': 'Voz A', 'usage_character_count_1y': 18},
      ]}), 200);
    }));
    final voices = await api.topTen(language: 'pt', descriptive: 'calm');
    expect(voices.length, 1);
    expect(voices.first.annualCharacters, 18);
    api.dispose();
  });

  test('Falha 403 não é apresentada como ranking falso', () async {
    final api = ElevenApi(() async => 'segredo', client: MockClient((request) async =>
        http.Response(jsonEncode({'detail': 'forbidden'}), 403)));
    expect(() => api.topTen(language: 'en'),
        throwsA(isA<ElevenApiException>()));
    api.dispose();
  });

  test('Não gera áudio sem texto', () async {
    final api = ElevenApi(() async => 'segredo', client: MockClient((request) async {
      fail('A API não deveria ser chamada para texto vazio');
    }));
    expect(() => api.synthesize(voiceId: 'v', text: ''), throwsA(isA<ElevenApiException>()));
    api.dispose();
  });
}
