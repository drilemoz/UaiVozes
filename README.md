# Uai, Vozes 🎙️

Uai, Vozes é um aplicativo Flutter Android leve para converter textos em áudio com **ElevenLabs**, com design inspirado em cartões limpos, filtro compacto, wizard, novidades, conta e consumo e preto AMOLED real.

Versão: **0.1.0-alpha.4+4** · APK pretendido: **Uai-Vozes-v0.04.apk** · Pacote Android: `com.drilemoz.uaivozes`.

Identidade do launcher: **ícone de microfone nativo do Android** (`@android:drawable/ic_btn_speak_now`), sem assets de imagem extras.

**ATENÇÃO:** o identificador Android mudou; este aplicativo é instalado separadamente do antigo Eleven. Os dados da instalação antiga não são migrados.

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
cp build/app/outputs/flutter-apk/app-release.apk dist/Uai-Vozes-v0.04.apk
```

Ou envie este projeto ao GitHub via GitHub Manager e execute o workflow **Gerar APK Uai, Vozes**. O artifact terá o APK separado do ZIP do código. Veja `docs/GITHUB_MANAGER.md`.

**Assinatura:** sem os quatro Secrets opcionais o template Flutter usa assinatura de desenvolvimento. Para atualizações instaláveis sobre versões anteriores, providencie keystore estável e secreta; veja `docs/GITHUB_MANAGER.md`.

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
