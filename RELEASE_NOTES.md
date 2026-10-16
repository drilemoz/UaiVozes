# Uai Vozes v0.09 · 0.1.0-alpha.9+9 (versionCode 9)

- Central de créditos com histórico local de até 60 gerações, sem salvar textos, voz, chave ou outros dados sensíveis nesse histórico.
- Alertas visuais configuráveis aos 50%, 80% e 95% do limite reportado pela ElevenLabs, consultado na API.
- Distinção entre saldo de uso oficial, caracteres locais acumulados no calendário e estimativa base (sem garantia de custo cobrado, pois planos e vozes podem variar).
- Consulta atrasada da conta anterior não substitui dados após trocar a chave API.
- Novos testes automatizados para contagens Unicode, limpeza de dados inválidos e faixas de alertas.

**Compatibilidade:** pacote `com.drilemoz.uaivozes` e assinatura release com os mesmos quatro Secrets existentes. Não reenviar Secrets nem alterar a keystore.

**Validação:** código preparado para `flutter analyze`, `flutter test` e build Release no GitHub Actions. Não há compilação Android local confirmada nesta entrega.

APK previsto fora do ZIP: `Uai-Vozes-v0.09.apk` com SHA-256 no Artifact. A publicação em Releases é opcional.
