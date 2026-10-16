#!/usr/bin/env python3
"""Validação estrutural do Uai Vozes sem exigir SDK Flutter/Android."""
import argparse
import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

from source_hygiene import distribution_paths, prohibited_paths

ROOT = Path(__file__).resolve().parents[1]
VERSION = "0.1.0-alpha.18"
CODE = 18
APK = "Uai-Vozes-v0.18.apk"
PACKAGE = "com.drilemoz.uaivozes"

def content(path):
    return (ROOT / path).read_text(encoding="utf-8")

def check(condition, description):
    if not condition:
        raise AssertionError(description)
    print(f"OK: {description}")

def main(source_archive=None):
    pubspec = content("pubspec.yaml")
    check(re.search(r"^name: uaivozes$", pubspec, re.M) is not None, "pacote Dart")
    check(f"version: {VERSION}+{CODE}" in pubspec, "versão pubspec")
    identity = json.loads(content("app_identity.json"))
    manager = json.loads(content("github-manager.json"))
    for metadata in (identity, manager):
        check(metadata["versionName"] == VERSION, "nome da versão JSON")
        check(metadata["versionCode"] == CODE, "versionCode JSON")
        check(metadata["apkFileName"] == APK, "nome do APK JSON")
    check(identity["packageName"] == PACKAGE, "applicationId persistente")
    main_dart = content("lib/src/app_model.dart")
    check(f"static const version = '{VERSION}'" in main_dart, "versão exibida")
    check(f"static const versionCode = {CODE}" in main_dart, "código exibido")
    settings = content("lib/src/settings_page.dart")
    check(f"'{VERSION}': [" in settings, "notas da versão na tela Sobre")
    workflow = content(".github/workflows/gerar-apk.yml")
    check(APK in workflow and f"tag_name: v{VERSION}" in workflow, "APK/tag do workflow")
    check("flutter analyze" in workflow and "flutter test" in workflow, "análise e testes CI")
    signing = content("scripts/prepare_android.sh")
    for name in ("KEYSTORE_BASE64", "KEYSTORE_PASSWORD", "KEY_ALIAS", "KEY_PASSWORD"):
        check(name in signing and f"secrets.{name}" in workflow, f"secret {name}")
    # Sem estas variáveis NO PASSO de build, o Gradle recebe storePassword=null.
    build_step = re.search(r"(?ms)^      - name: Compilar APK ARM64 otimizado\n(?P<body>.*?)(?=^      - name:|\Z)", workflow)
    check(build_step is not None, "passo de compilação identificado")
    for secret in ("KEYSTORE_BASE64", "KEYSTORE_PASSWORD", "KEY_ALIAS", "KEY_PASSWORD"):
        check(f"{secret}: ${{{{ secrets.{secret} }}}}" in build_step.group("body"),
              f"secret {secret} disponível durante Gradle")
    check("exit 1" in signing and "obrigatória" in signing.lower(), "assinatura estável obrigatória")
    check("-storepass:env KEYSTORE_PASSWORD" in signing and "-alias \"$KEY_ALIAS\"" in signing,
          "keystore verificada antes do build sem expor senha em argumentos")
    manifest = ET.fromstring(content("scripts/AndroidManifest.xml"))
    app = manifest.find("application")
    label = app.attrib["{http://schemas.android.com/apk/res/android}label"]
    check(label == "Uai Vozes", "nome no launcher")
    check("AudioCatalog" in main_dart and "tryBeginGeneration" in main_dart,
          "biblioteca robusta e trava de TTS")
    check(f"# Uai Vozes v0.{CODE:02d}" in content("RELEASE_NOTES.md"), "notas da release")
    check(f"## {VERSION}+{CODE}" in content("CHANGELOG.md"), "CHANGELOG atual")
    check(f"versionCode **{CODE}**" in content("docs/VERSIONING.md"), "guia de versionamento")
    # No GitHub Actions, flutter pub get/flutter create criam .dart_tool/, android/
    # e a keystore de release em tempo de execução. Inspecionar ROOT.rglob(*)
    # rejeitaria esses arquivos legítimos apesar de não estarem versionados.
    paths = distribution_paths(ROOT, source_archive)
    if paths is None:
        print("AVISO: sem Git neste diretório; passe --archive <ZIP> para verificar os arquivos distribuídos")
    else:
        check("scripts/android/MainActivity.kt" in paths, "ponte Kotlin nativa incluída na distribuição")
        rejected = prohibited_paths(paths)
        check(not rejected, "distribuição sem caches, Android gerado ou chaves privadas"
              + (f": {', '.join(rejected[:5])}" if rejected else ""))
    print("VALIDAÇÃO ESTRUTURAL: OK")

if __name__ == "__main__":
    try:
        parser = argparse.ArgumentParser(description="Validação do Uai Vozes")
        parser.add_argument('--archive', type=Path,
                            help="ZIP de origem a inspecionar fora de um checkout Git")
        args = parser.parse_args()
        main(args.archive)
    except (AssertionError, ValueError, KeyError, ET.ParseError, OSError) as exc:
        print(f"VALIDAÇÃO FALHOU: {exc}", file=sys.stderr)
        sys.exit(1)
