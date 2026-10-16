import 'package:flutter/services.dart';
import 'text_drafts.dart';

/// Escolhe TXT com SAF nativo e limite de tamanho, sem armazenamento amplo.
class TextTransfer {
  static const channel = MethodChannel('com.drilemoz.uaivozes/key_transfer');
  static Future<String?> importText() async {
    final content = await channel.invokeMethod<String>('importText');
    if (content == null) return null;
    final clean = content.replaceFirst('\ufeff', '');
    if (clean.trim().isEmpty || clean.runes.length > TextDrafts.maxCharacters) {
      throw const FormatException('O texto precisa ter de 1 a 50.000 caracteres.');
    }
    return clean;
  }
}
