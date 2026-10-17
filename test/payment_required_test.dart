import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uaivozes/src/eleven_api.dart';
import 'package:uaivozes/src/generation_failure.dart';

void main() {
  test('HTTP 402 com detail.status payment_required entra no diagnóstico', () async {
    var calls = 0;
    final api = ElevenApi(() async => 'segredo', client: MockClient((request) async {
      calls++;
      return http.Response(jsonEncode({'detail': {
        'status': 'payment_required', 'message': 'texto confidencial'}}), 402);
    }));
    await expectLater(api.synthesize(voiceId: 'voz', text: 'teste'),
      throwsA(isA<ElevenApiException>()
        .having((e) => e.statusCode, 'HTTP', 402)
        .having((e) => e.reason, 'motivo', 'payment_required')
        .having((e) => e.toString(), 'texto', isNot(contains('confidencial')))));
    expect(calls, 1);
    api.dispose();
  });

  test('code não permitido continua sem motivo mesmo com status permitido', () async {
    final api = ElevenApi(() async => 'segredo', client: MockClient((request) async =>
      http.Response(jsonEncode({'detail': {'code': 'privado',
        'status': 'payment_required'}}), 402)));
    await expectLater(api.synthesize(voiceId: 'voz', text: 'teste'),
      throwsA(isA<ElevenApiException>().having((e) => e.reason, 'motivo', isNull)));
    api.dispose();
  });

  test('plano Free + HTTP 402 sem motivo cita biblioteca sem afirmar causa', () {
    const error = ElevenApiException('texto privado', 402);
    final failure = GenerationFailure.classify(error,
      audioReceived: false, audioSaved: false, plan: 'free');
    expect(failure.message, contains('biblioteca pública'));
    expect(failure.message, contains('motivo exato não foi confirmado'));
    expect(failure.nextAction, contains('voz padrão'));
    expect(failure.report, isNot(contains('texto privado')));
  });

  test('payment_required no plano Free explica a restrição da biblioteca', () {
    const error = ElevenApiException('segredo', 402, 'payment_required');
    final failure = GenerationFailure.classify(error,
      audioReceived: false, audioSaved: false, plan: 'Free');
    expect(failure.message, contains('plano Free'));
    expect(failure.diagnostic, contains('payment_required'));
    expect(failure.report, isNot(contains('segredo')));
  });

  test('plano pago mantém mensagem genérica de 402', () {
    const error = ElevenApiException('x', 402);
    final failure = GenerationFailure.classify(error,
      audioReceived: false, audioSaved: false, plan: 'creator');
    expect(failure.message, isNot(contains('biblioteca pública')));
    expect(failure.nextAction, contains('Créditos e consumo'));
  });
}
