# Uai Vozes v0.08 · 0.1.0-alpha.8+8 (versionCode 8)

- Corrigido o GitHub Actions #8: a senha da keystore não chegava à etapa `flutter build apk`, causando `SigningConfig "release" is missing required property "storePassword"`.
- Os quatro Secrets de assinatura agora são disponibilizados tanto à preparação quanto à compilação, sem persistir senhas no repositório.
- Incluída verificação antecipada da keystore no script de preparação e testes contra regressão do workflow.
- Mantidos o mesmo certificado (Secrets existentes), identificador `com.drilemoz.uaivozes`, recursos, áudios locais e fluxo de atualização sem desinstalar.
- Confirmado pelo log #8: `flutter analyze` sem avisos e 32 testes Flutter aprovados para a v0.07. Novo build de APK ainda pendente.

APK previsto: `Uai-Vozes-v0.08.apk` no Artifact e opcionalmente em Releases, fora do ZIP de código, acompanhado do SHA-256 no Artifact.
