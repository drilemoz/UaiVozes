# Instruções do projeto Uai Vozes

- Stack Flutter Android, português do Brasil, dependências mínimas, foco em telas leves e baixo consumo.
- Não expor chaves API em código, logs, arquivos versionados ou testes.
- Preservar o layout clean dos cartões, tema branco/AMOLED preto puro/sistema, assistente e janela de novidades.
- Em TODA alteração, incrementar versão sequencial e versionCode (pubspec, JSON, README, CHANGELOG, RELEASE_NOTES, docs/VERSIONING, notas na tela Sobre, workflow e arquivo APK).
- Não inventar top 10 de vozes; sempre consultar o endpoint oficial ou mostrar falta de permissão/dados.
- Não repetir chamada TTS automaticamente, pois pode consumir créditos duplicados.
- Erros HTTP: tentar UTF-8 primeiro; permitir fallback de charset quando necessário, sem armazenar ou imprimir corpo remoto; somente motivos conhecidos da lista permitida. A documentação atual usa `detail.code` com fallback ao legado `detail.status`. HTTP 402 indica pagamento/crédito insuficiente, não confirma bloqueio de voz; distinguir códigos confirmados de hipótese. Manter regressões para respostas acentuadas sem charset (HTTP 422), JSON inválido, códigos inesperados e HTTP 402 sem `code`.
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

- Filtros de compatibilidade: só considerar "compatível" quando `available_for_tiers` contém o tier atual. Não transformar `free_users_allowed` em prova de geração, nem classificar voz sem metadados como grátis. Voice Library pública via API não atende contas Free segundo documentação em 16/10/2026; consultar novamente se API mudar. Consultar detalhes apenas por toque (GET), nunca emitir TTS para testar acesso, proteger trocas de chave/idioma e filtros contra dados antigos.

- Ao registrar restrições de vozes, nunca salvar nome, ID completo, prompt, chave, texto de erro, URL ou corpo HTTP. Capturar só após ação do usuário (selecionar, verificar, gerar); não registrar cada linha da lista nem disparar TTS de teste.
- Diagnóstico diferencia restrição explicitamente informada pela API/metadados de HTTP 402 ambíguo. O filtro de eventos de voz aplica-se também à exportação/cópia; conservar limite de 100 registros.

- A partir da alpha.18: filtros de compatibilidade exigem tiers explícitos, não confundir voz da conta com autorização comprovada. O endpoint /v2/voices permite `voice_type`, mas não possui filtro direto por assinatura; checagens adicionais devem ser GET manual por ação explícita, sem TTS e limitadas.
- Exclusão de voz: somente após confirmação do usuário e resposta `status: ok` da API DELETE; não apagar MP3 local, nem repetir DELETE automaticamente. Bloquear padrão/legada; remover seleção/favorito somente depois de sucesso.
- Diagnóstico: exportar o conteúdo UTF-8 completo por SAF (`exportDiagnostic`) e tratar cancelamento sem marcar sucesso. Nenhum dado privado no log/arquivo além de campos seguros. Copiar/Exportar/Excluir organizados na mesma faixa.
- Sobre só histórico/doação; acesso Diagnóstico em Ajustes junto de O que mudou?.

- Alpha.19: separar filtro estrito `Compatíveis com meu plano` de `Na minha conta (possíveis)`. `/v2/voices` é catálogo da conta, não garantia de TTS. O filtro de candidatas só pode funcionar em Minhas vozes e deve excluir bloqueios explicitamente confirmados. No Top 10 Free, explicar indisponibilidade da biblioteca pela API, oferecer Minhas vozes sem preservar filtros incompatíveis. HTTP 402 sem motivo continua ambíguo. Não fazer POST/TTS para verificar voz, nem afirmar gratuidade na ausência de `available_for_tiers`.

- Alpha.20: blocos de filhos Flutter `if / else if / else` devem manter o `else` imediatamente ligado à cadeia; widgets auxiliares (ex.: Consultar vozes padrão) precisam vir depois, em `if` independente. Adicionar e manter teste estático de regressão; no CI executar `flutter analyze` antes de `flutter test` e APK.
