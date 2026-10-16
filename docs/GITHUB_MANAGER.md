# Uso com GitHub Manager

Este ZIP é **código-fonte de repositório Flutter**, não um APK. Contém workflow GitHub Actions `Gerar APK Uai Vozes` acionável manualmente em Actions ou por push nas branches main/master.

1. Criar repositório GitHub e importar os arquivos do ZIP mantendo a pasta `.github/workflows/` e os arquivos na raiz (não adicionar pasta externa).
2. Iniciar `Gerar APK Uai Vozes` pelo GitHub Manager, caso o aplicativo suporte disparar workflows, ou pelo site GitHub > Actions.
3. Ao concluir, obter o artifact `Uai-Vozes-v0.09-apk`. Ao extrair esse artifact, `Uai-Vozes-v0.09.apk` fica **fora** do ZIP de código-fonte.
4. O comando manual marca `publicar_release` por padrão (é possível desmarcar) para publicar o mesmo APK como arquivo direto na aba Releases do GitHub, se a permissão contents:write permitir.

O workflow prepara a plataforma Android usando o Flutter SDK oficial antes de compilar. A **assinatura é obrigatória** na v0.09. Antes de executar, importe pelo GitHub Manager os quatro Secrets `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS` e `KEY_PASSWORD` associados à **mesma keystore das versões futuras**. Sem qualquer um deles o workflow para com mensagem explícita e não publica APK de assinatura provisória. Não incluir keystore nem segredos no ZIP ou repositório.

O Artifact inclui `Uai-Vozes-v0.09.apk` e `Uai-Vozes-v0.09.apk.sha256` para verificação da integridade. O arquivo APK não é colocado dentro do ZIP de código-fonte. O `versionCode` é 9; atualizar sem desinstalar exige mesma `applicationId` e certificado do APK instalado. A keystore gerada em conversa anterior precisa ser importada como Secrets no repositório, o simples backup no Drive não ativa a assinatura.

Os arquivos `github-manager.json` e `app_identity.json` são metadados auxiliares e **não são garantia de suporte a um formato proprietário de importação**. O caminho compatível é Git/GitHub Actions.

### Correção incluída na v0.07

O workflow #7 da v0.06 falhou na validação porque o Flutter cria `.dart_tool/` após `flutter pub get`. A v0.07 corrigiu o validador para examinar apenas os arquivos do Git e inclui testes Python dessa regra. O APK só estará disponível depois que o GitHub Actions concluir todas as etapas. A v0.09 utiliza os mesmos quatro Secrets e a mesma assinatura da instalação anterior, quando devidamente importados.

### Correção de assinatura preservada desde a v0.08

O build #8 da v0.07 passou na análise e nos 32 testes Flutter, mas falhou no empacotamento devido à senha da keystore ausente na etapa Gradle. Desde a v0.08, o workflow encaminha `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS` e `KEY_PASSWORD` também ao passo de compilação. A assinatura é verificada antecipadamente antes de começar o build. **Reutilize os mesmos Secrets** já importados: não é necessário gerar nova keystore nem desinstalar o APK anterior quando sua assinatura corresponde.

### Novidades v0.09

Central de créditos e histórico local de até 60 gerações, alertas visuais de limites opcionais, sem alterar o workflow de assinatura existente.
