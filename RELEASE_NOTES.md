# Uai Vozes v0.13 · 0.1.0-alpha.13+13 (versionCode 13)

- Correção do workflow #12: removida importação redundante de `dart:typed_data` no Estúdio, que fazia o `flutter analyze` falhar por `unnecessary_import` com Flutter 3.47.7.
- Mantidos editor de textos, catálogo de vozes, controle de créditos, geração ElevenLabs e biblioteca sem alteração comportamental.
- Incluído teste Python de regressão para o import e sincronizados nomes, versão, workflow e notas.

**Assinatura Android:** usar exatamente os quatro Secrets existentes `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS` e `KEY_PASSWORD`. Não há nova chave nem mudança do identificador `com.drilemoz.uaivozes`.

**Distribuição:** código-fonte em ZIP separado; após compilação confirmada pelo GitHub Actions, o APK será publicado como `Uai-Vozes-v0.13.apk` no artifact `Uai-Vozes-v0.13-apk`.

**Validação:** o run #12 aprovou seis testes Python e a verificação estrutural, mas parou no analisador antes dos testes Flutter e do APK. A análise Flutter corrigida, os testes Flutter, a compilação e a instalação Android ainda precisam de confirmação no próximo run.
