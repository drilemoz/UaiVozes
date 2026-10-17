import 'package:flutter/services.dart';

/// Salva um MP3 da Biblioteca no local escolhido pela pessoa (seletor nativo
/// SAF, sem permissão ampla de armazenamento). Não usa rede nem a API.
class AudioExport {
  static const channel = MethodChannel('com.drilemoz.uaivozes/key_transfer');
  static const fallbackName = 'Uai-Vozes-audio';
  static const maxNameLength = 80;

  /// Nome seguro para arquivo: remove separadores e caracteres reservados e
  /// garante a extensão .mp3.
  static String fileName(String title) {
    var base = title
        .replaceAll(RegExp(r'[\\/:*?"<>|\u0000-\u001F]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (base.toLowerCase().endsWith('.mp3')) {
      base = base.substring(0, base.length - 4).trim();
    }
    base = base.replaceAll(RegExp(r'^[._ ]+|[._ ]+$'), '');
    if (base.isEmpty) base = fallbackName;
    final runes = base.runes.toList();
    if (runes.length > maxNameLength) {
      base = String.fromCharCodes(runes.take(maxNameLength)).trim();
    }
    return '$base.mp3';
  }

  /// Retorna true se salvou, false se a pessoa cancelou.
  static Future<bool> saveMp3(String path, String title) async {
    if (path.trim().isEmpty) {
      throw const FormatException('Arquivo de áudio ausente.');
    }
    return await channel.invokeMethod<bool>('exportAudio',
      {'path': path, 'name': fileName(title)}) ?? false;
  }
}
