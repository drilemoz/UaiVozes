import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Diagnóstico local, pequeno e sem telemetria. Nunca armazena chaves,
/// cabeçalhos HTTP, corpos de requisição/resposta ou texto sintetizado.
class DiagnosticEntry {
  const DiagnosticEntry({required this.time, required this.kind,
    required this.category, required this.detail});
  final DateTime time;
  final String kind;
  final String category;
  final String detail;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'time': time.toIso8601String(), 'kind': kind,
    'category': category, 'detail': detail,
  };

  static DiagnosticEntry? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final date = DateTime.tryParse('${raw['time'] ?? ''}');
    if (date == null) return null;
    return DiagnosticEntry(time: date, kind: '${raw['kind'] ?? ''}',
      category: '${raw['category'] ?? ''}', detail: '${raw['detail'] ?? ''}');
  }
}

class AppDiagnostics extends ChangeNotifier {
  AppDiagnostics._();
  @visibleForTesting
  AppDiagnostics.forTest();
  static final AppDiagnostics instance = AppDiagnostics._();
  static const maxEntries = 100;
  static const _prefsKey = 'diagnostics_local_v1';
  final List<DiagnosticEntry> _entries = [];
  SharedPreferences? _prefs;

  List<DiagnosticEntry> get entries => List.unmodifiable(_entries.reversed);

  Future<void> restore() async {
    _prefs = await SharedPreferences.getInstance();
    try {
      final values = jsonDecode(_prefs?.getString(_prefsKey) ?? '[]');
      if (values is List) {
        _entries.clear();
        _entries.addAll(values.map(DiagnosticEntry.fromJson).whereType<DiagnosticEntry>().take(maxEntries));
      }
      notifyListeners();
    } catch (_) {
      _entries.clear();
    }
    info('APLICATIVO', 'Sessão iniciada.');
  }

  void info(String category, String detail) => _record('INFO', category, detail);
  void warning(String category, String detail) => _record('AVISO', category, detail);
  void failure(String category, String detail) => _record('ERRO', category, detail);

  /// Registra somente o TIPO da exceção e os frames do próprio aplicativo.
  /// Nunca serializa exception.toString() ou dados recebidos da API.
  void capture(String category, Object exception, [StackTrace? stack]) {
    final frames = stack == null ? const <String>[] : RegExp(
      r'package:uaivozes/[a-zA-Z0-9_/.]+\.dart:[0-9]+(?::[0-9]+)?',
    ).allMatches(stack.toString()).take(4).map((m) => m.group(0)!).toList();
    final detail = '${exception.runtimeType}'
        '${frames.isEmpty ? '' : ' | ${frames.join(' | ')}'}';
    _record('ERRO', category, detail);
  }

  void _record(String kind, String category, String detail) {
    // Categorias e mensagens são constantes fornecidas pelo aplicativo.
    final entry = DiagnosticEntry(time: DateTime.now(), kind: kind,
      category: category.length > 60 ? category.substring(0, 60) : category,
      detail: detail.length > 200 ? detail.substring(0, 200) : detail);
    _entries.add(entry);
    if (_entries.length > maxEntries) _entries.removeRange(0, _entries.length-maxEntries);
    notifyListeners();
    _persist();
  }

  void _persist() {
    final preferences = _prefs;
    if (preferences == null) return;
    // Persistência no armazenamento interno do próprio aplicativo.
    try {
      // Falha na persistência do diagnóstico não pode gerar ciclo de erro.
      preferences.setString(_prefsKey,
        jsonEncode(_entries.map((e) => e.toJson()).toList()))
        .catchError((Object _) => false);
    } catch (_) {
      // Falha do diagnóstico nunca deve derrubar o aplicativo.
    }
  }

  Future<void> clear() async {
    _entries.clear();
    notifyListeners();
    await _prefs?.remove(_prefsKey);
  }

  String report({String version = 'desconhecida'}) {
    final out = StringBuffer('Uai Vozes | Diagnóstico local\n')
      ..writeln('Versão: $version')
      ..writeln('Gerado: ${DateTime.now().toIso8601String()}')
      ..writeln('Registros: ${_entries.length}')
      ..writeln('Privacidade: não inclui chave API, textos, cabeçalhos ou corpos HTTP.')
      ..writeln('---');
    for (final item in entries) {
      out.writeln('[${item.time.toLocal().toIso8601String()}] '
          '${item.kind} • ${item.category} • ${item.detail}');
    }
    return out.toString();
  }
}
