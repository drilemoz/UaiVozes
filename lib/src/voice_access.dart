import 'models.dart';

/// Classificação conservadora baseada em sinais devolvidos pela API.
/// Compatível significa "tier explicitamente listado", NÃO geração gratuita,
/// créditos suficientes, acesso ao modelo nem garantia de síntese.
enum VoiceAccess { compatible, restricted, currentTierNotListed, unknown }

/// 'accountCandidates' são vozes da conta sem restrição comprovada; não
/// significa que a conta pode gerar TTS, nem que existe saldo suficiente.
enum VoiceAccessFilter { all, accountCandidates, compatible, restricted, unknown }

class VoiceAccessInfo {
  const VoiceAccessInfo(this.state, this.label, this.details, {this.specialRate = false});
  final VoiceAccess state;
  final String label;
  final String details;
  final bool specialRate;
  bool get isRestricted =>
      state == VoiceAccess.restricted || state == VoiceAccess.currentTierNotListed;
  bool get isCompatible => state == VoiceAccess.compatible;
}

bool matchesVoiceAccessFilter(VoiceAccessFilter filter, VoiceAccessInfo info,
    {bool ownedCatalog = false}) =>
    switch (filter) {
      VoiceAccessFilter.all => true,
      // /v2/voices lista vozes associadas à conta. A ausência de restrição
      // EXPLÍCITA as torna apenas candidatas, não compatíveis confirmadas.
      VoiceAccessFilter.accountCandidates => ownedCatalog && !info.isRestricted,
      VoiceAccessFilter.compatible => info.isCompatible,
      VoiceAccessFilter.restricted => info.isRestricted,
      VoiceAccessFilter.unknown => info.state == VoiceAccess.unknown,
    };

VoiceAccessInfo evaluateVoiceAccess(Voice voice, String? tier,
    {bool publicLibrary = false}) {
  final plan = (tier ?? '').trim().toLowerCase();
  final listed = voice.availableForTiers.map((e) => e.trim().toLowerCase())
      .where((e) => e.isNotEmpty).toSet();
  final special = voice.hasCustomRate;
  if (plan.isEmpty || plan == 'desconhecido' || plan == 'unknown') {
    return VoiceAccessInfo(VoiceAccess.unknown, 'Acesso a confirmar',
      'Consulte seu plano em Conta e verifique os detalhes da voz. '
      'Sem plano conhecido não é possível classificá-la.', specialRate: special);
  }
  // Regra documentada para a Voice Library: usuários Free não podem usar
  // vozes da biblioteca compartilhada via API, ainda que tenham prévia.
  if (publicLibrary && plan == 'free') {
    return VoiceAccessInfo(VoiceAccess.restricted, 'Biblioteca exige plano pago',
      'Segundo a ElevenLabs, vozes da biblioteca pública não ficam disponíveis '
      'pela API no plano Free. Ouvir prévia não significa acesso à geração.',
      specialRate: special);
  }
  if (listed.isNotEmpty && !listed.contains(plan)) {
    if (plan == 'free') {
      return VoiceAccessInfo(VoiceAccess.restricted, 'Exige plano pago',
        'A API não lista o plano Free entre os níveis disponíveis para a voz.',
        specialRate: special);
    }
    return VoiceAccessInfo(VoiceAccess.currentTierNotListed, 'Plano não listado',
      'A API não inclui o nível da sua assinatura entre os disponíveis nesta voz.',
      specialRate: special);
  }
  if (listed.contains(plan)) {
    return VoiceAccessInfo(VoiceAccess.compatible, 'Compatível segundo a API',
      'Seu plano está entre os níveis informados para a voz. Isso não confirma '
      'saldo, custo, permissão do modelo nem êxito da geração.', specialRate: special);
  }
  // free_users_allowed descreve a ADIÇÃO de uma voz compartilhada por um
  // usuário Free, não assegura nem impede geração em voz já adicionada.
  return VoiceAccessInfo(VoiceAccess.unknown, 'Acesso a confirmar',
    voice.freeUsersAllowed == false
      ? 'A voz restringe novas adições por usuários Free; isso não comprova '
        'que uma voz já na sua conta esteja bloqueada para geração.'
      : 'A API não informou os níveis de assinatura aceitos. A permissão de '
        'compartilhamento e a prévia não confirmam acesso à síntese.',
    specialRate: special);
}

/// A consulta de detalhe não deve apagar nome, filtros ou dados de ranking;
/// a API pode devolver somente parte dos campos de uma voz.
Voice mergeVoiceAccessMetadata(Voice original, Voice detail) {
  if (detail.id != original.id) return original;
  return Voice(
    id: original.id,
    name: original.name,
    category: original.category,
    description: original.description,
    previewUrl: original.previewUrl.isNotEmpty ? original.previewUrl : detail.previewUrl,
    language: original.language.isNotEmpty ? original.language : detail.language,
    accent: original.accent.isNotEmpty ? original.accent : detail.accent,
    useCase: original.useCase.isNotEmpty ? original.useCase : detail.useCase,
    gender: original.gender.isNotEmpty ? original.gender : detail.gender,
    style: original.style.isNotEmpty ? original.style : detail.style,
    annualCharacters: original.annualCharacters,
    publicOwnerId: original.publicOwnerId,
    availableForTiers: detail.availableForTiers.isNotEmpty
        ? detail.availableForTiers : original.availableForTiers,
    freeUsersAllowed: detail.freeUsersAllowed ?? original.freeUsersAllowed,
    hasCustomRate: detail.hasCustomRate || original.hasCustomRate,
    isLegacy: original.isLegacy || detail.isLegacy,
  );
}
