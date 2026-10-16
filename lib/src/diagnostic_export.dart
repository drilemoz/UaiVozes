import 'package:flutter/services.dart';

/// Salva o conteúdo UTF-8 diretamente no arquivo escolhido com SAF nativo.
/// Não usa Sharesheet, pois certos aplicativos compartilhavam só o título.
class DiagnosticExport {
  static const channel = MethodChannel('com.drilemoz.uaivozes/key_transfer');

  static Future<bool> save(String report) async {
    if (report.isEmpty || report.length > 100000) {
      throw const FormatException('Relatório inválido ou excessivamente grande.');
    }
    return await channel.invokeMethod<bool>('exportDiagnostic',
      {'content': report}) ?? false;
  }
}
