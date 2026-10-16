# Uai Vozes v0.17 (alpha.17)

Diagnóstico de bloqueios e recusas de acesso a vozes, com captura segura e sem gastos extras de créditos.

- Registra restrições quando o usuário tenta selecionar/gerar com voz restrita e quando uma consulta manual de detalhes confirma a restrição.
- Captura HTTP e motivo de erro permitido nas verificações e gerações rejeitadas. HTTP 402 isolado sinaliza cobrança/créditos a verificar, não bloqueio confirmado.
- Sobre > Diagnóstico local: filtro **Somente eventos de vozes**, Copiar e Exportar respeitando o filtro.
- Referência anônima da voz para relacionar eventos, sem guardar nome, ID original, texto, chave API, resposta remota ou cabeçalhos.
- Sem novas requisições TTS, dependências, migrações ou alteração de certificado e Secrets.
- APK/testes Flutter desta versão ainda não executados; conferir no GitHub Actions.
