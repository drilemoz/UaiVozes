import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uaivozes/src/eleven_api.dart';
import 'package:uaivozes/src/generation_failure.dart';

void main() {
  test('status 403 orienta verificar acesso à voz sem revelar conteúdo', () {
    const error = ElevenApiException('texto sensível que não pode vazar', 403);
    final result = GenerationFailure.classify(error,
      audioReceived: false, audioSaved: false);
    expect(result.title, 'Falha na geração pela API');
    expect(result.httpStatus, 403);
    expect(result.message, contains('chave'));
    expect(result.nextAction, contains('Minhas vozes'));
    expect(result.report, contains('HTTP 403'));
    expect(result.report, isNot(contains('texto sensível')));
  });

  test('status 404 dá orientação para seleção de voz', () {
    const error = ElevenApiException('conteúdo privado', 404, 'voice_not_found');
    final result = GenerationFailure.classify(error,
      audioReceived: false, audioSaved: false);
    expect(result.nextAction, contains('Minhas vozes'));
    expect(result.diagnostic, contains('voice_not_found'));
    expect(result.report, isNot(contains('conteúdo privado')));
  });

  test('erro de rede não recomenda repetição automática', () {
    final result = GenerationFailure.classify(
      const ElevenApiException('segredo da rede'),
      audioReceived: false, audioSaved: false);
    expect(result.httpStatus, isNull);
    expect(result.nextAction, contains('Biblioteca'));
    expect(result.nextAction, contains('saldo'));
  });

  test('áudio recebido mas não salvo informa risco de cobrança', () {
    final result = GenerationFailure.classify(
      const FileSystemException('caminho privado /sdcard'),
      audioReceived: true, audioSaved: false);
    expect(result.title, 'Erro ao salvar áudio');
    expect(result.nextAction, contains('pode ter sido cobrado'));
    expect(result.report, isNot(contains('/sdcard')));
  });

  test('nenhum relatório ecoa exceção desconhecida', () {
    final result = GenerationFailure.classify(
      Exception('xi-api-key=segredo e texto confidencial'),
      audioReceived: false, audioSaved: false);
    expect(result.report, isNot(contains('segredo')));
    expect(result.report, isNot(contains('confidencial')));
  });
}
