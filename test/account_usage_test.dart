import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uaivozes/src/eleven_api.dart';

void main() {
  test('assinatura converte campos reais e preserva ausência de créditos', () {
    final sub = Subscription.fromJson({
      'tier': 'free', 'status': 'active',
      'character_count': 1750, 'character_limit': 10000,
      'voice_slots_used': 2, 'voice_limit': 10,
      'next_character_count_reset_unix': 1790000000,
      'billing_period': 'monthly_period',
      'current_overage': {'amount': '0', 'currency': 'usd'},
    });
    expect(sub.tier, 'free');
    expect(sub.used, 1750);
    expect(sub.limit, 10000);
    expect(sub.remaining, 8250);
    expect(sub.usageRatio, closeTo(0.175, 0.0001));
    expect(sub.resetAt, isNotNull);
    expect(sub.voiceSlotsUsed, 2);
    expect(sub.overageAmount, '0');
  });

  test('assinatura vazia não inventa saldos, datas ou vagas', () {
    final sub = Subscription.fromJson({'tier': 'trial'});
    expect(sub.remaining, isNull);
    expect(sub.usageRatio, isNull);
    expect(sub.resetAt, isNull);
    expect(sub.voiceLimit, isNull);
  });

  test('contagem acima do limite satura indicador e saldo não fica negativo', () {
    final sub = Subscription.fromJson({
      'tier': 'creator', 'character_count': 11000, 'character_limit': 10000,
    });
    expect(sub.remaining, 0);
    expect(sub.usageRatio, 1.0);
  });

  test('API consulta /v1/user sem enviar segredo como parâmetro de URL', () async {
    final api = ElevenApi(() async => 'token-privado',
      client: MockClient((req) async {
        expect(req.url.path, '/v1/user');
        expect(req.url.query, isEmpty);
        expect(req.headers['xi-api-key'], 'token-privado');
        return http.Response(jsonEncode({
          'first_name': 'Pessoa', 'user_id': 'uid', 'workspace_id': 'w123',
          'seat_type': 'workspace_member',
          'subscription': {'tier': 'starter', 'character_count': 3},
        }), 200);
      }));
    final account = await api.getAccount();
    expect(account.firstName, 'Pessoa');
    expect(account.workspaceId, 'w123');
    expect(account.subscription?.used, 3);
    api.dispose();
  });

  test('bloqueio de User Read não é tratado como cadastro inexistente', () async {
    final api = ElevenApi(() async => 'segredo',
      client: MockClient((request) async => http.Response('forbidden', 403)));
    await expectLater(api.getAccount(), throwsA(isA<ElevenApiException>()));
    api.dispose();
  });
}
