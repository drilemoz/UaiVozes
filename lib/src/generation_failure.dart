import 'dart:io';

import 'eleven_api.dart';

/// Erros mostrados ao usuário sem ecoar o corpo da API, texto ou segredo.
class GenerationFailure {
  const GenerationFailure({required this.title, required this.message,
    required this.nextAction, required this.diagnostic, this.httpStatus});
  final String title;
  final String message;
  final String nextAction;
  final String diagnostic;
  final int? httpStatus;

  static GenerationFailure classify(Object error, {required bool audioReceived,
    required bool audioSaved}) {
    if (error is ElevenApiException && !audioReceived) {
      final status = error.statusCode;
      final details = switch (status) {
        400 || 422 => 'A API rejeitou a solicitação. Pode ser incompatibilidade entre voz e modelo.',
        401 => 'A chave não foi aceita para gerar áudio. Consultar saldo pode exigir permissões diferentes.',
        402 || 403 => 'A chave ou o plano não permite usar esta voz ou função.',
        404 => 'A voz selecionada ou o modelo não está disponível para esta conta.',
        429 => 'A ElevenLabs bloqueou a solicitação por limite de uso ou frequência.',
        500 || 502 || 503 || 504 => 'O servidor da ElevenLabs apresentou uma falha.',
        _ => 'Não foi possível confirmar a resposta da ElevenLabs.',
      };
      final next = switch (status) {
        400 || 402 || 403 || 404 || 422 =>
          'Confira se a voz está em Minhas vozes e tente uma voz disponível para sua conta.',
        401 => 'Confira as permissões da chave API em Configurações.',
        429 => 'Confira os limites e aguarde antes de solicitar outra geração.',
        _ => 'Confira a Biblioteca e o saldo antes de tentar novamente. Uma solicitação pode ter sido cobrada.',
      };
      return GenerationFailure(title: 'Falha na geração pela API', message: details,
        nextAction: next, httpStatus: status,
        diagnostic: 'GERACAO_API | ${status == null ? 'sem resposta HTTP confirmada' : 'HTTP $status'}'
          '${error.reason == null ? '' : ' | ${error.reason}'}');
    }
    if (audioReceived && !audioSaved) {
      return GenerationFailure(title: 'Erro ao salvar áudio',
        message: 'A API respondeu com áudio, mas o arquivo não foi confirmado na Biblioteca.',
        nextAction: 'Não gere novamente sem conferir a Biblioteca e o espaço livre. O pedido pode ter sido cobrado.',
        diagnostic: 'GERACAO_SALVAR | ${error is FileSystemException ? 'FileSystemException' : error.runtimeType}');
    }
    return GenerationFailure(title: 'Falha ao gerar áudio',
      message: 'O aplicativo não conseguiu concluir a operação.',
      nextAction: 'Confira a Biblioteca, o saldo e o Diagnóstico local antes de repetir.',
      diagnostic: 'GERACAO_INTERNA | ${error.runtimeType}');
  }

  String get report => 'Uai Vozes | $diagnostic\n$title\n$message\n$nextAction';
}
