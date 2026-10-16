# Uai Vozes v0.16 (alpha.16)

Filtro conservador de compatibilidade de vozes com o plano informado pela ElevenLabs.

- Explorador de Vozes: **Compatíveis com meu plano**, **Restritas** e **A confirmar**; combinam com busca, filtros existentes e favoritas, sem requisição TTS.
- **Compatível segundo a API** só quando `available_for_tiers` contém seu plano. Não representa voz gratuita nem promessa de geração, saldo ou modelo liberado.
- **Verificar acesso** consulta detalhes de uma voz individual por GET somente quando solicitado, sem gerar áudio. Dados inconclusivos continuam "A confirmar".
- No plano Free, a Voice Library pública não está disponível pela API segundo a ElevenLabs; prévias e permissão de compartilhar não liberam TTS. Voz já na conta não é bloqueada só por `free_users_allowed: false`.
- Botão para consultar a assinatura, tratamento de respostas antigas após troca de chave e aviso de que o filtro observa somente páginas carregadas.
- Preservados pacote Android, quatro Secrets, certificado, áudios, rascunhos e preferências. Nenhuma biblioteca nova. Testes Flutter e APK permanecem pendentes de GitHub Actions.
