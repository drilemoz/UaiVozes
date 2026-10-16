# Uai Vozes v0.19 (alpha.19)

Filtro de acesso mais útil para plano Free, sem confundir voz visível com permissão de gerar.

- O Top 10 é biblioteca compartilhada; no plano Free não há acesso à geração dessa biblioteca via API. Quando o filtro estrito não encontra vozes, há atalho para **Minhas vozes**.
- Novo filtro **Na minha conta (possíveis)** exibe vozes retornadas pela API para sua conta, omitindo apenas as com restrição explícita. A etiqueta de cada voz continua informando **Acesso a confirmar** quando os metadados não bastam.
- O filtro **Compatíveis com meu plano** permanece confiável e estrito: exige `available_for_tiers`. Se ficar vazio, não interpreta ausência do campo como bloqueio; oferece caminho para as vozes da conta.
- Quando necessário, botão consulta vozes padrão usando somente GET. Nenhuma geração TTS, teste pago automático ou nova dependência. HTTP 402 continua sinalizando cobrança/créditos a verificar, não prova bloqueio de voz.
- Identificador `com.drilemoz.uaivozes`, assinatura, quatro Secrets, dados locais e MP3s preservados. APK `Uai-Vozes-v0.19.apk` configurado para GitHub Actions; compilação Flutter/Android pendente.
