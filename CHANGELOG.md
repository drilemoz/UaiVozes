# Histórico de versões

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

Próxima versão prevista: 0.1.0-alpha.9+9. Incrementar metadados, notas, pubspec, arquivos JSON e nome do APK.
