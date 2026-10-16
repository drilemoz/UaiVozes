# Uai Vozes v0.18 (alpha.18)

Explorador de Vozes compacto, remoção confirmada e exportação completa do Diagnóstico local.

- Filtros da API reunidos em uma folha inferior para Minhas vozes e Top 10; indicador 🇧🇷 Português, ajudas `?` e informações sem texto repetido. Há filtros de tipo, finalidade, gênero, idade e sotaque conforme a origem, além da compatibilidade local.
- O filtro Compatíveis com meu plano não é garantido pela ElevenLabs: apenas metadados explícitos confirmam o tier. Ação manual para até 10 GETs de detalhes, sem teste TTS ou reenvio de geração.
- Minhas vozes inclui menu ⋮ > Remover da conta. Confirmação obrigatória antes da exclusão; vozes padrão/legadas não removíveis; áudios gravados continuam na Biblioteca.
- Diagnóstico movido para Ajustes, ao lado de O que mudou?. Copiar, Exportar TXT e Excluir na mesma linha. Exportação grava o texto real por SAF, mediante destino escolhido pelo usuário.
- Correções de código, documentação e metadados sincronizados em `0.1.0-alpha.18+18`, APK de nome separado `Uai-Vozes-v0.18.apk` no GitHub Actions.
- Sem mudança de Secrets, senha, chaves, keystore, `applicationId` ou dados locais. Compilação Android e testes Flutter completos ainda pendentes do workflow.
