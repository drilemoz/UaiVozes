import 'package:flutter_test/flutter_test.dart';
import 'package:eleven/src/models.dart';

void main() {
  test('Voz da conta possui metadados', () {
    final v = Voice.fromJson({
      'voice_id': 'abc', 'name': 'Teste',
      'labels': {'accent': 'brazilian', 'use_case': 'narrative_story'},
    });
    expect(v.id, 'abc');
    expect(v.accent, 'brazilian');
    expect(v.useCase, 'narrative_story');
  });

  test('Voz do ranking tem dono público e uso real', () {
    final v = Voice.fromJson({
      'voice_id': 'id', 'name': 'Biblioteca',
      'public_owner_id': 'owner', 'usage_character_count_1y': 1234,
    });
    expect(v.publicOwnerId, 'owner');
    expect(v.annualCharacters, 1234);
  });

  test('Biblioteca ignora registros inválidos', () {
    expect(decodeAudioRecords('não é JSON'), isEmpty);
    expect(decodeAudioRecords('[{"id":"a","path":"/data/test.mp3"}]'), hasLength(1));
    expect(decodeAudioRecords('[{"id":"a","path":""}]'), isEmpty);
  });
}
