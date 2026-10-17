# Uai Vozes 🎙️

Uai Vozes é um aplicativo Flutter Android leve para converter textos em áudio com **ElevenLabs**, com design inspirado em cartões limpos, filtro compacto, wizard, novidades, conta e consumo e preto AMOLED real.

Versão: **0.1.0-alpha.26+26** · APK pretendido: **Uai-Vozes-v0.26.apk** · Pacote Android: `com.drilemoz.uaivozes`.

Identidade do launcher: **ícone de microfone nativo do Android** (`@android:drawable/ic_btn_speak_now`), sem assets de imagem extras.

**Identificador estável:** `com.drilemoz.uaivozes` permanece igual desde a alpha.2 para permitir atualizações sem perda de dados, quando a assinatura do APK é a mesma.

## Alpha.26 (leitura Android + verificação de exportação)

- Retorno da leitura de textos pelo sintetizador Android (`android_speech`), inclusive atalho após HTTP 402. Não consome ElevenLabs e não exporta MP3; a disponibilidade offline depende do sintetizador instalado.
- Quando a última consulta oficial informa saldo zero, atualizar por GET antes do POST TTS. Sem confirmação de saldo positivo, não gerar; evitar chamadas duplicadas cobradas.
- Mantém o salvamento MP3 pelo SAF da alpha.25, com verificação adicional do arquivo antes da cópia, do tamanho efetivamente escrito e tratamento do cancelamento.
- Corrigido `test/audio_export_test.dart`, que continha expressão Dart inválida para repetição de string. Testes Dart/Flutter e APK precisam ser executados em CI para validação real.

## Alpha.25 (salvar MP3)

- Biblioteca com **Compartilhar** e **Salvar MP3** (seletor nativo do Android); sem rede e sem permissão ampla de armazenamento.

## Alpha.24 (seletor de modelo)

- Estúdio com escolha entre Multilingual v2 e Flash v2.5; estimativa de créditos e histórico seguem o modelo (valores de referência da ElevenLabs).

## Alpha.23 (vozes validadas por geração)

- Selo **Já gerou áudio nesta conta** e filtro de visto na tela Vozes; registro local, por conta, sem chamadas extras à API.

## Alpha.22 (atalho para vozes padrão)

- O aviso de HTTP 402 no Estúdio oferece **Ver vozes padrão da minha conta**, que abre a aba Vozes já filtrada (GET, sem gerar áudio).

## Alpha.21 (diagnóstico real: 402 e Top 10)

- HTTP 402 com plano Free: mensagem aponta a restrição de vozes da biblioteca pública pela API e sugere voz padrão; motivos `payment_required`/`paid_plan_required` reconhecidos.
- Top 10 sem idioma: orientação na tela, sem erro no diagnóstico.
- Análise Flutter, testes e APK v0.26 dependem do GitHub Actions.

## Correção da alpha.20 (workflow #19)

- Workflow `Gerar APK Uai Vozes` v0.19: 22 testes Python e validação estrutural aprovados; `flutter analyze` falhou com 3 erros de sintaxe em `lib/src/voices_page.dart:810` e `:816` antes do `flutter test` e do APK.
- Corrigido o bloco da lista com `if / else if / else ...visible.map(...)` e movido o botão de consultar vozes padrão para fora dessa cadeia. Mantidas as condições de ausência de chave, erro da API, lista vazia, vozes carregadas e carregamento.
- Teste estático de regressão protege a ordem dos blocos e a separação entre lista e botão. Nenhuma chamada de API, TTS, assinatura ou persistência alterada.
- A análise Dart/Flutter, os testes Flutter e a compilação APK v0.20 precisam ser executados pelo GitHub Actions; nenhum APK foi gerado localmente.

## Novidades da alpha.19 (Top 10 Free e vozes da conta)

- Após relatório real de plano Free com 27 eventos no Diagnóstico, o filtro estrito não exibe vozes porque a API não enviou `available_for_tiers` e a Voice Library pública bloqueia uso via API no Free. HTTP 402 sem `detail.code` continua inconclusivo: pode indicar cobrança/créditos, não prova voz bloqueada.
- O filtro **Na minha conta (possíveis)** lista vozes já retornadas por `GET /v2/voices` que não tenham restrições explícitas. Inclui acesso desconhecido com etiqueta **Acesso a confirmar**, mas **não** as chama de confirmadamente compatíveis/grátis e não faz TTS de verificação.
- Quando **Compatíveis com meu plano** fica vazio, a tela orienta e permite ir diretamente às vozes da conta. No Top 10 com Free, avisa sobre restrição da biblioteca; na conta, se não houver candidatas, sugere consultar vozes padrão usando `voice_type=default`.
- Filtros aplicados localmente às páginas carregadas. A verificação opcional de até dez detalhes continua manual, por GET, sem retentativas nem gastos de geração. Não altera biblioteca, textos, keystore, quatro Secrets ou identificador do Android.

## Novidades da alpha.18 (Explorador compacto e diagnóstico)

- Explorador de vozes com uma linha de navegação, 🇧🇷 Português e folha inferior de filtros para Minhas vozes e Top 10. Finalidade, gênero, idade, sotaque e tipo de voz seguem os parâmetros oficiais da API; estilo é local em Minhas vozes; categoria da biblioteca e gênero/idade/sotaque são enviados à API no Top 10. Contagem/refinamento de acesso são locais às páginas carregadas.
- Textos explicativos longos substituídos por botões `?` específicos para Minhas vozes, Top 10 e compatibilidade. Filtro de plano sem correspondências não significa bloqueio: a API não tem filtro por assinatura. Consulta manual limitada a até 10 GETs por ação, sem TTS, cache em memória e proteção contra troca de conta/aba.
- Menu ⋮ nas vozes da conta: remoção com confirmação via DELETE /v1/voices/:voice_id, sem retry; preserva MP3s e remove seleção/favorito locais somente após confirmação da API. Vozes padrão e legadas não são oferecidas para remoção.
- Diagnóstico movido de Sobre para Ajustes, ao lado de O que mudou?; Copiar, Exportar e Excluir na mesma faixa. Exportar usa ACTION_CREATE_DOCUMENT no Kotlin para salvar o TXT UTF-8 completo, em vez de Sharesheet que em certos destinos mostrava apenas o título.
- Não adiciona dependências, não toca na keystore/Secrets nem altera identificador Android. Compilação/testes Flutter reais continuam pendentes do Actions.

## Novidades da alpha.17 (captura de bloqueios de vozes)

- Diagnóstico local registra **restrição detectada por metadados** quando o usuário tenta escolher voz bloqueada no Explorador ou Estúdio, ou quando a verificação manual por GET confirma restrição. Não registra a listagem, a busca nem a mudança de filtro, para não poluir o histórico.
- Falhas da API ao verificar/adicionar voz ou gerar áudio guardam somente HTTP, código permitido, etapa da operação, plano (quando reconhecido) e referência de correlação derivada do ID. Nome e ID original da voz, mensagem/corpo HTTP, prompt e chave não são persistidos.
- **HTTP 402 sem código não é tratado como bloqueio de voz confirmado**, pois também pode indicar cobrança/créditos. Consultas sem metadados conclusivos são distinguidas de bloqueios.
- Ajustes > Diagnóstico local ganhou filtro **Somente eventos de vozes** com cópia/exportação apenas dos registros exibidos. Limite anterior de 100 registros, botão Limpar e persistência foram mantidos.
- Nenhuma dependência nova, chamada TTS extra, alteração de Secrets ou migração de arquivos. Testes Flutter/Android exigem execução CI.

## Novidades da alpha.16 (filtro de compatibilidade de vozes)

- Novo filtro local de acesso: Todas, **Compatíveis com meu plano**, Restritas e A confirmar; usa exclusivamente os resultados já carregados e o tier da assinatura consultada. Paginação e busca global continuam funcionando, sem insinuar que uma página abrange todo o catálogo.
- Compatível segundo a API requer `available_for_tiers` contendo explicitamente o nível da assinatura. É indício de acesso à voz, **não** prova de créditos, geração gratuita, custos ou liberação do modelo.
- A informação `free_users_allowed` regula novas adições de vozes compartilhadas por Free, não deve bloquear a síntese de uma voz já existente em Minhas vozes. Segundo a documentação da ElevenLabs, a biblioteca pública não está disponível via API para Free.
- Vozes sem metadados suficientes ficam **A confirmar** e têm botão manual para consultar `GET /v1/voices/:voice_id`, sem chamadas TTS. Informações recebidas ficam somente na memória e não sobrescrevem nome, ranking, favoritos ou dados pessoais; troca de conta/idioma descarta dados antigos.
- Se a assinatura ainda não foi consultada, botão **Consultar plano** faz somente a consulta de uso/assinatura. Mudança do plano recalcula os filtros sem chamadas TTS.
- Sem dependências ou migração, preservando assinatura, Secrets, rascunhos e biblioteca. Verificação Flutter e build APK pendentes do Actions.

## Novidades da alpha.15 (diagnóstico de HTTP 402)

- O relatório real `GERACAO_API | HTTP 402` era classificado genericamente como bloqueio de voz/chave. Segundo a documentação atual da ElevenLabs, HTTP 402 aponta créditos insuficientes ou pagamento exigido, sem comprovar que a voz está bloqueada.
- Mensagem de geração atualizada: diferencia HTTP 402 sem motivo explícito, `insufficient_credits` confirmado, restrição de assinatura e HTTP 403 de acesso, com indicação de onde conferir o consumo e botão local para consultá-lo.
- `_fail` agora prioriza `detail.code` (API atual), com fallback `detail.status` legado, e só aceita motivos previamente permitidos. Nenhuma mensagem privada da API, texto nem chave é copiada para diagnóstico.
- Novos testes com respostas HTTP 402 simuladas, uma única requisição TTS e proteção de dados; a v0.15 ainda precisa de CI/Flutter e APK.
- Nenhuma alteração em assinatura, base de dados, dependências ou chave API. Esta correção não adiciona créditos nem remove restrições reais impostas pela ElevenLabs.

## Novidades da alpha.14 (correção de resposta HTTP 422)

- O workflow #13 passou no `flutter analyze` e executou 61 testes Flutter: 60 aprovados e 1 reprovado (`test/api_test.dart`, motivo `voice_not_found` retornando `null`). A compilação APK não foi iniciada.
- A extração de um motivo de erro permitido agora tenta primeiro UTF-8 e, apenas se necessário, usa a decodificação do pacote `http` para respostas sem charset ou Latin-1; o corpo da API continua privado.
- Adicionados três testes Flutter de regressão para HTTP 422 (UTF-8 com charset, motivo desconhecido e resposta inválida), além do teste anterior de texto acentuado sem charset.
- Nenhuma retentativa TTS automática, novo Secret, dependência, migração de dados ou alteração de certificado. `flutter test` e APK alpha.14 requerem o próximo GitHub Actions.

## Novidades da alpha.13 (correção de análise Flutter)

- O workflow #12 parou no `flutter analyze` porque `dart:typed_data` foi importado desnecessariamente em `studio_page.dart`; essa importação foi removida, sem alterar o comportamento do Estúdio.
- Adicionado teste de regressão Python e sincronizados os metadados, notas e nomes do APK/artifact.
- Preservados identificador Android, keystore e os quatro Secrets já configurados. Testes Flutter, APK e instalação continuam pendentes do próximo GitHub Actions.

## Novidades da alpha.12 (vozes com restrição e editor de textos)

- Sinais informados pela API: `available_for_tiers`, `free_users_allowed` e presença de tarifa específica; avaliações conservadoras e sem classificação inventada.
- Explorador e Estúdio evitam escolher uma voz com bloqueio explícito para o nível conhecido da assinatura.
- Editor com rascunhos nomeados locais (máximo 20), importação de TXT via SAF nativo (até 50 mil caracteres), recuperação confirmada e divisão em partes com até 5 mil caracteres. Cada parte exige geração individual, com confirmação de consumo quando ativada.
- Não adiciona bibliotecas de terceiros nem inclui tokens, prompts ou áudio nos diagnósticos.

## Novidades da alpha.10 (Explorador de vozes 2.0)

- Busca global na API e paginação em blocos de até 30 vozes, sem limitar a busca à primeira tela.
- Filtros por finalidade, gênero, faixa etária e sotaque aceitos pela API; estilo local conforme metadados recebidos.
- Cache de metadados só em memória (3 minutos/10 páginas), descarte de respostas antigas e limpeza após troca de chave.
- Prévias podem ser paradas/trocadas sem aguardar o término da reprodução, com tratamento de erros.
- Minhas vozes permanece separado do Top 10 público real; ranking sujeito às permissões da conta.
- Adicionados testes de API e cache, sem novas dependências; assinatura de produção preservada.

## Novidades da alpha.9 (central de créditos)

- Histórico local de até 60 gerações com horário, caracteres, modelo e estimativa base, sem guardar prompts, voz ou API key nesse histórico. A contagem mensal pré-existente é preservada; o histórico detalhado começa na alpha.9.
- Aviso opcional no Estúdio e na consulta de consumo quando o uso oficial alcançar 50%, 80% ou 95% do limite. Controlável em Configurações, sem notificações em segundo plano.
- Estimativa base de aproximadamente um crédito por caractere para o modelo Multilingual v2, sujeita a multiplicadores de vozes e plano. Outros modelos sem tarifa confirmada não recebem estimativa inventada.
- Proteção para que dados de assinatura ou usuário consultados com a chave anterior não apareçam após troca de chave.
- Novos testes `credit_ledger_test.dart` e versão sequencial sincronizada. APK exige os mesmos quatro Secrets.

## Novidades da alpha.8 (correção do workflow #8)

- Corrigido `SigningConfig "release" is missing required property "storePassword"`: os quatro Secrets agora estão presentes também na etapa `flutter build apk`, onde o Gradle assina o APK.
- `prepare_android.sh` valida antecipadamente a keystore e o alias sem colocar a senha em argumentos ou logs.
- Novo teste Python regressivo para garantir assinatura configurada em ambas as etapas.
- **Não altere** os quatro Secrets de assinatura já importados. Use a mesma keystore para atualizar sem desinstalar.

## Novidades da alpha.7 (correção do workflow #7)

- Corrigida a verificação da distribuição: caches de `flutter pub get`, Android gerado e keystore temporária **não** são interpretados como arquivos enviados ao repositório.
- O validador inspeciona somente caminhos versionados (`git ls-files`) no CI, ou entradas reais de um ZIP pelo argumento `--archive`.
- Incluídos testes Python para distinguir arquivos temporários legítimos de chaves ou caches indevidamente distribuídos.
- Teste Flutter de identidade atualizado para comparar a versão atual com metadados, evitando expectativas fixas da alpha.5.
- `.gitignore` agora ignora apenas o Android compilado em `/android/` e preserva a integração Kotlin de `scripts/android/`.
- A assinatura e identificador Android permanecem inalterados; APK não foi compilado neste ambiente.

## Novidades da alpha.6 (estabilidade)

- Uma solicitação de geração por vez no modelo compartilhado, inclusive durante a confirmação de créditos; sem retentativa automática após falhas de rede.
- Biblioteca com índice JSON e backup no diretório privado; migração automática da lista da v0.05, preservando a preferência antiga para recuperação. Journals permitem recuperar MP3s salvos durante interrupções.
- Erros de reprodução separados de erros de salvamento: áudio gerado permanece acessível na Biblioteca mesmo que o player não o abra.
- Diagnósticos com persistência serializada; streams de áudio cancelados ao desmontar páginas.
- APK de GitHub Actions exige assinatura via os quatro Secrets. Sem eles o workflow falha e não publica APK temporariamente assinado. Artifact inclui checksum SHA-256.

## Alterações da alpha.5

- Nome visível **Uai Vozes**, sem vírgula, inclusive launcher, telas e workflow. `com.drilemoz.uaivozes` já era o identificador correto e foi preservado para não quebrar atualizações.
- Colar, Testar, Guardar e Obter chave na mesma linha, no wizard e em Ajustes; Importar no wizard e Importar/Exportar nas Configurações.
- **Testar não salva a chave**. Caso o usuário tente avançar com uma chave diferente da salva, o assistente solicita autorização para guardar, bloqueando o avanço se cancelar ou falhar.
- Importação/exportação por documentos do Android (TXT/ENV) sem biblioteca Flutter extra. Exportar exige confirmação porque o arquivo **não é criptografado**. A chave continua segura localmente enquanto não é exportada.
- Assim que conclui a etapa da chave, o wizard pede vozes associadas a português pela API e exibe a lista; sem retorno, mostra indisponibilidade. A opção Top 10 pt usa `language=pt` e `locale=pt-BR`.
- Confirmação opcional do gasto estimado antes de TTS, habilitada inicialmente e configurável em Ajustes. Estimativa de 1 crédito por caractere para o modelo padrão, sujeita à cobrança efetiva.

## Funcionalidades

- No topo do **Estúdio**, consulta de consumo e limite atual do período, com aviso sobre o significado de `character_count`; atualização após geração de áudio bem-sucedida.
- **Ajustes → Conta ElevenLabs** com dados permitidos por `GET /v1/user` e `GET /v1/user/subscription`, incluindo fallback se o escopo User: Read não estiver liberado.
- Novidades antes do wizard inicial; favoritas em ícone; temas em uma linha horizontal.

- Estúdio de texto até 5.000 caracteres por geração, ElevenLabs `eleven_multilingual_v2` e MP3 44.1 kHz/128 kbps.
- Vozes da conta via `GET /v2/voices` paginado; filtros de idioma e uso, pesquisa, prévia e favoritas locais.
- Top 10 por idioma/categoria, com **ordenação real por `usage_character_count_1y`**, via `GET /v1/shared-voices`. Não simula rankings se não autorizado.
- Adição consentida de voz compartilhada à conta antes da conversão.
- Biblioteca de MP3 salvos em diretório privado, reprodução e compartilhamento/exportação via menu Android.
- Chave API segura via Android Keystore; colar, copiar, mostrar, testar, remover e abrir o link oficial para obter uma chave.
- Mensagens visíveis dentro do assistente e nas Configurações para salvar/testar a chave.
- Sobre → Diagnóstico local: erros do Flutter, rede, geração e reprodução, até 100 eventos; copiar, exportar TXT, fechar e limpar.
- Branco, preto AMOLED, tema do sistema; wizard inicial; novidades antes do assistente na primeira abertura e após atualização; sobre e Pix.

## Compilar

Exige **Flutter stable**, Android SDK, Java 17 e acesso à internet para baixar dependências.

```bash
bash scripts/prepare_android.sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release --target-platform android-arm64
mkdir -p dist
cp build/app/outputs/flutter-apk/app-release.apk dist/Uai-Vozes-v0.26.apk
```

Ou envie este projeto ao GitHub via GitHub Manager e execute o workflow **Gerar APK Uai Vozes**. O artifact terá o APK separado do ZIP do código. Veja `docs/GITHUB_MANAGER.md`.

**Assinatura obrigatória na v0.26:** informe os quatro Secrets do GitHub Manager para liberar o build de produção. O workflow falha sem eles, evitando APK com certificado temporário. Veja `docs/GITHUB_MANAGER.md`.

## Segurança e limites

- O APK usa sua **chave pessoal** diretamente na API. Aplicativo de uso próprio. Se publicar/distribuir amplamente, use um backend/proxy para não expor tokens por interceptação em ambientes comprometidos.
- Evite imprimir chave em logs, backup ou GitHub. Copiar para clipboard requer confirmação.
- Geração exige internet e consome créditos da conta. Não há retentativa automática de síntese, para evitar gasto duplo.
- Áudios ficam no armazenamento privado do app, acessíveis offline, mas são apagados ao desinstalar. Exporte/compartilhe antes de desinstalar.
- A Voice Library pode ser restrita em planos Free; neste caso o aplicativo exibe erro real e oferece o catálogo pessoal.
- No primeiro build, o Android nativo é gerado pelo SDK oficial via `scripts/prepare_android.sh`, evitando incluir Gradle/Android gerados e arquivos pesados no ZIP.

## Documentação oficial

- https://elevenlabs.io/docs/api-reference/text-to-speech/convert
- https://elevenlabs.io/docs/api-reference/voices/search
- https://elevenlabs.io/docs/api-reference/voices/voice-library/get-shared
- https://elevenlabs.io/docs/api-reference/voices/voice-library/share

## Consumo/Créditos

A API de assinatura retorna `character_count`, `character_limit` e, quando disponível, o horário de renovação. Esses dados são exibidos literalmente como contagem/limite do ciclo de faturamento, que não é necessariamente o mês calendário. Os créditos cobrados podem variar por modelo. O texto ainda não gerado fornece apenas uma aproximação pelo número de caracteres e não representa gasto real. O indicador de uso local contabiliza caracteres de gerações bem-sucedidas desde a alpha.4, e o histórico detalhado começa na alpha.9, separado por mês calendário. Ele não recupera uso anterior nem de outros apps.

- https://elevenlabs.io/docs/api-reference/user/get
- https://elevenlabs.io/docs/api-reference/user/subscription/get

## Tratamento de falha na geração (v0.12)
Erros de API mostram código HTTP e orientações sem expor o texto ou a chave. Não há repetição automática. Caso um MP3 seja recebido, ele é salvo antes do registro opcional de consumo local. Para casos não identificados, copie o erro exibido e/ou use Ajustes > Diagnóstico local.
