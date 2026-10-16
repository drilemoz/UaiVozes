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
  flutter create --no-pub --platforms=android --project-name=eleven --org=com.drilemoz "$tmp/eleven"
  cp -a "$tmp/eleven/android" ./android
fi
mkdir -p android/app/src/main/res/drawable
cp scripts/AndroidManifest.xml android/app/src/main/AndroidManifest.xml
cp assets/android/ic_eleven.xml android/app/src/main/res/drawable/ic_eleven.xml
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
