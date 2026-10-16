# Uai Vozes 🎙️

Uai Vozes é um aplicativo Flutter Android leve para converter textos em áudio com **ElevenLabs**, com design inspirado em cartões limpos, filtro compacto, wizard, novidades, conta e consumo e preto AMOLED real.

Versão: **0.1.0-alpha.7+7** · APK pretendido: **Uai-Vozes-v0.07.apk** · Pacote Android: `com.drilemoz.uaivozes`.

Identidade do launcher: **ícone de microfone nativo do Android** (`@android:drawable/ic_btn_speak_now`), sem assets de imagem extras.

**Identificador estável:** `com.drilemoz.uaivozes` permanece igual desde a alpha.2 para permitir atualizações sem perda de dados, quando a assinatura do APK é a mesma.

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
cp build/app/outputs/flutter-apk/app-release.apk dist/Uai-Vozes-v0.07.apk
```

Ou envie este projeto ao GitHub via GitHub Manager e execute o workflow **Gerar APK Uai Vozes**. O artifact terá o APK separado do ZIP do código. Veja `docs/GITHUB_MANAGER.md`.

**Assinatura obrigatória na v0.07:** informe os quatro Secrets do GitHub Manager para liberar o build de produção. O workflow falha sem eles, evitando APK com certificado temporário. Veja `docs/GITHUB_MANAGER.md`.

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

A API de assinatura retorna `character_count`, `character_limit` e, quando disponível, o horário de renovação. Esses dados são exibidos literalmente como contagem/limite do ciclo de faturamento, que não é necessariamente o mês calendário. Os créditos cobrados podem variar por modelo. O texto ainda não gerado fornece apenas uma aproximação pelo número de caracteres e não representa gasto real. O indicador de uso local passa a contabilizar caracteres de gerações bem-sucedidas a partir desta versão, separado por mês calendário. Ele não recupera uso anterior nem de outros apps.

- https://elevenlabs.io/docs/api-reference/user/get
- https://elevenlabs.io/docs/api-reference/user/subscription/get
