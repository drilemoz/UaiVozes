# Uso com GitHub Manager

Este ZIP é **código-fonte de repositório Flutter**, não um APK. Contém workflow GitHub Actions `Gerar APK Uai, Vozes` acionável manualmente em Actions ou por push nas branches main/master.

1. Criar repositório GitHub e importar os arquivos do ZIP mantendo a pasta `.github/workflows/` e os arquivos na raiz (não adicionar pasta externa).
2. Iniciar `Gerar APK Uai, Vozes` pelo GitHub Manager, caso o aplicativo suporte disparar workflows, ou pelo site GitHub > Actions.
3. Ao concluir, obter o artifact `Uai-Vozes-v0.04-apk`. Ao extrair esse artifact, `Uai-Vozes-v0.04.apk` fica **fora** do ZIP de código-fonte.
4. O comando manual marca `publicar_release` por padrão (é possível desmarcar) para publicar o mesmo APK como arquivo direto na aba Releases do GitHub, se a permissão contents:write permitir.

O workflow prepara a plataforma Android usando o Flutter SDK oficial antes de compilar. Para assinatura consistente, configurar Secrets `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD` com uma keystore privada própria. Não salvar a keystore nem segredos no repositório. Sem Secrets o APK pode mudar de certificado a cada execução e impedir atualização sobre outra instalação.

Os arquivos `github-manager.json` e `app_identity.json` são metadados auxiliares e **não são garantia de suporte a um formato proprietário de importação**. O caminho compatível é Git/GitHub Actions.
