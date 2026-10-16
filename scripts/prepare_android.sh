#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
if ! command -v flutter >/dev/null 2>&1; then
  echo 'Flutter SDK ausente. Instale Flutter stable e execute novamente.' >&2
  exit 1
fi
if [[ ! -f android/app/build.gradle.kts ]]; then
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  flutter create --no-pub --platforms=android --project-name=uaivozes --org=com.drilemoz "$tmp/uaivozes"
  cp -a "$tmp/uaivozes/android" ./android
fi
# Evita artefatos Android gerados anteriormente com a identidade antiga.
if ! grep -Eq 'applicationId[[:space:]]*=[[:space:]]*"com.drilemoz.uaivozes"' android/app/build.gradle.kts; then
  echo 'ERRO: applicationId não é com.drilemoz.uaivozes. Exclua android/ gerado e execute novamente.' >&2
  exit 1
fi
cp scripts/AndroidManifest.xml android/app/src/main/AndroidManifest.xml
# Integração leve com o seletor de documentos do Android (sem plugin extra).
mkdir -p android/app/src/main/kotlin/com/drilemoz/uaivozes
cp scripts/android/MainActivity.kt android/app/src/main/kotlin/com/drilemoz/uaivozes/MainActivity.kt
# O scaffold Flutter define minSdk/versionCode no Gradle a partir do pubspec.
# Assinatura de produção opcional via Secrets; nunca persistir keystore no ZIP.
if [[ -f android/app/build.gradle.kts && -n "${KEYSTORE_BASE64:-}" && -n "${KEYSTORE_PASSWORD:-}" && -n "${KEY_ALIAS:-}" && -n "${KEY_PASSWORD:-}" ]]; then
  printf '%s' "$KEYSTORE_BASE64" | base64 -d > android/app/release-key.jks
  python3 - <<'PY'
from pathlib import Path
p=Path('android/app/build.gradle.kts')
s=p.read_text()
if 'signingConfigs.getByName("release")' not in s:
    marker='    buildTypes {'
    assert marker in s, 'Layout de Gradle gerado não reconhecido'
    snippet='''    signingConfigs {
        create("release") {
            storeFile = file("release-key.jks")
            storePassword = System.getenv("KEYSTORE_PASSWORD")
            keyAlias = System.getenv("KEY_ALIAS")
            keyPassword = System.getenv("KEY_PASSWORD")
        }
    }
'''
    s=s.replace(marker,snippet+marker,1)
    marker2='signingConfig = signingConfigs.getByName("debug")'
    assert marker2 in s, 'Assinatura debug padrão Flutter não encontrada'
    s=s.replace(marker2,'signingConfig = signingConfigs.getByName("release")',1)
    p.write_text(s)
PY
else
  echo 'AVISO: sem quatro Secrets, APK release terá assinatura debug do template Flutter e não terá assinatura estável entre runners.' >&2
fi
