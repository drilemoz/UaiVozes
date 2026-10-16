#!/usr/bin/env python3
"""Validação estrutural do Uai Vozes sem exigir SDK Flutter/Android."""
import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VERSION = "0.1.0-alpha.6"
CODE = 6
APK = "Uai-Vozes-v0.06.apk"
PACKAGE = "com.drilemoz.uaivozes"

def content(path):
    return (ROOT / path).read_text(encoding="utf-8")

def check(condition, description):
    if not condition:
        raise AssertionError(description)
    print(f"OK: {description}")

def main():
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
    check("exit 1" in signing and "obrigatória" in signing.lower(), "assinatura estável obrigatória")
    manifest = ET.fromstring(content("scripts/AndroidManifest.xml"))
    app = manifest.find("application")
    label = app.attrib["{http://schemas.android.com/apk/res/android}label"]
    check(label == "Uai Vozes", "nome no launcher")
    check("AudioCatalog" in main_dart and "tryBeginGeneration" in main_dart,
          "biblioteca robusta e trava de TTS")
    check("# Uai Vozes v0.06" in content("RELEASE_NOTES.md"), "notas da release")
    check(f"## {VERSION}+{CODE}" in content("CHANGELOG.md"), "CHANGELOG atual")
    check(f"versionCode **{CODE}**" in content("docs/VERSIONING.md"), "guia de versionamento")
    check(all(not any(part in f.parts for part in (".dart_tool", ".gradle", "build"))
          for f in ROOT.rglob("*")), "sem caches compilados dentro do ZIP")
    check(not list(ROOT.rglob("*.jks")) and not list(ROOT.rglob("*.p12")),
          "sem keystore privada distribuída")
    print("VALIDAÇÃO ESTRUTURAL: OK")

if __name__ == "__main__":
    try:
        main()
    except (AssertionError, ValueError, KeyError, ET.ParseError) as exc:
        print(f"VALIDAÇÃO FALHOU: {exc}", file=sys.stderr)
        sys.exit(1)
