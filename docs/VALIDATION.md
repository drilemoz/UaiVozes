# Estado de validação da alpha.1

Validações **executadas no ambiente de geração**:

- YAML do pubspec/workflow, JSONs e XMLs analisados sem erro.
- `bash -n scripts/prepare_android.sh` passou.
- Verificação léxica estática de equilíbrio de parênteses, colchetes e chaves de todos os arquivos Dart passou (não substitui compilação).
- ZIP de distribuição deve ser verificado por integridade CRC e presença de arquivos importantes.

**Não executados neste ambiente:** `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build apk`, instalação Android, acesso autenticado à ElevenLabs, teste de voz real e qualidade do layout no aparelho. Flutter SDK/Android SDK estão ausentes e o ambiente não resolve os servidores de download.

**Próxima validação real:** GitHub Actions `Gerar APK Eleven` executa Flutter stable, testes e compilação. Sem resultado verde do workflow, não afirmar que o APK compila. Se houver erro, corrigir com base nos logs e incrementar versão para 0.1.0-alpha.2+2.
