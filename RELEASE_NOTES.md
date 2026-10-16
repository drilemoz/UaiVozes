# Uai Vozes v0.07 · 0.1.0-alpha.7+7 (versionCode 7)

- Corrigido o falso positivo do validador do GitHub Actions #7, que confundia os caches legítimos do Flutter e o Android gerado com arquivos distribuídos.
- Verificação segura dos arquivos realmente versionados ou presentes no ZIP, mantendo proteção contra inclusão de caches e keystores privadas.
- Atualizado teste de identidade para acompanhar as versões atuais, sem referências estáticas à v0.05.
- Corrigido `.gitignore` para incluir `scripts/android/MainActivity.kt` no repositório; antes a regra ampla `android/` também ignorava esse código-fonte nativo.
- Acrescentados três testes Python de higiene da distribuição ao workflow, sem novas dependências Flutter.
- Preservados nome Uai Vozes, identificador `com.drilemoz.uaivozes`, dados locais e assinatura obrigatória com os mesmos quatro Secrets.

APK previsto: `Uai-Vozes-v0.07.apk` como artifact separado, com SHA-256. A compilação Flutter e os testes Android seguem pendentes da execução no GitHub Actions.
