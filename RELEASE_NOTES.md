# Uai Vozes v0.25 (alpha.25)

- Biblioteca: botão **Salvar MP3** abre o seletor nativo (`ACTION_CREATE_DOCUMENT`, `audio/mpeg`) e copia o arquivo para o local escolhido. O antigo Exportar passou a **Compartilhar** (folha de compartilhamento).
- A ponte Kotlin só aceita arquivos dentro do armazenamento privado do app (caminho canônico), até 50 MB, e sanitiza o nome. Nenhuma permissão de armazenamento, rede ou chamada à ElevenLabs.
- `MainActivity.kt` foi alterado: o build e o teste no aparelho dependem do GitHub Actions (nenhum Kotlin foi compilado aqui). APK previsto: `Uai-Vozes-v0.25.apk`.

# Versão anterior: v0.24 (alpha.24)

- Estúdio: seletor de modelo com **Multilingual v2** (padrão, 1 crédito base por caractere) e **Flash v2.5** (0,5 crédito base por caractere, segundo a central de ajuda da ElevenLabs). Só IDs conhecidos são aceitos; a escolha fica salva no aparelho.
- A confirmação de custo, a estimativa em Consumo e o histórico local usam o modelo escolhido; o diagnóstico registra `modelo=` apenas quando não é o padrão.
- Valores são referência, antes de multiplicadores da voz e de condições do plano/API; o custo real pode diferir. Nenhuma chamada extra: o modelo apenas troca o `model_id` do mesmo POST.
- APK previsto: `Uai-Vozes-v0.24.apk`; analyze/test/build dependem do GitHub Actions.

# Versão anterior: v0.23 (alpha.23)

- Depois de uma geração que devolveu MP3 válido, a voz é registrada como **já gerou áudio nesta conta** (`AppModel.workedVoiceIds`, até 200, salvo localmente só com IDs de voz).
- Selo na lista de vozes e novo filtro (ícone de visto) **só as que já geraram áudio**, combinável com favoritas, busca e filtros da API.
- O registro é limpo ao trocar a chave API e ao remover a voz da conta. Não é garantia de gerações futuras (saldo, modelo e plano podem mudar). Nenhuma chamada TTS ou GET adicional.
- APK previsto: `Uai-Vozes-v0.23.apk`; analyze/test/build dependem do GitHub Actions.

# Versão anterior: v0.22 (alpha.22)

- Aviso de falha HTTP 402 no Estúdio: novo botão **Ver vozes padrão da minha conta**. Ele vai à aba Vozes e aplica o filtro de vozes padrão (`voice_type=default`) por GET, sem gerar áudio.
- Implementado por um pedido no `AppModel` (`requestDefaultVoices`) que a aba Vozes observa; troca de chave/idioma continua limpando cache.
- Nenhuma chamada TTS adicional, assinatura, applicationId ou dados locais alterados. APK previsto: `Uai-Vozes-v0.22.apk`; analyze/test/build dependem do GitHub Actions.

# Versão anterior: v0.21 (alpha.21)

Diagnóstico real da alpha.20 (plano Free): vários HTTP 402 na geração e cinco FormatException ao abrir o Top 10 sem idioma.

- HTTP 402: `payment_required` e `paid_plan_required` entram na lista de motivos conhecidos; a leitura segue `detail.code`, depois `detail.status`, depois `detail.type`. Com plano Free, a mensagem cita a restrição de vozes da biblioteca pública pela API (sem afirmar como causa confirmada) e sugere testar uma voz padrão.
- Top 10 sem idioma agora mostra orientação e não grava erro no diagnóstico.
- Nenhuma chamada TTS adicional, assinatura, applicationId ou armazenamento alterados. O APK previsto é `Uai-Vozes-v0.21.apk`; analyze/test/build dependem do GitHub Actions.

# Versão anterior: v0.20 (alpha.20)

Correção de sintaxe da tela Explorar vozes identificada no GitHub Actions v0.19.

- Resolvidos os três erros de análise do workflow anterior causados pelo `if` auxiliar de vozes padrão entre uma cláusula `else if` e a lista de cartões.
- Mantidos os filtros estritos e de vozes da conta, navegação Top 10, remoção confirmada de voz, verificação por GET, busca, biblioteca, diagnósticos e proteção contra TTS duplicado.
- Teste de regressão estático adicionado; documentação, notas, metadados, `versionCode` e nomes do APK/artifact atualizados.
- `com.drilemoz.uaivozes`, quatro Secrets de assinatura e armazenamento local inalterados.
- O APK previsto é `Uai-Vozes-v0.20.apk`, separado do ZIP de código. O build e os testes Flutter da v0.20 aguardam execução em GitHub Actions.
