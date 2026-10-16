# Validação da versão 0.1.0-alpha.12+12

## Causa do workflow anterior

O workflow `Gerar APK Eleven` #1 concluiu a instalação do Flutter SDK 3.47.7 e `flutter pub get`, mas `flutter analyze` falhou com código 1 devido a seis ocorrências `deprecated_member_use` em `lib/src/settings_page.dart`, relativas a `RadioListTile.groupValue` / `onChanged` (linhas 153,154,160,161,167,168). O build e o APK não chegaram a ser executados.

## Correção

Os três `RadioListTile<ThemeMode>` ficam sob `RadioGroup<ThemeMode>` com `groupValue` e `onChanged` apenas no ancestral. Com Flutter >=3.35, este é o padrão suportado oficialmente. O workflow fixa Flutter 3.47.7 para reduzir variações entre compilações.

Também foram alterados o identificador Android (`com.drilemoz.uaivozes`), o pacote Flutter (`uaivozes`), os nomes exibidos, as notas, o workflow, o ícone de launcher nativo do Android e os metadados de versão.

## Novidades alpha.3

- `url_launcher` abre o endereço oficial das chaves API no navegador.
- Feedback de salvar/testar chave aparece dentro do wizard (não fica escondido atrás do modal) e em Configurações.
- Diagnóstico em Sobre registra exceções de framework/Dart, rede e operações tratadas; conteúdo é saneado para impedir cópia de chaves e textos. O registro usa armazenamento local limitado a 100 eventos e exportação voluntária via Sharesheet.
- Testes novos cobrem privacidade, limite do histórico, mensagens seguras e link oficial.

## Pendências

Não há SDK Flutter ou Android no ambiente local; o resultado de `flutter analyze`, `flutter test`, `flutter build apk`, instalação e acesso à API precisa ser verificado pelo próximo run do workflow. Não declarar APK testado antes disso.

## Novidades alpha.4

- Separado o DTO de usuário (`ElevenAccount`) do DTO de assinatura (`Subscription`), com parsing defensivo de campos opcionais e sem inventar dados.
- UI do consumo isolada em `account_page.dart`, utilizada no Estúdio e em Ajustes.
- `showChangesSheet` agora retorna `Future<void>` para apresentar novidades antes do wizard.
- Seleção de temas usa `SegmentedButton` horizontal; filtro de favoritas compactado num ícone.
- Testes novos: parsing de assinatura/conta, disponibilidade de dados e casos sem valores; indicador de estimativa local mensal.
- Validação estrutural local não substitui `flutter analyze`, `flutter test` e build CI.


## Alterações alpha.5
- Chave testada por consulta isolada sem persistência; proteção de avanço no wizard até salvar.
- Import/export implementado por Kotlin e seletor de documentos SAF, não sujeito a permissões amplas de armazenamento. Arquivos exportados não são criptografados; o usuário confirma isso.
- Vozes no wizard por consulta filtrada, seleção de idioma pt e ranking `locale=pt-BR`, sem fallback para inglês.
- Confirmação de estimativa antes de sintetizar, nunca há tentativa automática em erro.
- Testes unitários novos para parse de chave, filtro do ranking, etiquetas PT e identidade.
- Sem SDK Flutter/Android local; `flutter analyze`, `flutter test` e APK arm64 dependem de execução no GitHub Actions.


## Alterações e validação local alpha.6

- Revisão do fluxo TTS: trava no modelo e no diálogo, sem retentativas automáticas; solicitação de API pode ter sido cobrada mesmo quando a conexão falhou.
- Catálogo JSON atômico (`lib/src/audio_catalog.dart`) com backup, migração de metadados antigos sem apagar o legado, journal para arquivos recebidos mas não indexados e exclusão preparada para interrupções.
- Streams de player canceladas, erros de reprodução reportados separadamente da gravação do MP3.
- Diagnóstico agora ordena escritas nas preferências, evitando sobrescritas tardias após limpeza.
- Workflow bloqueia release se faltar qualquer um dos quatro Secrets de assinatura, preservando o certificado nas versões subsequentes.
- Testes adicionados em `test/audio_catalog_test.dart` e `test/generation_lock_test.dart`.
- Validações possíveis neste ambiente: verificação do ZIP, leitura/parse estrutural de JSON/YAML/XML, `bash -n` e regras estáticas de identidade/versão. **Não há SDK Flutter/Android disponível aqui** para `flutter analyze`, `flutter test`, compilação ou instalação. Esses resultados permanecem pendentes do workflow `Gerar APK Uai Vozes`.

## Correção do workflow #7 (alpha.7)

O run 7 falhou na etapa `python3 tools/validate_source.py`, depois de `flutter pub get`.
A expressão `ROOT.rglob("*")` inspecionava todo o diretório de trabalho e rejeitava
`.dart_tool/`, embora essa pasta tivesse sido criada pelo Flutter e não fizesse parte da distribuição.
A mesma lógica rejeitaria `android/app/release-key.jks`, produzida temporariamente
pelo script de assinatura; portanto ambas as validações precisavam ser corrigidas.

- `tools/source_hygiene.py`: valida caminhos presentes no **índice Git** durante o Actions; com `--archive`, valida entradas reais do ZIP e CRC.
- `tools/test_source_hygiene.py`: verifica que arquivos gerados não bloqueiam o run, que keystores incluídas no ZIP são proibidas e que o índice Git rejeita material privado rastreado.
- `test/identity_test.dart`: evita constantes antigas de versão/APK; obtém expectativas do `AppModel`.
- O workflow roda `python3 -m unittest discover -s tools -p 'test_*.py' -v` e mantém `validate_source.py` após `flutter pub get`, para exercer a correção no mesmo contexto do erro.

Validação histórica v0.07: `python3 tools/validate_source.py --archive ../Uai-Vozes-v0.07-Fonte.zip` e `python3 -m unittest discover -s tools -p 'test_*.py' -v`.
O SDK Flutter/Android não está disponível neste ambiente; `flutter analyze`, `flutter test`, `flutter build apk` e a assinatura real precisam ser verificados no GitHub Actions. **Não afirmar que o build do APK passou**.

### Arquivo Kotlin nativo versionado

A regra anterior `android/` de `.gitignore` também escondia `scripts/android/MainActivity.kt`. Foi substituída por `/android/`; o validador passa a exigir esse arquivo no índice Git/ZIP para garantir que a ponte nativa do seletor de documentos esteja disponível no CI.

## Correção do workflow #8 (alpha.8)

Os logs `Gerar APK Uai Vozes` #8 registram êxito de `flutter analyze` (zero issues) e dos **32 testes Flutter** para a v0.07. A falha real ocorreu no Gradle `:app:packageRelease` com `SigningConfig "release" is missing required property "storePassword"`.

**Causa:** `prepare_android.sh` insere no Gradle `storePassword = System.getenv("KEYSTORE_PASSWORD")`; as quatro credenciais eram enviadas somente para o passo "Gerar Android nativo e configurar assinatura", não para o passo "Compilar APK ARM64 otimizado". Cada passo Actions possui seu próprio ambiente.

**Correção:** os quatro Secrets são passados explicitamente ao passo `flutter build apk`, sem salvar senhas em arquivos versionados. `prepare_android.sh` também valida previamente a keystore e o alias com `keytool -list -storepass:env KEYSTORE_PASSWORD` e modo `umask 077`. O teste `tools/test_signing_workflow.py` impede regressão desse escopo de ambiente.

**Pendências:** recompilar no GitHub Actions e comprovar assinatura e instalação em Android real. O aviso de migração do Kotlin `share_plus` não causou a falha e não foi alterado nesta correção.

## Validação alpha.9

- Testes Flutter acrescentados: crédito base, faixas de alertas 50/80/95, histórico local ordenado e limitado, deduplicação, separação por mês e JSON inválido.
- Lint/análise/compilação Flutter não disponíveis no ambiente local. Executar GitHub Actions para verificação real.
- Código não grava texto, chave ou identificação de voz na nova lista de consumo.
- API oficial usada para dados do plano: `GET /v1/user/subscription`. `character_count` e `character_limit` não são um extrato universal do faturamento.

## Validação alpha.10 (Explorar vozes)

- Pesquisa da conta por `GET /v2/voices?search=...` com debounce e paginação por `next_page_token`/`has_more`.
- Filtros reais: `language`, `accent`, `gender`, `age` e `use_cases`. Estilo mantido como metadado local quando disponível.
- Resultados atrasados descartados por revisão da pesquisa e troca de credencial; cache LRU efêmero por 3 minutos, 10 páginas; limpo ao mudar conta/idioma.
- Top 10 permanece listado somente a partir de dados oficiais, condicionado ao acesso da conta.
- Testes em `test/voice_browse_test.dart`: requisições, paginação, cache, expiração, isolamento de filtros.
- `flutter analyze`, `flutter test` e build Android pendentes de execução real no GitHub Actions.

## Validação alpha.11
- Regressões cobrem códigos HTTP, falha no MP3 e classificação do erro por fase sem informação pessoal.
- O print da falha de v0.10 não contém código HTTP: diagnóstico exato do servidor pendente da próxima execução real.
- Flutter SDK/Android ausente no ambiente local: `flutter analyze`, `flutter test` e APK pendentes no GitHub Actions.

## Validação alpha.12
- Metadados opcionais de voz do GET /v1/voices/:voice_id e GET /v1/shared-voices, sem confundir prévia com acesso liberado.
- Novos testes Flutter: voz restrita/desconhecida, rascunhos locais, Unicode e divisão em partes de <=5000 caracteres.
- Importação TXT amplia a ponte Kotlin SAF com limite de 250 KiB, sem permissão de armazenamento amplo.
- Testes Flutter e compilação Android ainda requerem CI e aparelho real.
