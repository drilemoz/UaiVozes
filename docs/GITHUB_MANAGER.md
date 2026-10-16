# Uso com GitHub Manager

Este ZIP é **código-fonte de repositório Flutter**, não um APK. Contém workflow GitHub Actions `Gerar APK Uai Vozes` acionável manualmente em Actions ou por push nas branches main/master.

1. Criar repositório GitHub e importar os arquivos do ZIP mantendo a pasta `.github/workflows/` e os arquivos na raiz (não adicionar pasta externa).
2. Iniciar `Gerar APK Uai Vozes` pelo GitHub Manager, caso o aplicativo suporte disparar workflows, ou pelo site GitHub > Actions.
3. Ao concluir, obter o artifact `Uai-Vozes-v0.17-apk`. Ao extrair esse artifact, `Uai-Vozes-v0.17.apk` fica **fora** do ZIP de código-fonte.
4. O comando manual marca `publicar_release` por padrão (é possível desmarcar) para publicar o mesmo APK como arquivo direto na aba Releases do GitHub, se a permissão contents:write permitir.

O workflow prepara a plataforma Android usando o Flutter SDK oficial antes de compilar. A **assinatura é obrigatória** na v0.17. Antes de executar, importe pelo GitHub Manager os quatro Secrets `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS` e `KEY_PASSWORD` associados à **mesma keystore das versões futuras**. Sem qualquer um deles o workflow para com mensagem explícita e não publica APK de assinatura provisória. Não incluir keystore nem segredos no ZIP ou repositório.

O Artifact inclui `Uai-Vozes-v0.17.apk` e `Uai-Vozes-v0.17.apk.sha256` para verificação da integridade. O arquivo APK não é colocado dentro do ZIP de código-fonte. O `versionCode` é 17; atualizar sem desinstalar exige mesma `applicationId` e certificado do APK instalado. A keystore gerada em conversa anterior precisa ser importada como Secrets no repositório, o simples backup no Drive não ativa a assinatura.

Os arquivos `github-manager.json` e `app_identity.json` são metadados auxiliares e **não são garantia de suporte a um formato proprietário de importação**. O caminho compatível é Git/GitHub Actions.

### Correção incluída na v0.07

O workflow #7 da v0.06 falhou na validação porque o Flutter cria `.dart_tool/` após `flutter pub get`. A v0.07 corrigiu o validador para examinar apenas os arquivos do Git e inclui testes Python dessa regra. O APK só estará disponível depois que o GitHub Actions concluir todas as etapas. A v0.09 utiliza os mesmos quatro Secrets e a mesma assinatura da instalação anterior, quando devidamente importados.

### Correção de assinatura preservada desde a v0.08

O build #8 da v0.07 passou na análise e nos 32 testes Flutter, mas falhou no empacotamento devido à senha da keystore ausente na etapa Gradle. Desde a v0.08, o workflow encaminha `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS` e `KEY_PASSWORD` também ao passo de compilação. A assinatura é verificada antecipadamente antes de começar o build. **Reutilize os mesmos Secrets** já importados: não é necessário gerar nova keystore nem desinstalar o APK anterior quando sua assinatura corresponde.

### Novidades v0.09

Central de créditos e histórico local de até 60 gerações, alertas visuais de limites opcionais, sem alterar o workflow de assinatura existente.

### Novidades v0.10
- Explorador de vozes: busca na API, filtros e paginação, cache temporário e prévias controláveis.
- Mantenha os mesmos Secrets; o APK segue fora do ZIP de código-fonte.

### Atualização alpha.11
A geração agora mostra a etapa da falha e o código HTTP retornado pela ElevenLabs quando disponível; use Copiar erro para compartilhar apenas a descrição técnica saneada. Não envie sua chave API nem o texto da geração. Não repetir automaticamente uma operação potencialmente cobrada.

### Correção alpha.13
- O workflow #12 aprovou os testes Python e a validação, mas parou no `flutter analyze` devido ao import redundante de `dart:typed_data` no Estúdio.
- Corrigido na alpha.13, com regressão coberta por teste Python. Testes Flutter e compilação Android devem ser realizados pelo novo workflow.
- APK previsto: `Uai-Vozes-v0.13.apk`; artifact `Uai-Vozes-v0.13-apk`. Usar os mesmos quatro Secrets de assinatura, sem criar nova chave.

### Atualização alpha.12
- Avisos de restrição em vozes e editor de textos local com importação TXT; mesmos quatro Secrets, mesmo package e keystore.
- APK esperado no artifact `Uai-Vozes-v0.12-apk`. Não inclui Secrets nem backups privados.

### Correção alpha.14
- O workflow #13 passou na análise Flutter, mas 1 de 61 testes falhou na extração do motivo permitido de HTTP 422 com texto acentuado sem charset.
- A alpha.14 usa alternativa segura de decodificação, preservando a lista de motivos permitidos e uma única chamada de geração por ação.
- Executar novo workflow e verificar `flutter test` e build antes de anunciar APK; utilizar `Uai-Vozes-v0.14.apk` com os mesmos quatro Secrets.

### Correção alpha.15
- O erro em produção `GERACAO_API | HTTP 402` era comunicado de forma genérica como falta de acesso à voz. A alpha.15 distingue saldo/pagamento de permissões de voz.
- O app consulta apenas dados de assinatura pelo endpoint GET quando o usuário toca em **Consultar créditos e consumo**, sem nova geração TTS nem reenvio do texto.
- A leitura de `detail.code` com fallback a `detail.status` é restrita à lista de códigos conhecidos. Novos testes Flutter cobrem o cenário, mas ainda precisam ser executados via GitHub Actions.
- APK previsto: `Uai-Vozes-v0.17.apk`; artifact `Uai-Vozes-v0.17-apk`. Manter os Secrets atuais e não armazenar tokens no repositório.
