# Uai Vozes v0.11 · 0.1.0-alpha.11+11 (versionCode 11)

- Corrigida mensagem genérica de falha: o Estúdio agora apresenta etapa, status HTTP quando existe, orientações e botão de copiar resumo seguro.
- Diagnóstico registra código HTTP e categoria da operação, sem corpo da API, texto do usuário ou chave API.
- Priorizado salvamento do MP3 antes da contabilidade local, evitando perda do áudio por falha em preferências.
- Validação básica do cabeçalho MP3 impede salvar resposta HTML/JSON como arquivo de áudio.
- Nenhuma retentativa automática de geração: falhas ambíguas podem ter consumido créditos.
- Testes para resposta de erro, proteção de dados, áudio inválido, classificação por etapa e sucesso com MP3 válido.

**Limite da análise:** o print da v0.10 não informa o status HTTP; não é possível confirmar a causa externa (voz/plano/rede) sem novo diagnóstico ou log.

**Assinatura:** mesmos Secrets e `com.drilemoz.uaivozes`. APK previsto `Uai-Vozes-v0.11.apk`, separado do ZIP.

**Testes pendentes:** `flutter analyze`, `flutter test`, APK e verificação em aparelho via GitHub Actions.
