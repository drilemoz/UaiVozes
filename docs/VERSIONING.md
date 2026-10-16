# Versionamento sequencial

Versão atual: **0.1.0-alpha.2**, versionCode **2**.

Em toda modificação: incrementar versionName e versionCode e sincronizar `pubspec.yaml`, `app_identity.json`, `github-manager.json`, `CHANGELOG.md`, `RELEASE_NOTES.md`, `.github/workflows/gerar-apk.yml` (nome do APK/tag) e `lib/src/settings_page.dart` (notas e histórico). Não sobrescrever notas anteriores; mostrar últimas três versões em Sobre. Atualizar o controle da tela de novidades automaticamente pela versão.
