import 'package:flutter/services.dart';

/// Transferência explícita usando o seletor de documentos nativo Android.
/// Nenhuma chave é passada ao diagnóstico, ao log ou ao clipboard.
class KeyTransfer {
  static const channel = MethodChannel('com.drilemoz.uaivozes/key_transfer');

  static Future<String?> importFromDocument() async {
    final text = await channel.invokeMethod<String>('importKey');
    if (text == null) return null; // usuário cancelou
    return parseKeyFile(text);
  }

  /// O Android grava diretamente no URI escolhido, sem cópia temporária.
  static Future<bool> exportToDocument(String apiKey) async {
    return await channel.invokeMethod<bool>('exportKey', {
      'content': 'ELEVENLABS_API_KEY=${apiKey.trim()}\n',
    }) ?? false;
  }
}

/// Aceita chave pura, ENV e um JSON simples. NUNCA logar o conteúdo.
String parseKeyFile(String raw) {
  if (raw.length > 8192) throw const FormatException('Arquivo muito grande.');
  final text = raw.trim().replaceAll('\ufeff', '');
  if (text.isEmpty) throw const FormatException('Arquivo vazio.');
  if (text.startsWith('{')) {
    // Não permitimos JSON arbitrário: só chave plana.
    throw const FormatException('Use um arquivo TXT ou ENV com ELEVENLABS_API_KEY=valor.');
  }
  final data = text.split(RegExp(r'\r?\n')).where((l) =>
      l.trim().isNotEmpty && !l.trimLeft().startsWith('#')).toList();
  if (data.length != 1) throw const FormatException('O arquivo deve conter apenas uma chave API.');
  var value = data.single.trim();
  if (value.startsWith('export ')) value = value.substring(7).trim();
  if (value.startsWith('ELEVENLABS_API_KEY=')) {
    value = value.substring('ELEVENLABS_API_KEY='.length).trim();
  } else if (value.contains('=')) {
    throw const FormatException('Nome de chave inválido. Use ELEVENLABS_API_KEY.');
  }
  if ((value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))) {
    value = value.substring(1, value.length - 1);
  }
  if (value.isEmpty || value.length > 4096 || RegExp(r'\s').hasMatch(value)) {
    throw const FormatException('A chave API do arquivo não é válida.');
  }
  return value;
}
