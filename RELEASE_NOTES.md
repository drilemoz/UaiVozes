# Uai, Vozes v0.02 · 0.1.0-alpha.2 (versionCode 2)

- Novo nome visível: **Uai, Vozes**.
- Novo pacote Android `com.drilemoz.uaivozes` e pacote Dart `uaivozes`.
- Ícone de microfone do próprio Android no launcher (`@android:drawable/ic_btn_speak_now`).
- Correção do erro do build GitHub Actions #1: substituídos seis usos obsoletos de `RadioListTile.groupValue` / `RadioListTile.onChanged` por `RadioGroup`.
- Mantidos conversão de texto pela API ElevenLabs, catálogo de vozes, biblioteca offline, temas e Pix.
- APK ARM64 gerado como `Uai-Vozes-v0.02.apk`, fora do ZIP do código-fonte, após aprovação do workflow.

**Atenção:** o identificador mudou; esta compilação instala como aplicativo independente do antigo Eleven, sem migrar dados ou chave API.

**Validação:** análise local estática, YAML/JSON/XML e ZIP; compilação Flutter/Android real fica pendente de GitHub Actions.
