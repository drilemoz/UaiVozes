import 'package:flutter_test/flutter_test.dart';
import 'package:uaivozes/src/key_transfer.dart';

void main() {
  test('Importação aceita chave em ENV e TEXTO', () {
    expect(parseKeyFile('ELEVENLABS_API_KEY=sk_teste123\n'), 'sk_teste123');
    expect(parseKeyFile('  sk_teste123  '), 'sk_teste123');
    expect(parseKeyFile('export ELEVENLABS_API_KEY="sk_teste123"'), 'sk_teste123');
  });
  test('Importação recusa múltiplas linhas e nomes estranhos', () {
    expect(() => parseKeyFile('foo=123'), throwsFormatException);
    expect(() => parseKeyFile('a\nb'), throwsFormatException);
    expect(() => parseKeyFile('ELEVENLABS_API_KEY='), throwsFormatException);
    expect(() => parseKeyFile('sk ch ave'), throwsFormatException);
  });
}
