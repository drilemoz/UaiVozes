import 'package:flutter_test/flutter_test.dart';
import 'package:uaivozes/src/models.dart';
import 'package:uaivozes/src/voice_access.dart';

void main() {
  test('Exclusão explícita de usuários Free indica bloqueio', () {
    final voice = Voice.fromJson({'voice_id':'a','name':'A', 'free_users_allowed': false});
    expect(evaluateVoiceAccess(voice,'free').state, VoiceAccess.restricted);
  });
  test('Plano listado explicitamente não equivale a acesso confirmado', () {
    final voice = Voice.fromJson({'voice_id':'b','name':'B', 'available_for_tiers':['creator','enterprise']});
    expect(evaluateVoiceAccess(voice,'free').isRestricted, true);
    expect(evaluateVoiceAccess(voice,'creator').state, VoiceAccess.unknown);
  });
  test('Sem dados não inventa restrição ou acesso liberado', () {
    final voice = Voice.fromJson({'voice_id':'c','name':'C'});
    expect(evaluateVoiceAccess(voice,'free').state, VoiceAccess.unknown);
  });
  test('Tarifa é informação separada e sem multiplicador inventado', () {
    final voice = Voice.fromJson({'voice_id':'d','name':'D','rate':0.05});
    expect(voice.hasCustomRate, true);
    expect(evaluateVoiceAccess(voice,'free').specialRate, true);
    expect(Voice.fromJson(voice.toJson()).freeUsersAllowed, isNull);
  });
  test('Reidratação preserva metadados de restrição', () {
    final voice = Voice.fromJson({'voice_id':'d','name':'D','sharing':{'free_users_allowed':false}});
    final restored = Voice.fromJson(voice.toJson());
    expect(evaluateVoiceAccess(restored,'free').isRestricted, true);
  });
}
