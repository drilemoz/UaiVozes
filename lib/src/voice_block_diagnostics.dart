import 'diagnostics.dart';
import 'eleven_api.dart';
import 'models.dart';
import 'voice_access.dart';

/// Identifica onde ocorreu a restrição sem registrar texto, URL ou ID da voz.
enum VoiceCheckStage { select, studio, detail, addShared }

/// Eventos acionados por ações explícitas, nunca durante renderização,
/// pesquisa automática, aplicação de filtros ou paginação.
class VoiceBlockDiagnostics {
  const VoiceBlockDiagnostics._();

  static const _safeTiers = <String>{
    'free', 'starter', 'creator', 'pro', 'scale', 'business', 'enterprise',
  };
  static const _safeReasons = <String>{
    'voice_not_found', 'model_not_found', 'quota_exceeded',
    'invalid_api_key', 'missing_permissions', 'rate_limit_exceeded',
    'voice_limit_reached', 'free_users_not_allowed',
    'insufficient_credits', 'subscription_required',
    'feature_not_available', 'voice_access_denied',
    'model_access_denied', 'insufficient_permissions',
  };
  static const _voiceDenied = <String>{
    'voice_access_denied', 'free_users_not_allowed',
  };

  static String _tier(String? raw) {
    final tier = raw?.trim().toLowerCase() ?? '';
    return _safeTiers.contains(tier) ? tier : 'desconhecido';
  }

  /// Código de correlação não reversível de forma direta, mas não é um
  /// hash criptográfico. Não incluir o ID original, nome ou metadados livres.
  static String _reference(String voiceId) {
    var hash = 0x811c9dc5;
    for (final unit in voiceId.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  static String _base(Voice voice, String? tier, bool publicLibrary,
      VoiceCheckStage stage) {
    final info = evaluateVoiceAccess(voice, tier, publicLibrary: publicLibrary);
    final origin = publicLibrary ? 'publica' : 'minhas';
    return 'ref=${_reference(voice.id)} | etapa=${stage.name} | '
        'origem=$origin | plano=${_tier(tier)} | '
        'acesso=${info.state.name} | '
        'tarifa=${info.specialRate ? 'sim' : 'nao'}';
  }

  /// Só grava como BLOQUEIO quando os metadados efetivamente indicarem
  /// restrição para o plano conhecido, não para acesso desconhecido.
  static bool localRestriction(Voice voice, String? tier,
      {required bool publicLibrary, required VoiceCheckStage stage,
      AppDiagnostics? diagnostics}) {
    if (!evaluateVoiceAccess(voice, tier, publicLibrary: publicLibrary)
        .isRestricted) return false;
    (diagnostics ?? AppDiagnostics.instance).warning('VOZ_BLOQUEIO',
      '${_base(voice, tier, publicLibrary, stage)} | fonte=metadados');
    return true;
  }

  /// GET feito manualmente sem informação suficiente: não é bloqueio.
  static void inconclusiveDetail(Voice voice, String? tier,
      {required bool publicLibrary, AppDiagnostics? diagnostics}) {
    (diagnostics ?? AppDiagnostics.instance).info('VOZ_VERIFICACAO',
      '${_base(voice, tier, publicLibrary, VoiceCheckStage.detail)} | '
      'resultado=acesso_nao_confirmado');
  }

  /// Código HTTP e motivo permitidos, sem armazenar conteúdo retornado.
  /// HTTP 402 sem motivo não pode ser classificado como bloqueio de voz.
  static void apiFailure(Voice voice, String? tier, ElevenApiException error,
      {required bool publicLibrary, required VoiceCheckStage stage,
      AppDiagnostics? diagnostics}) {
    final reason = _safeReasons.contains(error.reason) ? error.reason! : 'nao_informado';
    final status = error.statusCode;
    final http = status != null && status >= 100 && status <= 599
        ? '$status' : 'desconhecido';
    final denied = _voiceDenied.contains(reason);
    final interpretation = denied ? 'bloqueio_voz_confirmado_pela_api'
        : status == 402 ? 'cobranca_ou_creditos_a_verificar'
        : status == 403 ? 'permissao_a_verificar'
        : 'motivo_a_verificar';
    (diagnostics ?? AppDiagnostics.instance).warning(
      denied ? 'VOZ_BLOQUEIO' : 'VOZ_API',
      '${_base(voice, tier, publicLibrary, stage)} | '
      'HTTP=$http | codigo=$reason | resultado=$interpretation');
  }
}
