# Uai Vozes v0.14 · 0.1.0-alpha.14+14 (versionCode 14)

- Corrigido tratamento do motivo `voice_not_found` em HTTP 422 quando a resposta contém bytes Latin-1 sem charset declarado; tenta JSON UTF-8 primeiro e recorre a `Response.body` quando necessário.
- Dados privados enviados em mensagens de erro nunca são incluídos em relatórios; somente motivos explicitamente permitidos pela aplicação podem ser expostos.
- Mantidas trava global de geração, uma única solicitação TTS por ação, biblioteca, rascunhos, preferências e assinatura existente.
- Três novos testes de regressão para UTF-8, motivos desconhecidos e respostas inválidas; teste anterior HTTP 422 preservado.

**Assinatura Android:** utilize os mesmos quatro Secrets `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS` e `KEY_PASSWORD`. Identificador Android preservado: `com.drilemoz.uaivozes`. Nenhuma keystore foi gerada.

**Distribuição:** código-fonte em ZIP separado. No GitHub Actions, o APK ARM64 será publicado como `Uai-Vozes-v0.14.apk` no artifact `Uai-Vozes-v0.14-apk` somente após testes e compilação aprovados.

**Validação:** o workflow #13 aprovou `flutter analyze`, 60 testes Flutter e a validação Python/estrutura, mas falhou em um teste HTTP 422 antes do build. A análise Flutter, os testes e a compilação da alpha.14 ainda precisam ser executados no CI; sem confirmação de APK nem teste em Android físico.
