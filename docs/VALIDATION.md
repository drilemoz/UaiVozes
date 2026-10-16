# Validação da versão 0.1.0-alpha.6+6

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
