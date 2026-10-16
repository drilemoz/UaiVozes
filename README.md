# Uai, Vozes 🎙️

Uai, Vozes é um aplicativo Flutter Android leve para converter textos em áudio com **ElevenLabs**, com design inspirado em cartões limpos, filtro compacto, wizard, novidades e preto AMOLED real.

Versão: **0.1.0-alpha.2+2** · APK pretendido: **Uai-Vozes-v0.02.apk** · Pacote Android: `com.drilemoz.uaivozes`.

Identidade do launcher: **ícone de microfone nativo do Android** (`@android:drawable/ic_btn_speak_now`), sem assets de imagem extras.

**ATENÇÃO:** o identificador Android mudou; este aplicativo é instalado separadamente do antigo Eleven. Os dados da instalação antiga não são migrados.

## Funcionalidades

- Estúdio de texto até 5.000 caracteres por geração, ElevenLabs `eleven_multilingual_v2` e MP3 44.1 kHz/128 kbps.
- Vozes da conta via `GET /v2/voices` paginado; filtros de idioma e uso, pesquisa, prévia e favoritas locais.
- Top 10 por idioma/categoria, com **ordenação real por `usage_character_count_1y`**, via `GET /v1/shared-voices`. Não simula rankings se não autorizado.
- Adição consentida de voz compartilhada à conta antes da conversão.
- Biblioteca de MP3 salvos em diretório privado, reprodução e compartilhamento/exportação via menu Android.
- Chave API segura via Android Keystore; botão colar, copiar (com aviso), mostrar, testar e remover.
- Branco, preto AMOLED, tema do sistema; wizard inicial; pop-ups e novidades pós-atualização; sobre e Pix.

## Compilar

Exige **Flutter stable**, Android SDK, Java 17 e acesso à internet para baixar dependências.

```bash
bash scripts/prepare_android.sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release --target-platform android-arm64
mkdir -p dist
cp build/app/outputs/flutter-apk/app-release.apk dist/Uai-Vozes-v0.02.apk
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
