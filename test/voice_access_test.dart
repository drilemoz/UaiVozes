import 'package:flutter_test/flutter_test.dart';
import 'package:uaivozes/src/models.dart';
import 'package:uaivozes/src/voice_access.dart';

void main() {
  test('Tier Free explicitamente listado indica compatibilidade, não gratuidade', () {
    final voice = Voice.fromJson({'voice_id':'a', 'name':'A',
      'available_for_tiers':['free','starter']});
    final info = evaluateVoiceAccess(voice, ' FREE ');
    expect(info.state, VoiceAccess.compatible);
    expect(info.isRestricted, false);
    expect(info.details, contains('não confirma'));
  });
  test('Plano pago listado indica compatibilidade somente para aquele tier', () {
    final voice = Voice.fromJson({'voice_id':'b', 'name':'B',
      'available_for_tiers':['creator','enterprise']});
    expect(evaluateVoiceAccess(voice,'creator').state, VoiceAccess.compatible);
    expect(evaluateVoiceAccess(voice,'free').state, VoiceAccess.restricted);
    expect(evaluateVoiceAccess(voice,'starter').state,
      VoiceAccess.currentTierNotListed);
  });
  test('Plano desconhecido nunca recebe falsa confirmação', () {
    const voice = Voice(id:'c', name:'C', availableForTiers:['creator']);
    for (final tier in <String?>[null,'','desconhecido','unknown']) {
      expect(evaluateVoiceAccess(voice,tier).state, VoiceAccess.unknown);
    }
  });
  test('free_users_allowed sozinho diz respeito a novas adições, não TTS em Minhas vozes', () {
    final voice = Voice.fromJson({'voice_id':'d','name':'D',
      'sharing':{'free_users_allowed':false}});
    expect(evaluateVoiceAccess(voice,'free').state, VoiceAccess.unknown);
    expect(evaluateVoiceAccess(voice,'free').details, contains('novas adições'));
    expect(Voice.fromJson(voice.toJson()).freeUsersAllowed, false);
  });
  test('Biblioteca pública não é compatível com acesso Free via API', () {
    final shared = Voice.fromJson({'voice_id':'e','name':'E',
      'available_for_tiers':['free'],'sharing':{'free_users_allowed':true}});
    expect(evaluateVoiceAccess(shared,'free',publicLibrary:true).state,
      VoiceAccess.restricted);
    expect(evaluateVoiceAccess(shared,'creator',publicLibrary:true).state,
      VoiceAccess.currentTierNotListed);
  });
  test('Metadados insuficientes não são considerados compatíveis', () {
    const voice = Voice(id:'f', name:'F');
    expect(evaluateVoiceAccess(voice,'creator').state, VoiceAccess.unknown);
    expect(evaluateVoiceAccess(voice,'free').state, VoiceAccess.unknown);
  });
  test('Filtro mantém estados exclusivos e separa todos dos restritos', () {
    const compatible = VoiceAccessInfo(VoiceAccess.compatible,'','');
    const denied = VoiceAccessInfo(VoiceAccess.restricted,'','');
    const notListed = VoiceAccessInfo(VoiceAccess.currentTierNotListed,'','');
    const unknown = VoiceAccessInfo(VoiceAccess.unknown,'','');
    final all = [compatible, denied, notListed, unknown];
    expect(all.where((v) => matchesVoiceAccessFilter(VoiceAccessFilter.all,v)).length,4);
    expect(all.where((v) => matchesVoiceAccessFilter(VoiceAccessFilter.compatible,v)).length,1);
    expect(all.where((v) => matchesVoiceAccessFilter(VoiceAccessFilter.restricted,v)).length,2);
    expect(all.where((v) => matchesVoiceAccessFilter(VoiceAccessFilter.unknown,v)).length,1);
  });
  test('Vozes da conta sem restrição explícita são candidatas, não confirmadas', () {
    const unknown = VoiceAccessInfo(VoiceAccess.unknown, 'A confirmar', '');
    const compatible = VoiceAccessInfo(VoiceAccess.compatible, 'Confirmada', '');
    const restricted = VoiceAccessInfo(VoiceAccess.restricted, 'Bloqueada', '');
    expect(matchesVoiceAccessFilter(VoiceAccessFilter.accountCandidates,
      unknown, ownedCatalog: true), isTrue);
    expect(matchesVoiceAccessFilter(VoiceAccessFilter.accountCandidates,
      compatible, ownedCatalog: true), isTrue);
    expect(matchesVoiceAccessFilter(VoiceAccessFilter.accountCandidates,
      restricted, ownedCatalog: true), isFalse);
    expect(matchesVoiceAccessFilter(VoiceAccessFilter.accountCandidates,
      unknown, ownedCatalog: false), isFalse);
    // O filtro estrito nunca classifica 'unknown' como compatível.
    expect(matchesVoiceAccessFilter(VoiceAccessFilter.compatible, unknown), isFalse);
  });

  test('Top 10 público de plano Free permanece bloqueado sem inferir TTS', () {
    const shared = Voice(id: 'shared', name: 'Top', availableForTiers: ['free']);
    expect(evaluateVoiceAccess(shared, 'free', publicLibrary: true).isRestricted, isTrue);
    expect(evaluateVoiceAccess(shared, 'free').isCompatible, isTrue);
  });

  test('Consulta manual pode acrescentar tiers sem perder metadados já mostrados', () {
    const original = Voice(id:'g',name:'Nome original',description:'Resumo',
      style:'calm', previewUrl:'https://example.org/audio.mp3',
      annualCharacters:720, publicOwnerId:'owner');
    const detail = Voice(id:'g',name:'Nome diferente',
      availableForTiers:['creator'],freeUsersAllowed:false,hasCustomRate:true);
    final merged = mergeVoiceAccessMetadata(original,detail);
    expect(merged.name,'Nome original');
    expect(merged.previewUrl,original.previewUrl);
    expect(merged.annualCharacters,720);
    expect(merged.publicOwnerId,'owner');
    expect(merged.freeUsersAllowed,false);
    expect(merged.hasCustomRate,true);
    expect(evaluateVoiceAccess(merged,'creator').isCompatible,true);
  });
  test('Detalhes com outro ID nunca são incorporados à voz', () {
    const original = Voice(id:'h',name:'Original');
    const other = Voice(id:'outro',name:'Falha',availableForTiers:['free']);
    final merged = mergeVoiceAccessMetadata(original,other);
    expect(merged.id,'h');
    expect(evaluateVoiceAccess(merged,'free').state,VoiceAccess.unknown);
  });
  test('Tarifa especial independente de acesso e sem multiplicador inventado', () {
    final voice = Voice.fromJson({'voice_id':'i','name':'I','rate':0.05});
    expect(voice.hasCustomRate,true);
    expect(evaluateVoiceAccess(voice,'free').specialRate,true);
    expect(evaluateVoiceAccess(voice,'free').state,VoiceAccess.unknown);
  });
}
