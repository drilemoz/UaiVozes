import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'models.dart';

class ElevenApiException implements Exception {
  const ElevenApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class Subscription {
  const Subscription({required this.tier, this.used, this.limit});
  final String tier;
  final int? used;
  final int? limit;
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

  Future<Map<String, String>> _headers() async {
    final key = (await _readKey()).trim();
    if (key.isEmpty) {
      throw const ElevenApiException('Configure sua chave de API primeiro.');
    }
    return {'xi-api-key': key, 'Accept': 'application/json'};
  }

  Never _fail(http.Response response) {
    String detail = '';
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map && body['detail'] is Map) {
        detail = '${body['detail']['message'] ?? ''}';
      } else if (body is Map && body['detail'] is String) {
        detail = body['detail'] as String;
      }
    } catch (_) {
      // Mensagem humana padronizada. Não expõe cabeçalhos/chave.
    }
    final code = response.statusCode;
    if (code == 401) {
      throw ElevenApiException('Chave API inválida ou sem permissão.', code);
    }
    if (code == 402) {
      throw ElevenApiException('Recurso exige outro plano da ElevenLabs.', code);
    }
    if (code == 403) {
      throw ElevenApiException('Seu plano ou sua chave não permite este recurso.', code);
    }
    if (code == 429) {
      throw ElevenApiException('Limite de requisições ou créditos atingido.', code);
    }
    if (code == 422) {
      throw ElevenApiException(
          detail.isEmpty ? 'Texto, voz ou modelo não aceito pela API.' : detail,
          code);
    }
    throw ElevenApiException(
        detail.isEmpty ? 'A ElevenLabs retornou HTTP $code.' : detail, code);
  }

  Future<http.Response> _get(String path, [Map<String, String>? params]) async {
    try {
      final response = await _client
          .get(Uri.https(host, path, params), headers: await _headers())
          .timeout(const Duration(seconds: 25));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _fail(response);
      }
      return response;
    } on ElevenApiException {
      rethrow;
    } catch (_) {
      throw const ElevenApiException('Falha de conexão. Verifique sua internet.');
    }
  }

  Future<Subscription> checkSubscription() async {
    final response = await _get('/v1/user/subscription');
    final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return Subscription(
      tier: '${json['tier'] ?? 'desconhecido'}',
      used: (json['character_count'] as num?)?.toInt(),
      limit: (json['character_limit'] as num?)?.toInt(),
    );
  }

  Future<VoicePage> voices({String? token, String? language}) async {
    final query = <String, String>{
      'page_size': '50',
      'include_total_count': 'false',
    };
    if (token != null && token.isNotEmpty) query['next_page_token'] = token;
    if (language != null && language.isNotEmpty && language != 'all') {
      query['language'] = language;
    }
    final response = await _get('/v2/voices', query);
    final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final raw = json['voices'] is List ? json['voices'] as List : [];
    final entries = raw.whereType<Map>().map((e) => Voice.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.id.isNotEmpty).toList();
    final next = json['has_more'] == true ? json['next_page_token'] as String? : null;
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
    } catch (_) {
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
      return response.bodyBytes;
    } on ElevenApiException {
      rethrow;
    } catch (_) {
      // Não há retentativa automática: uma solicitação pode ter consumido créditos.
      throw const ElevenApiException(
          'Não foi possível concluir a geração. Consulte seus créditos antes de repetir.');
    }
  }

  void dispose() => _client.close();
}
