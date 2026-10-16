# Uai, Vozes v0.03 · 0.1.0-alpha.3 (versionCode 3)

## Alterações

- Link oficial da ElevenLabs para criar chave API nas Configurações e assistente inicial.
- Mensagens visíveis ao salvar ou testar uma chave, com indicação de sucesso ou erro.
- Diagnóstico local em **Configurações → Sobre o Uai, Vozes → Erros do aplicativo**.
- Captura de falhas de Flutter e Dart e erros tratados de rede, geração, voz e reprodução; exportação TXT por compartilhamento Android ou cópia.
- Sem registro de chave API, texto convertido ou conteúdo privado de chamadas HTTP.
- Mantidos visual branco/AMOLED, biblioteca, ranking real condicionado a conta e demais recursos anteriores.

## APK

Após o workflow de compilação, `Uai-Vozes-v0.03.apk` será disponibilizado como artifact separado e, quando permitido, Release. Não há APK pré-compilado no ZIP de fontes.

## Validação

Foram validadas a integridade do ZIP e a estrutura local. Execução de `flutter analyze`, `flutter test` e `flutter build apk` permanece pendente no GitHub Actions.
