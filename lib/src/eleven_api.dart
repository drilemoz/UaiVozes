import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'models.dart';
import 'diagnostics.dart';

class ElevenApiException implements Exception {
  const ElevenApiException(this.message, [this.statusCode, this.reason]);
  final String message;
  final int? statusCode;
  /// Somente categorias conhecidas, nunca o corpo remoto nem a chave.
  final String? reason;
  @override
  String toString() => message;
}

String friendlyError(Object error) {
  if (error is ElevenApiException) {
    if (error.reason == 'free_users_not_allowed') {
      return 'esta voz não está disponível para usuários do plano Free';
    }
    return switch (error.statusCode) {
      400 => 'formato ou parâmetros não aceitos pela ElevenLabs',
      401 => 'chave inválida ou sem permissão',
      402 || 403 => 'recurso indisponível para seu plano ou chave',
      404 => 'voz ou modelo não encontrado ou sem acesso',
      422 => 'voz, modelo ou solicitação não aceitos pela API',
      429 => 'limite de requisições ou créditos atingidos',
      500 || 502 || 503 || 504 => 'instabilidade temporária da ElevenLabs',
      _ => error.statusCode == null ? 'falha de conexão ou resposta inválida' :
        'servidor respondeu HTTP ${error.statusCode}',
    };
  }
  return 'erro interno (consulte o diagnóstico local)';
}

class Subscription {
  const Subscription({
    required this.tier,
    this.used,
    this.limit,
    this.status = '',
    this.voiceSlotsUsed,
    this.voiceLimit,
    this.resetAt,
    this.billingPeriod = '',
    this.overageAmount,
    this.overageCurrency,
  });

  final String tier;
  /// Contagem reportada pela API (caracteres/unidades de uso), não uma
  /// estimativa de créditos faturados para qualquer modelo.
  final int? used;
  final int? limit;
  final String status;
  final int? voiceSlotsUsed;
  final int? voiceLimit;
  final DateTime? resetAt;
  final String billingPeriod;
  final String? overageAmount;
  final String? overageCurrency;

  int? get remaining => used == null || limit == null
      ? null : (limit! - used!).clamp(0, limit!).toInt();
  double? get usageRatio => used == null || limit == null || limit! <= 0
      ? null : (used! / limit!).clamp(0.0, 1.0).toDouble();

  factory Subscription.fromJson(Map<String, dynamic> json) {
    final reset = json['next_character_count_reset_unix'];
    final overage = json['current_overage'];
    final overageData = overage is Map ? overage : const {};
    return Subscription(
      tier: '${json['tier'] ?? 'desconhecido'}',
      used: (json['character_count'] as num?)?.toInt(),
      limit: (json['character_limit'] as num?)?.toInt(),
      status: '${json['status'] ?? ''}',
      voiceSlotsUsed: (json['voice_slots_used'] as num?)?.toInt(),
      voiceLimit: (json['voice_limit'] as num?)?.toInt(),
      resetAt: reset is num && reset > 0
          ? DateTime.fromMillisecondsSinceEpoch(reset.toInt() * 1000, isUtc: true).toLocal()
          : null,
      billingPeriod: '${json['billing_period'] ?? ''}',
      overageAmount: overageData['amount']?.toString(),
      overageCurrency: overageData['currency']?.toString(),
    );
  }
}

class ElevenAccount {
  const ElevenAccount({
    this.firstName = '',
    this.userId = '',
    this.workspaceId = '',
    this.seatType = '',
    this.subscription,
  });
  final String firstName;
  final String userId;
  final String workspaceId;
  final String seatType;
  final Subscription? subscription;

  factory ElevenAccount.fromJson(Map<String, dynamic> json) {
    final nested = json['subscription'];
    return ElevenAccount(
      firstName: json['first_name'] is String ? json['first_name'] as String : '',
      userId: json['user_id'] is String ? json['user_id'] as String : '',
      workspaceId: json['workspace_id'] is String ? json['workspace_id'] as String : '',
      seatType: json['seat_type'] is String ? json['seat_type'] as String : '',
      subscription: nested is Map
          ? Subscription.fromJson(Map<String, dynamic>.from(nested)) : null,
    );
  }
}

class VoicePage {
  const VoicePage(this.voices, this.nextToken);
  final List<Voice> voices;
  final String? nextToken;
}

class ElevenApi {
  ElevenApi(this._readKey, {http.Client? client})
      : _client = client ?? http.Client();

  final Future<String> Function() _readKey;
  final http.Client _client;
  static const host = 'api.elevenlabs.io';

  Future<Map<String, String>> _headers([String? keyOverride]) async {
    final key = (keyOverride ?? await _readKey()).trim();
    if (key.isEmpty) {
      throw const ElevenApiException('Configure sua chave de API primeiro.');
    }
    return {'xi-api-key': key, 'Accept': 'application/json'};
  }

  Never _fail(http.Response response) {
    // Não incluir o corpo remoto no diagnóstico ou numa mensagem. O servidor
    // pode ecoar partes do texto, metadados pessoais ou dados sensíveis.
    String? reason;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map && decoded['detail'] is Map) {
        final raw = decoded['detail']['status'];
        const permitted = <String>{
          'voice_not_found', 'model_not_found', 'quota_exceeded',
          'invalid_api_key', 'missing_permissions', 'rate_limit_exceeded',
          'voice_limit_reached', 'free_users_not_allowed',
        };
        if (raw is String && permitted.contains(raw)) reason = raw;
      }
    } catch (_) {
      // Falha de parse não deve esconder o status HTTP.
    }
    final code = response.statusCode;
    AppDiagnostics.instance.failure('API_HTTP',
        'HTTP $code${reason == null ? '' : ' | $reason'}');
    final message = switch (code) {
      400 => 'A solicitação não foi aceita. Verifique a voz e o modelo.',
      401 => 'Chave API inválida ou sem permissão para este recurso.',
      402 || 403 => 'O plano ou a chave API não permite esta operação.',
      404 => 'A voz ou o modelo pode não estar disponível na sua conta.',
      422 => 'A ElevenLabs rejeitou a combinação de voz, modelo ou texto.',
      429 => 'Limite da conta ou da API atingido.',
      500 || 502 || 503 || 504 => 'A ElevenLabs apresentou instabilidade.',
      _ => 'A ElevenLabs retornou HTTP $code.',
    };
    throw ElevenApiException(message, code, reason);
  }

  Future<http.Response> _get(String path, [Map<String, String>? params, String? overrideKey]) async {
    try {
      final response = await _client
          .get(Uri.https(host, path, params), headers: await _headers(overrideKey))
          .timeout(const Duration(seconds: 25));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _fail(response);
      }
      return response;
    } on ElevenApiException {
      rethrow;
    } catch (e, stack) {
      AppDiagnostics.instance.capture('API_REDE', e, stack);
      throw const ElevenApiException('Falha de conexão. Verifique sua internet.');
    }
  }

  /// Testa a chave digitada sem substituí-la no Keystore nem no modelo.
  /// Compartilha o client injetável para permitir testes com resposta simulada.
  Future<Subscription> checkCandidateKey(String candidate) async {
    final checked = candidate.trim();
    if (checked.isEmpty) throw const ElevenApiException('Informe uma chave API.');
    final response = await _get('/v1/user/subscription', null, checked);
    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return Subscription.fromJson(data);
  }

  Future<Subscription> checkSubscription() async {
    final response = await _get('/v1/user/subscription');
    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return Subscription.fromJson(data);
  }

  /// Os dados pessoais só ficam disponíveis com escopo User: Read na chave.
  Future<ElevenAccount> getAccount() async {
    final response = await _get('/v1/user');
    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return ElevenAccount.fromJson(data);
  }

  /// Busca paginada no catálogo da conta. Os filtros abaixo pertencem
  /// ao endpoint /v2/voices, não ao ranking de vozes compartilhadas.
  Future<VoicePage> voices({
    String? token,
    String? language,
    String? search,
    String? gender,
    String? age,
    String? accent,
    String? useCase,
  }) async {
    final query = <String, String>{
      'page_size': '30',
      'include_total_count': 'false',
    };
    if (token != null && token.isNotEmpty) query['next_page_token'] = token;
    if (language != null && language.isNotEmpty && language != 'all') {
      query['language'] = language;
    }
    if (search != null && search.trim().isNotEmpty) query['search'] = search.trim();
    if (gender != null && gender.isNotEmpty && gender != 'all') query['gender'] = gender;
    if (age != null && age.isNotEmpty && age != 'all') query['age'] = age;
    if (accent != null && accent.isNotEmpty && accent != 'all') query['accent'] = accent;
    if (useCase != null && useCase.isNotEmpty && useCase != 'all') {
      query['use_cases'] = useCase;
    }
    final response = await _get('/v2/voices', query);
    final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final raw = json['voices'] is List ? json['voices'] as List : [];
    final entries = raw.whereType<Map>()
        .map((e) => Voice.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.id.isNotEmpty).toList();
    final next = json['has_more'] == true && json['next_page_token'] is String
        && (json['next_page_token'] as String).isNotEmpty
        ? json['next_page_token'] as String : null;
    return VoicePage(entries, next);
  }

  /// Classificação REAL do catálogo compartilhado, não da lista pessoal.
  /// Este endpoint pode estar indisponível em contas Free.
  Future<List<Voice>> topTen({
    required String language,
    String? useCase,
    String? descriptive,
  }) async {
    final query = <String, String>{
      'language': language,
      if (language == 'pt') 'locale': 'pt-BR',
      'sort': 'usage_character_count_1y',
      'page_size': '10',
      'page': '0',
    };
    if (useCase != null && useCase.isNotEmpty && useCase != 'all') {
      query['use_cases'] = useCase;
    }
    if (descriptive != null && descriptive.isNotEmpty && descriptive != 'all') {
      query['descriptives'] = descriptive;
    }
    final response = await _get('/v1/shared-voices', query);
    final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final list = json['voices'] is List ? json['voices'] as List : [];
    return list.whereType<Map>().map((e) => Voice.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.id.isNotEmpty).take(10).toList();
  }

  Future<Voice> voiceDetail(String id) async {
    final response = await _get('/v1/voices/${Uri.encodeComponent(id)}');
    return Voice.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
  }

  /// Adiciona voz da biblioteca compartilhada à conta, mediante ação explícita.
  Future<String> addSharedVoice(Voice voice) async {
    if (voice.publicOwnerId.isEmpty) {
      throw const ElevenApiException('Esta voz já deve estar na sua conta.');
    }
    try {
      final response = await _client.post(
        Uri.https(host,
            '/v1/voices/add/${Uri.encodeComponent(voice.publicOwnerId)}/${Uri.encodeComponent(voice.id)}'),
        headers: {...await _headers(), 'Content-Type': 'application/json'},
        body: jsonEncode({'new_name': voice.name}),
      ).timeout(const Duration(seconds: 35));
      if (response.statusCode < 200 || response.statusCode >= 300) _fail(response);
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final id = json['voice_id'];
      if (id is! String || id.isEmpty) {
        throw const ElevenApiException('A API não confirmou a voz adicionada.');
      }
      return id;
    } on ElevenApiException {
      rethrow;
    } catch (e, stack) {
      AppDiagnostics.instance.capture('API_ADICIONAR_VOZ', e, stack);
      throw const ElevenApiException('Não foi possível adicionar a voz.');
    }
  }

  Future<Uint8List> synthesize({
    required String voiceId,
    required String text,
    String model = 'eleven_multilingual_v2',
  }) async {
    final normalized = text.trim();
    if (normalized.isEmpty) {
      throw const ElevenApiException('Digite um texto para converter.');
    }
    if (normalized.runes.length > 5000) {
      throw const ElevenApiException('Máximo de 5.000 caracteres por geração.');
    }
    try {
      final headers = await _headers();
      final response = await _client.post(
        Uri.https(host, '/v1/text-to-speech/${Uri.encodeComponent(voiceId)}',
            {'output_format': 'mp3_44100_128'}),
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode({'text': normalized, 'model_id': model}),
      ).timeout(const Duration(seconds: 100));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _fail(response);
      }
      if (response.bodyBytes.isEmpty) {
        throw const ElevenApiException('Nenhum áudio foi retornado.');
      }
      // Não salvar uma resposta HTML/JSON de proxy como arquivo MP3.
      final bytes = response.bodyBytes;
      final hasId3 = bytes.length >= 3 && bytes[0] == 0x49 &&
          bytes[1] == 0x44 && bytes[2] == 0x33;
      final hasMpegFrame = bytes.length >= 2 && bytes[0] == 0xFF &&
          (bytes[1] & 0xE0) == 0xE0;
      if (!hasId3 && !hasMpegFrame) {
        AppDiagnostics.instance.failure('API_AUDIO', 'HTTP 200 sem cabeçalho MP3 reconhecível');
        throw const ElevenApiException('A resposta da API não contém um MP3 reconhecível.');
      }
      return bytes;
    } on ElevenApiException {
      rethrow;
    } catch (e, stack) {
      AppDiagnostics.instance.capture('API_GERAR_AUDIO', e, stack);
      // Não há retentativa automática: uma solicitação pode ter consumido créditos.
      throw const ElevenApiException(
          'Não foi possível concluir a geração. Consulte seus créditos antes de repetir.');
    }
  }

  void dispose() => _client.close();
}
