# Uai Vozes v0.12 · 0.1.0-alpha.12+12 (versionCode 12)

- Explorador de Vozes: indica “Exige plano pago” apenas com metadados explícitos da ElevenLabs e “Acesso a confirmar” em casos incertos; tarifas especiais recebem aviso sem assumir multiplicador.
- Evita selecionar ou gerar com vozes explicitamente indisponíveis para o plano atual, reduzindo tentativas com risco de consumo.
- Estúdio: importar TXT, salvar e recuperar rascunhos nomeados; dividir textos longos em partes de até 5.000 caracteres para geração manual controlada.
- Testes de elegibilidade, dados incompletos, limite de rascunhos, integridade Unicode e validações anteriores preservadas.

**Assinatura Android:** inalterada, mesmos Secrets obrigatórios. APK previsto `Uai-Vozes-v0.12.apk`, distribuído fora do ZIP do código.

**Limitação:** voz com selo “Acesso a confirmar” não é necessariamente gratuita; prévia não garante autorização. Em planos Free, a biblioteca pública via API pode ser inacessível. Não há download ou geração automática de partes longas.

**Validação pendente:** Flutter analyze, testes Flutter e compilação do APK no GitHub Actions.
