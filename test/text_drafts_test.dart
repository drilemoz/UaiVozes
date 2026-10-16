import 'package:flutter_test/flutter_test.dart';
import 'package:uaivozes/src/text_drafts.dart';

void main() {
  test('Rascunhos mantêm título, conteúdo e data', () {
    final item = TextDraft(id:'1', title:'Teste', content:'Olá', savedAt:DateTime(2026,10,16));
    final restored = TextDrafts.decode(TextDrafts.encode([item]));
    expect(restored.single.content, 'Olá');
    expect(restored.single.title, 'Teste');
  });
  test('JSON inválido é ignorado sem quebrar inicialização', () {
    expect(TextDrafts.decode('{'), isEmpty);
    expect(TextDrafts.decode('[{"id":"1","title":"a","content":""}]'), isEmpty);
  });
  test('Divide texto longo sem quebrar pares Unicode nem perder palavras', () {
    final text = List.generate(1550, (i) => 'Frase🙂$i').join(' ');
    final parts = TextDrafts.split(text);
    expect(parts.length, greaterThan(1));
    for (final item in parts) { expect(item.runes.length, lessThanOrEqualTo(5000)); }
    expect(parts.join(' '), text);
  });
  test('Limite de persistência impede crescimento ilimitado', () {
    final entries = List.generate(30, (i) => TextDraft(
      id:'$i', title:'t$i', content:'texto', savedAt:DateTime(2026)));
    expect(TextDrafts.decode(TextDrafts.encode(entries)).length, 20);
  });
}
