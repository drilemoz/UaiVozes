# Histórico de versões

## 0.1.0-alpha.17+17 · 16/10/2026

- Captura de restrições de vozes nos Diagnósticos: seleção bloqueada por metadados, verificação manual inconclusiva e erros de verificação, inclusão ou geração. Diferencia bloqueio confirmado por motivo da API de HTTP 402 sem causa confirmada.
- Novo `VoiceBlockDiagnostics` classifica etapas, origens e plano por listas seguras; vincula eventos pela referência derivada do ID sem registrar nome ou ID original, chave, texto, cabeçalhos ou corpo HTTP. Limite de 100 registros mantido.
- Tela Diagnóstico ganhou filtro de eventos de vozes aplicado também à cópia e exportação em TXT, sem apagar os demais eventos. Não há detecção automática por envio de textos, chamadas TTS extras ou verificações em lote.
- Sete testes Dart e três regressões Python adicionados; `flutter analyze`, `flutter test` e build Android aguardam execução no Actions.
- Metadados, workflow, documentação, notas no app e identificador Android sincronizados; quatro Secrets existentes preservados.

## 0.1.0-alpha.16+16 · 16/10/2026

- Relatório real do usuário `GERACAO_API | HTTP 402` revelou classificação imprecisa na interface; HTTP 402 normalmente representa pagamento requerido ou saldo insuficiente, não confirma bloqueio da voz.
- Atualizado `_fail` para preferir `detail.code` da documentação atual da ElevenLabs, com fallback ao `detail.status` legado, e aceitar apenas motivos explicitamente listados. Adicionado suporte a `insufficient_credits`, `subscription_required`, `feature_not_available`, `voice_access_denied`, `model_access_denied` e `insufficient_permissions`.
- Mensagens de TTS distinguem créditos insuficientes confirmados de HTTP 402 genérico, assinatura, e HTTP 403. Modal permite consultar créditos e consumo por GET, sem gerar áudio novamente.
- Sete testes Flutter adicionais garantem classificação, compatibilidade e privacidade; nenhum POST TTS automático adicional, logs sensíveis, dependência ou migração.
- Atualizados README, CHANGELOG, AGENTS, release, workflow, versionamento, metadados e novidades. `flutter analyze`, `flutter test` e compilação do APK alpha.15 ainda pendem de CI.

## 0.1.0-alpha.14+14 · 16/10/2026

- Workflow #13: `flutter analyze` aprovado (Flutter 3.47.7); `flutter test` concluiu com **60 testes aprovados e 1 falha**, em `test/api_test.dart:63`, antes da compilação APK.
- Causa provável da falha: `http.Response` de teste com corpo contendo acento e sem charset explícito usa Latin-1 por padrão; `_fail` tentava somente `utf8.decode(response.bodyBytes)` e perdia o motivo permitido `voice_not_found` ao descartar a exceção de decodificação.
- Corrigido `_fail` para tentar JSON UTF-8 primeiro e, se a leitura falhar, usar `response.body` (charset HTTP ou Latin-1 padrão). Preserva somente motivos da lista permitida; não registra corpo, texto, chave ou mensagens do servidor.
- Três novos testes Flutter para erros HTTP 422 com UTF-8 explícito, motivo desconhecido e corpo inválido; o teste original de uma única chamada TTS permanece.
- Versão, documentação, novidade no app e workflow atualizados para v0.14; certificado e quatro Secrets preservados. Flutter analyze/test da nova versão e compilação ARM64 permanecem pendentes no GitHub Actions.

## 0.1.0-alpha.13+13 · 16/10/2026

- Corrigido o bloqueio do workflow #12 em `flutter analyze` causado por `unnecessary_import` em `lib/src/studio_page.dart:2` (importação redundante de `dart:typed_data`).
- Mantido `package:flutter/services.dart`, que fornece o símbolo necessário; nenhuma alteração na lógica do Estúdio, TTS, biblioteca ou persistência.
- Adicionado teste Python preventivo para a regressão de imports no Estúdio.
- Sincronizados versão, notas, APK externo, artifact, metadados e instruções de publicação, sem tocar em credenciais ou assinatura Android.
- Os seis testes Python do run #12 e a validação de estrutura passaram, mas o workflow foi interrompido antes de `flutter test` e `flutter build apk`. Esses passos ainda exigem novo CI.

## 0.1.0-alpha.12+12 · 16/10/2026

- Explorador: estados conservadores de acesso de vozes com dados `available_for_tiers` e `free_users_allowed` retornados pela API. Sem informação suficiente, mostra “Acesso a confirmar”.
- Aviso de tarifa específica e bloqueio preventivo de seleção/geração somente quando há restrição explícita ao plano atual.
- Estúdio: rascunhos nomeados (até 20) além do salvamento automático; importar TXT com seletor SAF e dividir textos longos em partes de até 5.000 caracteres.
- Incluídos testes de dados de voz, persistência defensiva de rascunhos e divisão Unicode. Nenhuma geração automática adicional.
- Versão e documentação sincronizadas; mesmo `applicationId` e certificado de assinatura.

## 0.1.0-alpha.11+11
- Diferencia erro de API (HTTP), falha de salvamento e erro interno, com orientação e cópia segura.
- Salva MP3 antes de contabilizar consumo local; valida assinatura MP3.
- Novos testes de regressão e versão sincronizada.

## 0.1.0-alpha.10+10 · 16/10/2026
- Busca de vozes via API v2 com 400 ms de debounce e paginação por token, evitando resultados perdidos em páginas não carregadas.
- Novos filtros por finalidade, gênero, faixa etária e sotaque, usando parâmetros oficialmente aceitos. Estilo local conforme metadados disponíveis.
- Cache de metadados apenas em RAM por até três minutos e dez páginas, invalidado ao trocar API key ou idioma.
- Proteção contra resultados atrasados, controle aprimorado das prévias e cancelamento de assinaturas do player.
- Top 10 público real permanece distinto do catálogo da conta. Novos testes de requisições, paginação, cache e expiração. Sem bibliotecas novas.
- Identificador Android `com.drilemoz.uaivozes`, certificado e quatro Secrets preservados. Testes Flutter e build real pendentes de CI.


## 0.1.0-alpha.9+9 · 16/10/2026
- Central de créditos ampliada com histórico local de até 60 gerações, armazenando apenas data, modelo, caracteres e referência estimada, sem texto ou chave.
- Alertas visuais opcionais para 50%, 80% e 95% do limite consultado via API, sem notificações em segundo plano.
- Estimativa base de consumo revisada: custo real pode incluir multiplicadores de voz e condições da conta; uso oficial e histórico local permanecem separados.
- Proteção contra resultados atrasados de consultas da conta antiga depois da troca de chave API.
- Novos testes Flutter para estimador, histórico, JSON inválido e faixas de aviso. Manteve assinatura, identificador e fluxo do GitHub Manager.
- Compilação APK e testes Flutter da alpha.9 pendentes do GitHub Actions.


## 0.1.0-alpha.8+8 · 16/10/2026
- Corrigido o workflow #8: os Secrets estavam presentes somente na etapa de preparação Android, não no `flutter build apk`. Isso deixava `storePassword` vazio em `:app:packageRelease`.
- Incluídos os quatro Secrets também no ambiente de compilação Gradle; keystore e alias validados antecipadamente, sem exibir senhas.
- Adicionados testes de regressão para garantir que os Secrets cheguem à preparação e ao build. Identidade, assinatura e dados de versões anteriores preservados.
- Logs do build #8 confirmam `flutter analyze` aprovado e 32 testes Flutter aprovados para a v0.07. APK v0.08 ainda precisa ser compilado.

## 0.1.0-alpha.7+7 · 16/10/2026
- Corrigida a falha do workflow #7: `validate_source.py` analisava todo o workspace após `flutter pub get`, rejeitando `.dart_tool` e o Android gerado apesar de não estarem no ZIP ou no Git.
- Verificação de higiene agora consulta o índice Git no CI ou um ZIP explicitamente informado com `--archive`, protegendo contra distribuição de caches e chaves privadas sem bloquear arquivos temporários do compilador.
- Corrigido teste de identidade que ainda exigia v0.05 e adicionado conjunto de três testes Python para prevenir a regressão.
- Ajustado `.gitignore`: `/android/` ignora somente o Android gerado, preservando `scripts/android/MainActivity.kt` necessário para importar/exportar a chave API.
- Versão, APK, artefato, tags, README, notas de release, Sobre e documentação sincronizados. Assinatura e applicationId preservados.

## 0.1.0-alpha.6+6 · 16/10/2026

- **Estúdio:** bloqueio síncrono enquanto a caixa de confirmação está aberta e trava de TTS no `AppModel` para evitar requisições paralelas. Sem retentativa automática em falha incerta.
- **Biblioteca:** `AudioCatalog` separado com índice JSON salvo atomicamente e cópia íntegra, journal por MP3 para recuperar gerações interrompidas, migração sem excluir o índice legado das preferências e exclusão com preparação reversível.
- **Player:** assinaturas dos streams canceladas na desmontagem; erros assíncronos categorizados; MP3 aparece na biblioteca mesmo se o player falhar após salvar; pausar durante a reprodução permanece possível.
- **Diagnóstico:** gravações locais serializadas para impedir eventos antigos sobrescreverem novos ou reaparecerem após a limpeza.
- **GitHub Actions:** assinatura estável obrigatória via quatro Secrets; sem assinatura, build falha explicitamente em vez de publicar APK assinado pelo debug do runner. Artifact ARM64 inclui APK separado e SHA-256.
- Novos testes automatizados para recuperação, migração, exclusão e prevenção de dupla geração. Sem dependência Flutter adicional. `flutter analyze`, `flutter test` e build Android ainda pendentes de CI.

## 0.1.0-alpha.5+5 · 16/10/2026

- Nome público corrigido para **Uai Vozes** (sem vírgula). Identificador Android **preservado**: `com.drilemoz.uaivozes`, para permitir atualização sobre as versões anteriores com certificado igual.
- Linha compacta Colar / Testar / Guardar / Obter chave nas duas telas; importação TXT/ENV e exportação TXT com confirmação explícita de segredo não criptografado usando Storage Access Framework nativo, sem plugin Flutter adicional.
- Testar chave não salva mais automaticamente. Assistente bloqueia o avanço se a chave digitada ainda não foi guardada, oferecendo salvar e continuar.
- Segunda etapa do wizard carrega vozes portuguesas de `GET /v2/voices?language=pt`; ranking de pt inclui filtro `locale=pt-BR`. Fallback automático para inglês removido.
- Metadados simples traduzidos para português, com preservação dos nomes oficiais de vozes.
- Aviso opcional antes de sintetizar áudio, com caracteres e estimativa de créditos para Multilingual v2; preferência ativada por padrão, controlável em Ajustes.
- Versão, workflow, notas de atualização, metadados e testes sincronizados. Compilação Gradle/Flutter e teste de SAF Android pendentes.

## 0.1.0-alpha.4+4 · 16/10/2026

- Estúdio: indicador consultável de uso/limite do período ao lado do título, atualização da assinatura e referência aproximada de caracteres do texto antes de gerar e contador local do mês desde o início do acompanhamento. Não confunde contagem de caracteres com créditos exatos.
- Conta ElevenLabs em Ajustes: perfil autorizado, workspace parcialmente mascarado, plano, status, vagas de voz, ciclo, saldo, renovação e erros de permissão.
- Exibe novidades antes do assistente de primeira configuração.
- Explorar vozes: favoritas passa a ser filtro por ícone no cabeçalho; idioma e Minhas vozes/Top 10 em uma única linha rolável.
- Aparência: temas Branco, AMOLED e Sistema em seletor horizontal.
- Separação de modelos de assinatura/conta e componentes de consumo para facilitar testes e manutenção.
- Versão, Android versionCode e nome do APK sincronizados; sem alteração do package name e sem apagar áudios.

## 0.1.0-alpha.3+3 · 16/10/2026

- Botão **Obter chave API** no wizard e nas Configurações abre `https://elevenlabs.io/app/settings/api-keys` no navegador externo.
- **Guardar** e **Testar** agora mostram sucesso/erro no mesmo cartão do assistente e das Configurações, sem mensagens escondidas sob modal.
- **Sobre → Diagnóstico local** lista erros categorizados com data/hora e permite **Copiar**, **Exportar** relatório TXT via Android, **Fechar** e limpar histórico.
- Captura falhas não tratadas em Flutter UI, Dart/zone, e falhas conhecidas da API, biblioteca e player; limita registros locais a 100 e não serializa chave, textos, headers ou corpos da API.
- Atualizados testes, workflow, versionCode 3 e APK externo `Uai-Vozes-v0.03.apk`.

## 0.1.0-alpha.2+2 · 16/10/2026

- Renomeado para **Uai Vozes**, pacote Flutter `uaivozes`, applicationId `com.drilemoz.uaivozes` e metadados sincronizados.
- Corrigidos os seis avisos de Flutter `deprecated_member_use` em Configurações, substituindo propriedades obsoletas dos `RadioListTile` por `RadioGroup<ThemeMode>`.
- Ícone de launcher agora utiliza `@android:drawable/ic_btn_speak_now`, recurso oficial do Android, sem recursos extras.
- Workflow renomeado e APK ARM64 `Uai-Vozes-v0.02.apk` exportado como artifact independente; release opcional.
- Alterar applicationId impede atualização direta da instalação antiga e separa seus dados.

## 0.1.0-alpha.1+1 · 16/10/2026

1. Estúdio de texto para voz com salvamento MP3 e reprodução.
2. Explorador de vozes, prévias, favoritas, filtro e ranking real por idioma.
3. Biblioteca local, chave segura, temas claro/AMOLED/sistema, wizard, novidades, Sobre e Pix.

Próxima versão prevista: 0.1.0-alpha.18+18. Incrementar metadados, notas, pubspec, arquivos JSON e nome do APK.
