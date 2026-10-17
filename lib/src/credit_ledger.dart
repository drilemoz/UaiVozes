import 'dart:convert';

/// Crédito BASE estimado, não custo faturado. As vozes podem ter
/// multiplicadores e a tarifa da API pode depender do plano.
class TtsModelOption {
  const TtsModelOption(this.id, this.label, this.hint);
  final String id;
  final String label;
  final String hint;
}

class CreditEstimator {
  static const String defaultModel = 'eleven_multilingual_v2';
  static const String flashModel = 'eleven_flash_v2_5';

  /// Somente modelos com custo base documentado pela ElevenLabs. Nenhum outro
  /// ID pode ser enviado: valores desconhecidos voltam ao padrão.
  static const List<TtsModelOption> ttsModels = [
    TtsModelOption(defaultModel, 'Multilingual v2',
        'Mais expressivo · base de 1 crédito por caractere'),
    TtsModelOption(flashModel, 'Flash v2.5',
        'Mais econômico · base de 0,5 crédito por caractere'),
  ];

  static bool isKnownModel(String? id) => ttsModels.any((m) => m.id == id);

  static String modelLabel(String id) => ttsModels
      .firstWhere((m) => m.id == id, orElse: () => ttsModels.first).label;

  static int characterCount(String text) => text.trim().runes.length;

  static int? baseEstimate(int characters, {String model = defaultModel}) {
    if (characters < 0) return null;
    // Tabela deliberadamente conservadora: nenhum preço inferido para
    // modelos cujo custo da API depende de plano/contrato.
    if (model == defaultModel) return characters;
    // Flash v2.5: 0,5 crédito/caractere (arredondado para cima), antes de
    // multiplicadores da voz e de eventuais condições do plano/API.
    if (model == flashModel) return (characters + 1) ~/ 2;
    return null;
  }
}

/// Registro LOCAL não inclui texto, nome de usuário, API key nem voz usada.
/// Não é um extrato oficial da ElevenLabs.
class CreditEvent {
  const CreditEvent({
    required this.id,
    required this.createdAt,
    required this.characters,
    required this.model,
    this.baseEstimate,
  });

  final String id;
  final DateTime createdAt;
  final int characters;
  final String model;
  final int? baseEstimate;

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'characters': characters,
    'model': model,
    if (baseEstimate != null) 'baseEstimate': baseEstimate,
  };

  static CreditEvent? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    // Itens corrompidos de versões anteriores não invalidam os demais.
    if (raw.keys.any((key) => key is! String)) return null;
    final map = Map<String, dynamic>.from(raw);
    final id = map['id'];
    final when = DateTime.tryParse('${map['createdAt'] ?? ''}');
    final chars = map['characters'];
    final model = map['model'];
    if (id is! String || id.isEmpty || id.length > 64 || when == null ||
        chars is! int || chars < 1 || chars > 100000 ||
        model is! String || model.isEmpty || model.length > 80) {
      return null;
    }
    final estimate = map['baseEstimate'];
    return CreditEvent(
      id: id,
      createdAt: when.toLocal(),
      characters: chars,
      model: model,
      baseEstimate: estimate is int && estimate >= 0 ? estimate : null,
    );
  }
}

class CreditLedger {
  static const maxEntries = 60;
  final List<CreditEvent> _events = [];
  List<CreditEvent> get events => List.unmodifiable(_events);

  CreditLedger([Iterable<CreditEvent> initial = const []]) {
    for (final event in initial) {
      add(event);
    }
  }

  static CreditLedger fromJson(String? raw) {
    if (raw == null || raw.isEmpty) return CreditLedger();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return CreditLedger();
      return CreditLedger(decoded.map(CreditEvent.tryParse).whereType<CreditEvent>());
    } catch (_) {
      return CreditLedger();
    }
  }

  void add(CreditEvent entry) {
    if (_events.any((e) => e.id == entry.id)) return;
    _events.add(entry);
    _events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (_events.length > maxEntries) {
      _events.removeRange(maxEntries, _events.length);
    }
  }

  List<CreditEvent> forMonth(DateTime date) => List.unmodifiable(_events.where(
    (event) => event.createdAt.year == date.year &&
        event.createdAt.month == date.month,
  ));

  String encode() => jsonEncode(_events.map((e) => e.toJson()).toList());
}

/// Mostra avisos apenas em dados OFICIAIS recém-consultados e válidos.
class CreditWarning {
  static int? percentThreshold(int? used, int? limit) {
    if (used == null || limit == null || used < 0 || limit <= 0) return null;
    final ratio = used / limit;
    if (ratio >= 0.95) return 95;
    if (ratio >= 0.80) return 80;
    if (ratio >= 0.50) return 50;
    return null;
  }
}
