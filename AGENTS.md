# Instruções do projeto Uai Vozes

- Stack Flutter Android, português do Brasil, dependências mínimas, foco em telas leves e baixo consumo.
- Não expor chaves API em código, logs, arquivos versionados ou testes.
- Preservar o layout clean dos cartões, tema branco/AMOLED preto puro/sistema, assistente e janela de novidades.
- Em TODA alteração, incrementar versão sequencial e versionCode (pubspec, JSON, README, CHANGELOG, RELEASE_NOTES, docs/VERSIONING, notas na tela Sobre, workflow e arquivo APK).
- Não inventar top 10 de vozes; sempre consultar o endpoint oficial ou mostrar falta de permissão/dados.
- Não repetir chamada TTS automaticamente, pois pode consumir créditos duplicados.
- Compilar APK separado do ZIP de código no artifact GitHub Actions e/ou Release.
- Cobrir regressões de análise Flutter com testes de código-fonte quando possível; não declarar o lint aprovado até executar `flutter analyze`.
- Validar flutter analyze, flutter test e build Android no GitHub Actions antes de afirmar APK testado.

- Diagnósticos: não registrar chaves, cabeçalhos, corpo HTTP, prompts/textos e caminhos externos. Limitar histórico a 100 eventos com exportação controlada pelo usuário.

- Dados de consumo: nunca apresentar `character_count` como créditos faturados universais; distinguir informação da API e estimativa local.
- Fluxo inicial: abrir novidades antes do assistente de configuração.

- Assinatura release é obrigatória a partir da v0.06; sem os quatro Secrets de keystore, workflow deve falhar para não gerar APK que exige reinstalação. Não incluir keystore ou Secrets no ZIP.
- Biblioteca: preservar migração da antiga preferência `library`, catálogo atômico e journals. Não apagar áudio após falhas de índice; testes de recuperação devem ser mantidos.

- Higiene de distribuição: validar somente arquivos versionados no Git (`git ls-files`) ou entradas reais do ZIP (`--archive`), nunca o workspace gerado por `flutter pub get` ou por `prepare_android.sh`. A checagem de keystores privadas deve inspecionar fontes distribuídas, não a keystore temporária legítima do build.
- Os testes `test/identity_test.dart` devem sempre acompanhar o versionamento, sem constantes hardcoded de releases antigas.

- Não usar `android/` (sem barra inicial) no `.gitignore`: isso ocultaria `scripts/android/MainActivity.kt`; usar `/android/` para excluir só o Android gerado.

- Os Secrets de assinatura precisam estar no ambiente do passo `flutter build apk`, pois o `build.gradle.kts` os lê com `System.getenv`; nunca mover apenas para a preparação nem incluir credenciais no ZIP.
