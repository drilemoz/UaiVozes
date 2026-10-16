import 'models.dart';

/// Somente estados sustentados por metadados explícitos; ausência de dados
/// nunca significa que a voz é gratuita ou cobrável em tarifa normal.
enum VoiceAccess { restricted, currentTierNotListed, unknown }

class VoiceAccessInfo {
  const VoiceAccessInfo(this.state, this.label, this.details, {this.specialRate = false});
  final VoiceAccess state;
  final String label;
  final String details;
  final bool specialRate;
  bool get isRestricted => state != VoiceAccess.unknown;
}

VoiceAccessInfo evaluateVoiceAccess(Voice voice, String? tier) {
  final plan = (tier ?? '').trim().toLowerCase();
  final listed = voice.availableForTiers.map((e) => e.toLowerCase()).toSet();
  final special = voice.hasCustomRate;
  if (plan == 'free' && (voice.freeUsersAllowed == false ||
      (listed.isNotEmpty && !listed.contains('free')))) {
    return VoiceAccessInfo(VoiceAccess.restricted, 'Exige plano pago',
      'Os metadados indicam restrição ao plano Free. Não tente gerar sem conferir a conta.',
      specialRate: special);
  }
  if (plan.isNotEmpty && plan != 'free' && listed.isNotEmpty &&
      !listed.contains(plan)) {
    return VoiceAccessInfo(VoiceAccess.currentTierNotListed, 'Plano não listado',
      'O nível da sua assinatura não aparece entre os níveis disponíveis nesta voz.',
      specialRate: special);
  }
  return VoiceAccessInfo(VoiceAccess.unknown, 'Acesso a confirmar',
    'Não há confirmação suficiente de acesso à síntese. Algumas vozes da biblioteca pública exigem assinatura, mesmo quando a prévia funciona.',
    specialRate: special);
}
