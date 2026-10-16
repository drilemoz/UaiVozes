import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uaivozes/src/eleven_api.dart';
import 'package:uaivozes/src/models.dart';

void main() {
  test('DELETE de voz usa endpoint correto uma vez e exige status ok', () async {
    var calls = 0;
    final api = ElevenApi(() async => 'chave_teste', client: MockClient((request) async {
      calls++;
      expect(request.method, 'DELETE');
      expect(request.url.path, '/v1/voices/voz-test');
      expect(request.headers['xi-api-key'], 'chave_teste');
      return http.Response(jsonEncode({'status':'ok'}),200);
    }));
    await api.deleteVoice('voz-test');
    expect(calls,1);
    api.dispose();
  });

  test('DELETE inconclusivo não é confundido com remoção confirmada', () async {
    var calls = 0;
    final api = ElevenApi(() async => 'chave', client: MockClient((request) async {
      calls++;
      return http.Response(jsonEncode({'status':'pending'}),200);
    }));
    await expectLater(api.deleteVoice('voz-test'),throwsA(isA<ElevenApiException>()));
    expect(calls,1);
    api.dispose();
  });

  test('DELETE proibido não é repetido nem ecoa texto da API', () async {
    var calls = 0;
    final api = ElevenApi(() async => 'chave_teste', client: MockClient((request) async {
      calls++;
      return http.Response(jsonEncode({'detail': {
        'code': 'missing_permissions', 'message':'dado sigiloso'
      }}),403);
    }));
    try {
      await api.deleteVoice('voz-test');
      fail('Era esperada a proibição.');
    } on ElevenApiException catch (e) {
      expect(e.statusCode, 403);
      expect(e.toString(), isNot(contains('sigiloso')));
    }
    expect(calls,1);
    api.dispose();
  });

  test('Voz padrão ou legada não é removível pelo aplicativo', () {
    expect(Voice.fromJson({'voice_id':'1','name':'A','category':'premade'})
      .canRemoveFromAccount,false);
    expect(Voice.fromJson({'voice_id':'2','name':'B','is_legacy':true})
      .canRemoveFromAccount,false);
    expect(Voice.fromJson({'voice_id':'3','name':'C','category':'cloned'})
      .canRemoveFromAccount,true);
  });
}
