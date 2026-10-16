# Histórico de versões

## 0.1.0-alpha.3+3 · 16/10/2026

- Botão **Obter chave API** no wizard e nas Configurações abre `https://elevenlabs.io/app/settings/api-keys` no navegador externo.
- **Guardar** e **Testar** agora mostram sucesso/erro no mesmo cartão do assistente e das Configurações, sem mensagens escondidas sob modal.
- **Sobre → Diagnóstico local** lista erros categorizados com data/hora e permite **Copiar**, **Exportar** relatório TXT via Android, **Fechar** e limpar histórico.
- Captura falhas não tratadas em Flutter UI, Dart/zone, e falhas conhecidas da API, biblioteca e player; limita registros locais a 100 e não serializa chave, textos, headers ou corpos da API.
- Atualizados testes, workflow, versionCode 3 e APK externo `Uai-Vozes-v0.03.apk`.

## 0.1.0-alpha.2+2 · 16/10/2026

- Renomeado para **Uai, Vozes**, pacote Flutter `uaivozes`, applicationId `com.drilemoz.uaivozes` e metadados sincronizados.
- Corrigidos os seis avisos de Flutter `deprecated_member_use` em Configurações, substituindo propriedades obsoletas dos `RadioListTile` por `RadioGroup<ThemeMode>`.
- Ícone de launcher agora utiliza `@android:drawable/ic_btn_speak_now`, recurso oficial do Android, sem recursos extras.
- Workflow renomeado e APK ARM64 `Uai-Vozes-v0.02.apk` exportado como artifact independente; release opcional.
- Alterar applicationId impede atualização direta da instalação antiga e separa seus dados.

## 0.1.0-alpha.1+1 · 16/10/2026

1. Estúdio de texto para voz com salvamento MP3 e reprodução.
2. Explorador de vozes, prévias, favoritas, filtro e ranking real por idioma.
3. Biblioteca local, chave segura, temas claro/AMOLED/sistema, wizard, novidades, Sobre e Pix.

Próxima versão prevista: 0.1.0-alpha.4+4. Incrementar metadados, notas, pubspec, arquivos JSON e nome do APK.
