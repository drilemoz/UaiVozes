import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uaivozes/src/eleven_api.dart';
import 'package:uaivozes/src/models.dart';
import 'package:uaivozes/src/voice_browse_cache.dart';

void main() {
  test('Busca da conta envia filtros reais ao endpoint v2', () async {
    final api = ElevenApi(() async => 'test-secret', client: MockClient((request) async {
      expect(request.url.path, '/v2/voices');
      final query = request.url.queryParameters;
      expect(query['language'], 'pt');
      expect(query['search'], 'voz natural');
      expect(query['gender'], 'female');
      expect(query['age'], 'young');
      expect(query['accent'], 'brazilian');
      expect(query['use_cases'], 'narrative_story');
      expect(query['page_size'], '30');
      expect(query['include_total_count'], 'false');
      expect(request.headers['xi-api-key'], 'test-secret');
      return http.Response(jsonEncode({
        'voices': [{'voice_id': 'v-pt', 'name': 'Teste', 'labels': {'accent': 'brazilian'}}],
        'has_more': true,
        'next_page_token': 'page:2',
      }), 200);
    }));
    final page = await api.voices(language: 'pt', search: ' voz natural ',
      gender: 'female', age: 'young', accent: 'brazilian',
      useCase: 'narrative_story');
    expect(page.voices.single.id, 'v-pt');
    expect(page.nextToken, 'page:2');
    api.dispose();
  });

  test('Paginação não repassa filtros all e termina quando has_more é falso', () async {
    final api = ElevenApi(() async => 'dummy', client: MockClient((request) async {
      final query = request.url.queryParameters;
      expect(query['next_page_token'], 'token-exato');
      expect(query.containsKey('language'), false);
      expect(query.containsKey('accent'), false);
      expect(query.containsKey('use_cases'), false);
      return http.Response(jsonEncode({
        'voices': [{'voice_id': 'b', 'name': 'Segunda'}],
        'has_more': false,
        'next_page_token': 'nao-usar',
      }), 200);
    }));
    final page = await api.voices(token: 'token-exato',
      language: 'all', accent: 'all', useCase: 'all');
    expect(page.voices.single.name, 'Segunda');
    expect(page.nextToken, isNull);
    api.dispose();
  });

  test('Verificar detalhes é GET isolado, sem POST TTS e sem apresentar acesso inventado', () async {
    var calls = 0;
    final api = ElevenApi(() async => 'key-test', client: MockClient((request) async {
      calls++;
      expect(request.method, 'GET');
      expect(request.url.path, '/v1/voices/voz-1');
      return http.Response(jsonEncode({
        'voice_id':'voz-1', 'name':'Detalhe',
        'available_for_tiers':['creator','enterprise'],
        'sharing':{'free_users_allowed':false},
      }),200,headers:{'content-type':'application/json; charset=utf-8'});
    }));
    final detail = await api.voiceDetail('voz-1');
    expect(detail.availableForTiers, contains('creator'));
    expect(detail.freeUsersAllowed,false);
    expect(calls,1);
    api.dispose();
  });

  test('Cache de vozes expira em três minutos, sem persistência', () {
    var clock = DateTime.utc(2026, 10, 16, 8);
    final cache = VoiceBrowseCache(clock: () => clock);
    final result = VoicePage([const Voice(id: '1', name: 'Nome')], null);
    cache.put('pt', result);
    expect(cache.get('pt')?.voices.single.id, '1');
    clock = clock.add(const Duration(minutes: 3));
    expect(cache.get('pt'), isNull);
    expect(cache.count, 0);
  });

  test('Cache LRU tem limite de dez páginas e pode ser zerado na troca de chave', () {
    final cache = VoiceBrowseCache();
    final result = VoicePage(const [], null);
    for (var i = 0; i < 10; i++) { cache.put('page:$i', result); }
    cache.get('page:0');
    cache.put('page:10', result);
    expect(cache.get('page:1'), isNull);
    expect(cache.get('page:0'), isNotNull);
    expect(cache.count, 10);
    cache.clear();
    expect(cache.count, 0);
  });

  test('Chave do cache distingue pesquisa, idioma, ranking, filtros e páginas', () {
    final base = voiceBrowseKey(language: 'pt', ranking: false);
    expect(voiceBrowseKey(language: 'en', ranking: false), isNot(base));
    expect(voiceBrowseKey(language: 'pt', ranking: true), isNot(base));
    expect(voiceBrowseKey(language: 'pt', ranking: false, search: 'voz'), isNot(base));
    expect(voiceBrowseKey(language: 'pt', ranking: false, gender: 'female'), isNot(base));
    expect(voiceBrowseKey(language: 'pt', ranking: false, token: '2'), isNot(base));
    expect(voiceBrowseKey(language: 'pt', ranking: false, search: ' A '),
      voiceBrowseKey(language: 'pt', ranking: false, search: 'a'));
  });

  test('Minhas vozes usa voice_type no endpoint oficial v2', () async {
    var requests = 0;
    final api = ElevenApi(() async => 'key-test', client: MockClient((request) async {
      requests++;
      expect(request.method, 'GET');
      expect(request.url.path, '/v2/voices');
      expect(request.url.queryParameters['voice_type'], 'saved');
      return http.Response(jsonEncode({'voices':[], 'has_more':false}), 200);
    }));
    await api.voices(voiceType: 'saved');
    expect(requests, 1);
    api.dispose();
  });

  test('Top 10 encaminha filtros documentados ao catálogo público', () async {
    final api = ElevenApi(() async => 'key-test', client: MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/v1/shared-voices');
      expect(request.url.queryParameters['sort'], 'usage_character_count_1y');
      expect(request.url.queryParameters['gender'], 'female');
      expect(request.url.queryParameters['age'], 'young');
      expect(request.url.queryParameters['accent'], 'brazilian');
      expect(request.url.queryParameters['category'], 'professional');
      expect(request.url.queryParameters['use_cases'], 'narrative_story');
      return http.Response(jsonEncode({'voices':[]}),200);
    }));
    await api.topTen(language: 'pt', gender: 'female', age: 'young',
      accent: 'brazilian', sharedCategory: 'professional', useCase: 'narrative_story');
    api.dispose();
  });

  test('Cache distingue categoria pública e tipo de voz salvo', () {
    final base = voiceBrowseKey(language: 'pt', ranking: false);
    expect(voiceBrowseKey(language:'pt', ranking:false, voiceType:'saved'), isNot(base));
    expect(voiceBrowseKey(language:'pt', ranking:true, sharedCategory:'professional'),
      isNot(voiceBrowseKey(language:'pt',ranking:true)));
  });

}

