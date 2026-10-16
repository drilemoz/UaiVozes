import 'package:flutter_test/flutter_test.dart';
import 'package:uaivozes/src/diagnostics.dart';
import 'package:uaivozes/src/eleven_api.dart';
import 'package:uaivozes/src/models.dart';
import 'package:uaivozes/src/voice_block_diagnostics.dart';

void main() {
  const voice = Voice(
    id: 'voice-secret-abc', name: 'Voz particular e confidencial',
    description: 'Texto confidencial', availableForTiers: ['creator'],
  );

  test('registra bloqueio indicado pelo tier somente após ação', () {
    final log = AppDiagnostics.forTest();
    expect(VoiceBlockDiagnostics.localRestriction(voice, 'free',
      publicLibrary: false, stage: VoiceCheckStage.select, diagnostics: log), true);
    final entry = log.entries.single;
    expect(entry.category, 'VOZ_BLOQUEIO');
    expect(entry.detail, contains('etapa=select'));
    expect(entry.detail, contains('fonte=metadados'));
    expect(entry.detail, contains('plano=free'));
    final report = log.report(version: '0.1.0-alpha.17');
    expect(report, isNot(contains(voice.id)));
    expect(report, isNot(contains(voice.name)));
    expect(report, isNot(contains(voice.description)));
    expect(report, contains('ref='));
  });

  test('compatível ou acesso desconhecido não gera falso bloqueio', () {
    final log = AppDiagnostics.forTest();
    expect(VoiceBlockDiagnostics.localRestriction(voice, 'creator',
      publicLibrary: false, stage: VoiceCheckStage.studio, diagnostics: log), false);
    expect(VoiceBlockDiagnostics.localRestriction(voice, null,
      publicLibrary: false, stage: VoiceCheckStage.studio, diagnostics: log), false);
    expect(log.entries, isEmpty);
  });

  test('HTTP 402 sem código continua motivo financeiro indeterminado', () {
    final log = AppDiagnostics.forTest();
    VoiceBlockDiagnostics.apiFailure(voice, 'free',
      const ElevenApiException('token secreto e corpo de resposta', 402),
      publicLibrary: false, stage: VoiceCheckStage.studio, diagnostics: log);
    final item = log.entries.single;
    expect(item.category, 'VOZ_API');
    expect(item.detail, contains('HTTP=402'));
    expect(item.detail, contains('cobranca_ou_creditos_a_verificar'));
    expect(item.detail, isNot(contains('bloqueio_voz_confirmado')));
    expect(log.report(), isNot(contains('token secreto')));
  });

  test('HTTP 403 com motivo explícito documenta restrição confirmada', () {
    final log = AppDiagnostics.forTest();
    VoiceBlockDiagnostics.apiFailure(voice, 'creator',
      const ElevenApiException('NÃO COPIAR', 403, 'voice_access_denied'),
      publicLibrary: false, stage: VoiceCheckStage.detail, diagnostics: log);
    final item = log.entries.single;
    expect(item.category, 'VOZ_BLOQUEIO');
    expect(item.detail, contains('codigo=voice_access_denied'));
    expect(item.detail, contains('bloqueio_voz_confirmado_pela_api'));
    expect(item.detail, isNot(contains('NÃO COPIAR')));
    expect(item.detail.length, lessThanOrEqualTo(200));
  });

  test('razões não permitidas não vazam para o registro', () {
    final log = AppDiagnostics.forTest();
    VoiceBlockDiagnostics.apiFailure(voice, 'starter-token-confidencial',
      const ElevenApiException('xxx', 403, 'secret=my-long-api-key'),
      publicLibrary: true, stage: VoiceCheckStage.addShared, diagnostics: log);
    final report = log.report();
    expect(report, contains('codigo=nao_informado'));
    expect(report, contains('plano=desconhecido'));
    expect(report, isNot(contains('my-long-api-key')));
    expect(report, isNot(contains('starter-token-confidencial')));
    expect(report, isNot(contains(voice.id)));
  });

  test('consulta inconclusiva não vira bloqueio', () {
    final log = AppDiagnostics.forTest();
    VoiceBlockDiagnostics.inconclusiveDetail(voice, 'creator',
      publicLibrary: false, diagnostics: log);
    expect(log.entries.single.category, 'VOZ_VERIFICACAO');
    expect(log.entries.single.detail, contains('acesso_nao_confirmado'));
  });

  test('diagnóstico filtra vozes na UI e na exportação sem apagar outros eventos', () {
    final log = AppDiagnostics.forTest();
    log.warning('CONTA', 'evento geral');
    VoiceBlockDiagnostics.apiFailure(voice, 'free',
      const ElevenApiException('status', 402), publicLibrary: false,
      stage: VoiceCheckStage.studio, diagnostics: log);
    log.info('VOZES_PREVIA', 'erro de prévia');
    expect(log.entries.length, 3);
    expect(log.filteredEntries(voiceOnly: true).length, 2);
    final result = log.report(voiceOnly: true);
    expect(result, contains('Filtro: eventos de vozes'));
    expect(result, contains('VOZ_API'));
    expect(result, contains('VOZES_PREVIA'));
    expect(result, isNot(contains('CONTA')));
    expect(log.report(), contains('CONTA'));
  });
}
