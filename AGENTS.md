# Instruções do projeto Uai, Vozes

- Stack Flutter Android, português do Brasil, dependências mínimas, foco em telas leves e baixo consumo.
- Não expor chaves API em código, logs, arquivos versionados ou testes.
- Preservar o layout clean dos cartões, tema branco/AMOLED preto puro/sistema, assistente e janela de novidades.
- Em TODA alteração, incrementar versão sequencial e versionCode (pubspec, JSON, README, CHANGELOG, RELEASE_NOTES, docs/VERSIONING, notas na tela Sobre, workflow e arquivo APK).
- Não inventar top 10 de vozes; sempre consultar o endpoint oficial ou mostrar falta de permissão/dados.
- Não repetir chamada TTS automaticamente, pois pode consumir créditos duplicados.
- Compilar APK separado do ZIP de código no artifact GitHub Actions e/ou Release.
- Validar flutter analyze, flutter test e build Android no GitHub Actions antes de afirmar APK testado.

- Diagnósticos: não registrar chaves, cabeçalhos, corpo HTTP, prompts/textos e caminhos externos. Limitar histórico a 100 eventos com exportação controlada pelo usuário.
