import 'dart:convert';
import 'dart:typed_data';

import 'package:uaivozes/src/eleven_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('Top 10 encaminha idioma e usa dados reais da API', () async {
    final api = ElevenApi(() async => 'segredo', client: MockClient((request) async {
      expect(request.url.path, '/v1/shared-voices');
      expect(request.url.queryParameters['language'], 'pt');
      expect(request.url.queryParameters['locale'], 'pt-BR');
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

  test('Testar chave candidata não usa a chave persistida', () async {
    var reads = 0;
    final api = ElevenApi(() async { reads++; return 'chave_persistida'; },
      client: MockClient((request) async {
        expect(request.headers['xi-api-key'], 'chave_teste');
        return http.Response(jsonEncode({'tier': 'free', 'character_count': 0, 'character_limit': 10000}), 200);
      }));
    final result = await api.checkCandidateKey('chave_teste');
    expect(result.tier, 'free');
    expect(reads, 0);
    api.dispose();
  });

  test('Falha 403 não é apresentada como ranking falso', () async {
    final api = ElevenApi(() async => 'segredo', client: MockClient((request) async =>
        http.Response(jsonEncode({'detail': 'forbidden'}), 403)));
    expect(() => api.topTen(language: 'en'),
        throwsA(isA<ElevenApiException>()));
    api.dispose();
  });

  test('TTS identifica HTTP 422 e não repete chamada cobrável', () async {
    var calls = 0;
    final api = ElevenApi(() async => 'chave_privada', client: MockClient((request) async {
      calls++;
      return http.Response(jsonEncode({'detail': {
        'status': 'voice_not_found',
        'message': 'chave_privada texto sensível',
      }}), 422);
    }));
    try {
      await api.synthesize(voiceId: 'voz', text: 'teste');
      fail('Esperada falha HTTP 422');
    } on ElevenApiException catch (e) {
      expect(e.statusCode, 422);
      expect(e.reason, 'voice_not_found');
      expect(e.toString(), isNot(contains('sensível')));
      expect(e.toString(), isNot(contains('chave_privada')));
    }
    expect(calls, 1);
    api.dispose();
  });

  test('TTS preserva motivo com resposta UTF-8 declarada', () async {
    var calls = 0;
    final api = ElevenApi(() async => 'segredo', client: MockClient((request) async {
      calls++;
      return http.Response(jsonEncode({'detail': {
        'status': 'voice_not_found', 'message': 'áudio não encontrado',
      }}), 422, headers: {'content-type': 'application/json; charset=utf-8'});
    }));
    await expectLater(api.synthesize(voiceId: 'voz', text: 'teste'),
      throwsA(isA<ElevenApiException>()
        .having((e) => e.statusCode, 'HTTP', 422)
        .having((e) => e.reason, 'motivo', 'voice_not_found')));
    expect(calls, 1);
    api.dispose();
  });

  test('TTS não expõe motivo inesperado nem ecoa texto remoto', () async {
    var calls = 0;
    final api = ElevenApi(() async => 'segredo', client: MockClient((request) async {
      calls++;
      return http.Response(jsonEncode({'detail': {
        'status': 'segredo_usuario', 'message': 'texto privado',
      }}), 422);
    }));
    try {
      await api.synthesize(voiceId: 'voz', text: 'teste');
      fail('Era esperado HTTP 422');
    } on ElevenApiException catch (e) {
      expect(e.statusCode, 422);
      expect(e.reason, isNull);
      expect(e.toString(), isNot(contains('segredo_usuario')));
      expect(e.toString(), isNot(contains('texto privado')));
    }
    expect(calls, 1);
    api.dispose();
  });

  test('TTS mantém HTTP e uma única chamada em resposta inválida', () async {
    var calls = 0;
    final api = ElevenApi(() async => 'segredo', client: MockClient((request) async {
      calls++;
      return http.Response('<html>erro privado</html>', 422);
    }));
    await expectLater(api.synthesize(voiceId: 'voz', text: 'teste'),
      throwsA(isA<ElevenApiException>()
        .having((e) => e.statusCode, 'HTTP', 422)
        .having((e) => e.reason, 'motivo', isNull)));
    expect(calls, 1);
    api.dispose();
  });

  test('TTS aceita MP3 com cabeçalho ID3', () async {
    final api = ElevenApi(() async => 'chave', client: MockClient((request) async {
      expect(request.url.path, '/v1/text-to-speech/voz');
      return http.Response.bytes(Uint8List.fromList([0x49,0x44,0x33,0x03,0x00]), 200);
    }));
    final bytes = await api.synthesize(voiceId: 'voz', text: 'Olá!');
    expect(bytes.length, 5);
    api.dispose();
  });

  test('TTS recusa HTML retornado com HTTP 200 no lugar de MP3', () async {
    final api = ElevenApi(() async => 'chave', client: MockClient((request) async =>
      http.Response('<html>proxy</html>', 200)));
    await expectLater(api.synthesize(voiceId: 'voz', text: 'teste'),
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
