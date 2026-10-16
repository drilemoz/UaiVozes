# Uai Vozes v0.15 (alpha.15)

Correção de diagnóstico de geração HTTP 402 pela ElevenLabs, sem alterar cobrança ou permissões reais da conta.

- `GERACAO_API | HTTP 402` agora orienta conferir saldo/pagamento; não presume bloqueio de voz.
- Extrai códigos conhecidos do campo `detail.code` oficial, com fallback para `detail.status` antigo. `insufficient_credits` indica saldo insuficiente confirmado; códigos de assinatura/acesso recebem orientações específicas.
- O painel de falha permite abrir Créditos e consumo e atualizar os dados da conta, sem disparar nova geração de áudio.
- Protege chave, texto, mensagens e detalhes não permitidos nas exceções e relatórios; nenhuma retentativa automática cobrável.
- Mantém assinatura existente, Secrets, biblioteca e pacote Android; testes Flutter e compilação APK pendentes do workflow.

