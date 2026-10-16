import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uaivozes/src/diagnostics.dart';
import 'package:uaivozes/src/eleven_links.dart';
import 'package:uaivozes/src/eleven_api.dart';

void main() {
  test('limpeza espera gravações anteriores e persiste vazia', () async {
    SharedPreferences.setMockInitialValues({});
    final diagnostics = AppDiagnostics.forTest();
    await diagnostics.restore();
    diagnostics.failure('TESTE', 'falha controlada');
    diagnostics.warning('TESTE', 'aviso controlado');
    await diagnostics.clear();
    await diagnostics.flush();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('diagnostics_local_v1'), isNull);
    expect(diagnostics.entries, isEmpty);
  });

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

// Regressão de gravações assíncronas: Limpar deve permanecer vazio após
// qualquer evento que ainda esteja na fila de persistência.
