import 'package:flutter_test/flutter_test.dart';
import 'package:uaivozes/src/credit_ledger.dart';

CreditEvent example(int day, {String? id, int characters = 25}) => CreditEvent(
  id: id ?? 'id$day',
  createdAt: DateTime(2026, 10, day, 9),
  characters: characters,
  model: CreditEstimator.defaultModel,
  baseEstimate: CreditEstimator.baseEstimate(characters),
);

void main() {
  test('contagem Unicode não confunde emoji com um único code unit', () {
    expect(CreditEstimator.characterCount('Oi 😀'), 4);
    expect(CreditEstimator.baseEstimate(42), 42);
    expect(CreditEstimator.baseEstimate(42, model: 'outro_modelo'), isNull);
    expect(CreditEstimator.baseEstimate(-1), isNull);
  });
  test('histórico preserva só metadados, não texto ou chave', () {
    final ledger = CreditLedger([example(2), example(3)]);
    final raw = ledger.encode();
    expect(raw, isNot(contains('minha chave')));
    final restored = CreditLedger.fromJson(raw);
    expect(restored.events.length, 2);
    expect(restored.events.first.createdAt.day, 3);
    expect(restored.forMonth(DateTime(2026, 11)), isEmpty);
    expect(restored.forMonth(DateTime(2026, 10)).length, 2);
  });
  test('entrada duplicada não conta duas vezes', () {
    final ledger = CreditLedger();
    ledger.add(example(2));
    ledger.add(example(3, id: 'id2'));
    expect(ledger.events.length, 1);
  });
  test('limite de registros é 60 e ordem é decrescente', () {
    final ledger = CreditLedger();
    for (var index = 0; index < 80; index++) {
      ledger.add(CreditEvent(id: 'evt$index',
        createdAt: DateTime(2026, 10, 1).add(Duration(minutes: index)),
        characters: index + 1, model: CreditEstimator.defaultModel));
    }
    expect(ledger.events.length, 60);
    expect(ledger.events.first.id, 'evt79');
    expect(ledger.events.last.id, 'evt20');
  });
  test('JSON malformado ignora entradas erradas sem quebrar o app', () {
    expect(CreditLedger.fromJson('not json').events, isEmpty);
    expect(CreditLedger.fromJson('[{"id":"a","characters":-3}]').events, isEmpty);
    expect(CreditLedger.fromJson('null').events, isEmpty);
    expect(CreditLedger.fromJson('[{"1":2}, {"id":"a","createdAt":"2026-10-15T10:00:00Z","characters":10,"model":"eleven_multilingual_v2"}]').events.length, 1);
  });
  test('alertas usam somente razão válida de consumo oficial', () {
    expect(CreditWarning.percentThreshold(null, 100), isNull);
    expect(CreditWarning.percentThreshold(40, 100), isNull);
    expect(CreditWarning.percentThreshold(50, 100), 50);
    expect(CreditWarning.percentThreshold(80, 100), 80);
    expect(CreditWarning.percentThreshold(95, 100), 95);
    expect(CreditWarning.percentThreshold(130, 100), 95);
    expect(CreditWarning.percentThreshold(2, 0), isNull);
  });
}
