import 'package:url_launcher/url_launcher.dart';
import 'diagnostics.dart';

const elevenApiKeysUrl = 'https://elevenlabs.io/app/settings/api-keys';

/// Abre sempre em navegador/aplicativo externo, sem renderizar páginas com chave no app.
Future<bool> openElevenApiKeys() async {
  try {
    final result = await launchUrl(Uri.parse(elevenApiKeysUrl),
        mode: LaunchMode.externalApplication);
    if (!result) AppDiagnostics.instance.warning('LINK_API', 'Navegador indisponível.');
    return result;
  } catch (e, stack) {
    AppDiagnostics.instance.capture('LINK_API', e, stack);
    return false;
  }
}
