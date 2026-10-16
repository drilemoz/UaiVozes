import 'package:flutter_test/flutter_test.dart';
import 'package:uaivozes/src/diagnostics.dart';
import 'package:uaivozes/src/eleven_links.dart';
import 'package:uaivozes/src/eleven_api.dart';

void main() {
  test('relatório não serializa exceção com segredo', () {
    final diagnostics = AppDiagnostics.forTest();
    diagnostics.capture('TESTE', Exception('xi-api-key: secreta123 e texto confidencial'));
    final report = diagnostics.report(version: 'teste');
    expect(report, contains('TESTE'));
    expect(report, contains('ERRO'));
    expect(report, isNot(contains('secreta123')));
    expect(report, isNot(contains('confidencial')));
  });

  test('limita registros para não inflar arquivo', () {
    final diagnostics = AppDiagnostics.forTest();
    for (var i = 0; i < AppDiagnostics.maxEntries + 12; i++) {
      diagnostics.info('LIMITE', 'evento');
    }
    expect(diagnostics.entries.length, AppDiagnostics.maxEntries);
  });

  test('erros API exibem resposta segura', () {
    const error = ElevenApiException('Resposta pode ter texto!', 401);
    expect(friendlyError(error), contains('chave inválida'));
    expect(friendlyError(error), isNot(contains('Resposta')));
  });

  test('link aponta para as chaves oficiais', () {
    expect(elevenApiKeysUrl, 'https://elevenlabs.io/app/settings/api-keys');
  });
}
