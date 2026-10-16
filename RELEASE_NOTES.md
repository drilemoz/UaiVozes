# Uai, Vozes v0.04 · 0.1.0-alpha.4 (versionCode 4)

## Novidades

- Consumo consultável no **Estúdio**, com contagem e limite disponíveis pela API da ElevenLabs, botão atualizar e estimativa de caracteres do texto e somatório local do mês (desde o início do monitoramento).
- **Ajustes → Conta ElevenLabs**: dados de usuário permitidos pela chave, plano, status, limites, vagas de voz e próxima renovação.
- Tela **O que mudou?** é exibida antes do assistente inicial após instalar ou atualizar.
- Explorar vozes: filtro de favoritas agora é um ícone; sem botão redundante que quebre a linha.
- **Branco, AMOLED e Sistema** lado a lado em Ajustes.
- Componentes internos reorganizados para reduzir duplicação.

## Consumo e privacidade

A API disponibiliza contagens e limites do ciclo da assinatura, não um conversor universal de caracteres para créditos. O texto do editor apresenta referência aproximada, nunca cobrança exata. Dados da conta podem exigir permissão **User: Read**. Sem acesso, o aplicativo informa limitação e preserva as demais funções.

## APK

O GitHub Actions deve produzir `Uai-Vozes-v0.04.apk` separadamente do ZIP de fontes. O APK não foi compilado neste ambiente; análise e testes Flutter precisam ser executados pelo workflow.
