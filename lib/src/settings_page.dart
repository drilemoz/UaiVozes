import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_model.dart';
import 'account_page.dart';
import 'eleven_links.dart';
import 'eleven_api.dart';
import 'diagnostics.dart';
import 'diagnostics_page.dart';
import 'ui.dart';
import 'key_buttons.dart';
import 'key_transfer.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.model, required this.showChanges, required this.showWizard});
  final AppModel model;
  final VoidCallback showChanges;
  final VoidCallback showWizard;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController keyController = TextEditingController(text: widget.model.key);
  bool reveal = false;
  bool testing = false;
  bool saving = false;
  String feedback = '';
  bool feedbackError = false;
  late String lastSyncedKey;

  @override
  void initState() {
    super.initState();
    lastSyncedKey = widget.model.key;
    widget.model.addListener(syncKeyFromModel);
  }

  void syncKeyFromModel() {
    if (widget.model.key != lastSyncedKey) {
      lastSyncedKey = widget.model.key;
      if (keyController.text != lastSyncedKey) {
        keyController.value = TextEditingValue(
          text: lastSyncedKey,
          selection: TextSelection.collapsed(offset: lastSyncedKey.length),
        );
      }
    }
  }

  void updateFeedback(String message, {bool error = false}) {
    if (mounted) setState(() { feedback = message; feedbackError = error; });
  }

  @override
  void dispose() {
    widget.model.removeListener(syncKeyFromModel);
    keyController.dispose();
    super.dispose();
  }

  Future<void> pasteKey() async {
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    final content = clipboard?.text?.trim();
    if (content == null || content.isEmpty) {
      if (mounted) notice(context, 'A área de transferência está vazia.');
      return;
    }
    keyController.text = content;
    setState(() {});
  }

  Future<void> saveKey() async {
    if (saving) return;
    if (keyController.text.trim().isEmpty) {
      updateFeedback('Cole sua chave antes de salvar.', error: true);
      return;
    }
    setState(() => saving = true);
    updateFeedback('Salvando chave…');
    try {
      await widget.model.setKey(keyController.text);
      AppDiagnostics.instance.info('CHAVE_API', 'Chave armazenada com sucesso.');
      updateFeedback('Chave guardada no armazenamento seguro.');
    } catch (e, stack) {
      AppDiagnostics.instance.capture('CHAVE_GUARDAR', e, stack);
      updateFeedback('Falha ao salvar. Verifique o Keystore.', error: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> testKey() async {
    if (testing) return;
    if (keyController.text.trim().isEmpty) {
      updateFeedback('Cole sua chave antes de testar.', error: true);
      return;
    }
    setState(() => testing = true);
    updateFeedback('Testando conexão com a ElevenLabs…');
    try {
      final data = await widget.model.api.checkCandidateKey(keyController.text.trim());
      AppDiagnostics.instance.info('API_TESTE', 'Conexão validada.');
      updateFeedback('Conexão válida! Plano: ${data.tier}. Use Guardar para salvar.');
    } catch (e, stack) {
      AppDiagnostics.instance.capture('API_TESTE', e, stack);
      updateFeedback('Falha ao testar: ${friendlyError(e)}.', error: true);
    } finally {
      if (mounted) setState(() => testing = false);
    }
  }

  Future<void> removeKey() async {
    if (!await confirmSheet(context, title: 'Remover a chave API?',
      message: 'A chave será apagada deste aparelho. Seus áudios salvos continuarão disponíveis.',
      action: 'Remover', destructive: true)) return;
    try {
      await widget.model.setKey('');
      keyController.clear();
      updateFeedback('Chave removida deste aparelho.');
    } catch (_) {
      updateFeedback('Não foi possível remover a chave.', error: true);
    }
  }

  Future<void> copyKey() async {
    if (keyController.text.trim().isEmpty) return;
    if (!await confirmSheet(context, title: 'Copiar chave secreta?',
      message: 'Outros aplicativos podem acessar a área de transferência do Android. Copie apenas se necessário.',
      action: 'Copiar chave')) return;
    await Clipboard.setData(ClipboardData(text: keyController.text.trim()));
    if (mounted) notice(context, 'Chave copiada.');
  }

  Future<void> importKey() async {
    try {
      final imported = await KeyTransfer.importFromDocument();
      if (!mounted || imported == null) return;
      keyController.text = imported;
      updateFeedback('Chave importada. Use Guardar para salvar.');
    } catch (_) {
      AppDiagnostics.instance.info('CHAVE_IMPORTAR', 'Não foi possível importar o arquivo selecionado.');
      updateFeedback('Arquivo não aceito. Use TXT/ENV com uma chave.', error: true);
    }
  }

  Future<void> exportKey() async {
    final saved = widget.model.key;
    if (saved.isEmpty) {
      updateFeedback('Guarde sua chave antes de exportar.', error: true);
      return;
    }
    final approved = await confirmSheet(context,
      title: 'Exportar chave secreta?',
      message: 'O arquivo TXT será salvo SEM criptografia. Quem tiver acesso ao arquivo poderá usar seus créditos. Escolha um local seguro e apague cópias desnecessárias.',
      action: 'Escolher local');
    if (!approved || !mounted) return;
    try {
      final exported = await KeyTransfer.exportToDocument(saved);
      if (mounted) updateFeedback(exported
        ? 'Chave exportada no local selecionado. Proteja o arquivo.'
        : 'Exportação cancelada.');
    } catch (_) {
      AppDiagnostics.instance.info('CHAVE_EXPORTAR', 'Falha no seletor de documentos.');
      if (mounted) updateFeedback('Não foi possível exportar a chave.', error: true);
    }
  }

  Widget header(BuildContext context, String title) => SectionTitle(title);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subscription = widget.model.subscription;
    return SafeArea(child: ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 35),
      children: [
        Text('Configurações', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Personalização, segurança e informações.', style: theme.textTheme.bodyMedium),
        header(context, 'Conexão ElevenLabs'),
        UaiVozesCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.key_rounded), SizedBox(width: 10),
            Text('Chave pessoal da API', style: TextStyle(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 14),
          TextField(controller: keyController, obscureText: !reveal,
            onChanged: (_) => updateFeedback(''),
            enableSuggestions: false, autocorrect: false,
            decoration: InputDecoration(
              hintText: 'Cole sua chave da ElevenLabs',
              suffixIcon: IconButton(onPressed: () => setState(() => reveal = !reveal),
                  tooltip: reveal ? 'Ocultar chave' : 'Mostrar chave',
                  icon: Icon(reveal ? Icons.visibility_off_outlined : Icons.visibility_outlined)),
            ),
          ),
          const SizedBox(height: 9),
          KeyActionsRow(busy: testing || saving,
            paste: () { pasteKey(); }, test: () { testKey(); }, save: () { saveKey(); },
            getKey: () async {
              final ok = await openElevenApiKeys();
              if (!ok) updateFeedback('Não foi possível abrir o navegador.', error: true);
            }),
          const SizedBox(height: 4),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
            TextButton.icon(onPressed: importKey, icon: const Icon(Icons.file_open_outlined, size: 19),
              label: const Text('Importar')),
            TextButton.icon(onPressed: exportKey, icon: const Icon(Icons.save_alt_outlined, size: 19),
              label: const Text('Exportar')),
            TextButton.icon(onPressed: copyKey, icon: const Icon(Icons.copy_outlined, size: 19),
              label: const Text('Copiar')),
            TextButton.icon(onPressed: removeKey, icon: const Icon(Icons.delete_outline_rounded, size: 19),
              label: const Text('Apagar')),
          ])),
          if (feedback.isNotEmpty) ...[
            const SizedBox(height: 12),
            InlineFeedback(message: feedback, isError: feedbackError),
          ],
          if (subscription != null) ...[
            const SizedBox(height: 13),
            Text('Plano: ${subscription.tier}', style: const TextStyle(fontWeight: FontWeight.w700)),
            if (subscription.limit != null && subscription.used != null)
              Text('Uso reportado: ${subscription.used} / ${subscription.limit} caracteres',
                  style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 10),
          Text('Somente armazenamento seguro local. Não envie sua chave a terceiros.',
              style: theme.textTheme.bodySmall),
        ])),
        header(context, 'Conta ElevenLabs'),
        UaiVozesCard(child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.account_circle_outlined),
          title: const Text('Conta e consumo'),
          subtitle: const Text('Plano, dados disponíveis, limite e uso do período'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => AccountPage(model: widget.model))),
        )),
        header(context, 'Aparência'),
        UaiVozesCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: double.infinity, child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: ThemeMode.light, label: Text('Branco'),
                  icon: Icon(Icons.light_mode_outlined, size: 17)),
                ButtonSegment(value: ThemeMode.dark, label: Text('AMOLED'),
                  icon: Icon(Icons.dark_mode_outlined, size: 17)),
                ButtonSegment(value: ThemeMode.system, label: Text('Sistema'),
                  icon: Icon(Icons.settings_suggest_outlined, size: 17)),
              ],
              selected: {widget.model.themeMode},
              onSelectionChanged: (values) => widget.model.setTheme(values.first),
            )),
            const SizedBox(height: 8),
            Text(switch (widget.model.themeMode) {
              ThemeMode.light => 'Branco: fundo claro e superfícies limpas.',
              ThemeMode.dark => 'AMOLED: preto real #000000.',
              ThemeMode.system => 'Segue a aparência configurada no Android.',
            }, style: theme.textTheme.bodySmall),
          ],
        )),
        header(context, 'Geração de áudio'),
        UaiVozesCard(child: SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.toll_outlined),
          title: const Text('Confirmar créditos antes de gerar'),
          subtitle: const Text('Mostra a estimativa e pede autorização antes de consumir créditos.'),
          value: widget.model.confirmCreditsBeforeGenerate,
          onChanged: widget.model.setConfirmCredits,
        )),
        UaiVozesCard(child: SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.notifications_active_outlined),
          title: const Text('Alertas de consumo'),
          subtitle: const Text('Exibir avisos aos 50%, 80% e 95% do limite consultado na API. Não envia notificações em segundo plano.'),
          value: widget.model.creditAlertsEnabled,
          onChanged: widget.model.setCreditAlerts,
        )),
        header(context, 'Aplicativo'),
        UaiVozesCard(child: Column(children: [
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.auto_awesome_rounded),
            title: const Text('O que mudou?'), subtitle: const Text('Novidades da versão instalada'),
            trailing: const Icon(Icons.chevron_right_rounded), onTap: widget.showChanges),
          const Divider(),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.assistant_outlined),
            title: const Text('Assistente inicial'), subtitle: const Text('Reabrir o guia de configuração'),
            trailing: const Icon(Icons.chevron_right_rounded), onTap: widget.showWizard),
          const Divider(),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.info_outline_rounded),
            title: const Text('Sobre o Uai Vozes'), subtitle: const Text('Versão, histórico e doação Pix'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (ctx) => AboutPage(model: widget.model, showChanges: widget.showChanges))),
          ),
        ])),
      ],
    ));
  }
}

const releaseNotes = <String, List<String>>{
  '0.1.0-alpha.11': [
    'Erros de geração exibem etapa e HTTP em painel, com opção Copiar erro sem dados sensíveis.',
    'Áudio recebido é salvo antes de registrar histórico: falha do histórico não descarta o MP3.',
    'Tratamento seguro de respostas da ElevenLabs e validação de MP3 antes de salvar.',
  ],
  '0.1.0-alpha.10': [
    'Explorar vozes agora pesquisa o catálogo completo com paginação e novos filtros.',
    'Cache de sessão e respostas atrasadas protegidas após trocar idioma ou conta.',
    'Prévias podem ser interrompidas sem bloquear o aplicativo; novos testes de API.',
  ],
  '0.1.0-alpha.9': [
    'Central de créditos com histórico local por geração, sem armazenar o texto.',
    'Alertas opcionais aos 50%, 80% e 95% do limite reportado pela ElevenLabs.',
    'Estimativas identificadas como valores base e proteção contra retorno de conta antiga.',
  ],
  '0.1.0-alpha.8': [
    'Corrigida falha de assinatura no GitHub Actions #8, durante o empacotamento Release.',
    'Os Secrets são disponibilizados também ao Gradle, mantendo o certificado de atualização.',
    'Verificação antecipada da keystore e testes preventivos do workflow.',
  ],
  '0.1.0-alpha.7': [
    'Corrigida verificação do workflow que rejeitava caches normais do Flutter.',
    'Segurança de distribuição reforçada sem incluir chaves ou arquivos temporários.',
    'Teste de identidade e validações automatizadas atualizados.',
  ],
  '0.1.0-alpha.6': [
    'Bloqueio global de solicitações TTS duplicadas, inclusive durante a confirmação.',
    'Biblioteca com gravação atômica, recuperação de áudio e migração sem excluir o histórico.',
    'Erros de reprodução tratados e assinatura obrigatória no APK do GitHub Actions.',
  ],
  '0.1.0-alpha.5': [
    'Nome Uai Vozes sem vírgula em toda a interface e nos metadados.',
    'API: botões em linha, importação/exportação TXT e confirmação de chave não salva.',
    'Prévia de créditos opcional e vozes em português no assistente inicial.',
  ],
  '0.1.0-alpha.4': [
    'Consumo de assinatura no Estúdio, com consulta à API e estimativa do texto.',
    'Tela Conta ElevenLabs com plano, limites, vagas de voz e dados autorizados.',
    'Novidades antes do assistente; filtro de favoritas compacto e temas lado a lado.',
  ],
  '0.1.0-alpha.3': [
    'Link oficial para criar a chave API, nas Configurações e no assistente.',
    'Feedback visível de sucesso/erro ao guardar e testar a API.',
    'Diagnóstico local de erros com copiar, exportar e fechar, sem expor a chave.',
  ],
  '0.1.0-alpha.2': [
    'Novo nome Uai Vozes e identificador Android com.drilemoz.uaivozes.',
    'Corrigida análise do Flutter: seletores de tema migrados para RadioGroup.',
    'Ícone do launcher usa o microfone oficial do Android, sem imagem extra.',
  ],
  '0.1.0-alpha.1': [
    'Primeira versão do Estúdio, com geração MP3 e salvamento local.',
    'Explorador de vozes e ranking real por idioma conforme permissões da API.',
    'Tema AMOLED, assistente inicial, biblioteca, API segura e doação Pix.',
  ],
};

Future<void> showChangesSheet(BuildContext context, AppModel model) {
  return showModalBottomSheet<void>(context: context, showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
    builder: (ctx) => SafeArea(child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 25),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Chip(label: Text('Nova versão • ${AppModel.version}')),
          const Spacer(),
          const Icon(Icons.auto_awesome_rounded),
        ]),
        const SizedBox(height: 8),
        Text('O que mudou?', style: Theme.of(ctx).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        ...releaseNotes[AppModel.version]!.map((note) => Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.check_circle_outline_rounded, size: 23),
            const SizedBox(width: 12),
            Expanded(child: Text(note)),
          ]),
        )),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: FilledButton(
          onPressed: () async { await model.markChangelogSeen(); if (ctx.mounted) Navigator.pop(ctx); },
          child: const Text('Entendi'),
        )),
      ]),
    )),
  );
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key, required this.model, required this.showChanges});
  final AppModel model;
  final VoidCallback showChanges;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastThree = releaseNotes.keys.take(3).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Sobre o Uai Vozes')),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(18), children: [
        UaiVozesCard(child: Column(children: [
          CircleAvatar(radius: 35, backgroundColor: theme.colorScheme.primaryContainer,
            child: const Icon(Icons.graphic_eq_rounded, size: 35)),
          const SizedBox(height: 12),
          Text('Uai Vozes', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          Text('Versão ${AppModel.version} • code ${AppModel.versionCode}'),
          const SizedBox(height: 9),
          const Text('Uai Vozes: estúdio de áudio com tecnologia ElevenLabs, desenvolvido em Flutter.', textAlign: TextAlign.center),
        ])),
        const SectionTitle('Últimas três alterações'),
        ...lastThree.map((version) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: UaiVozesCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(version, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ...(releaseNotes[version] ?? []).map((note) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('•  '), Expanded(child: Text(note)),
              ]),
            )),
          ])),
        )),
        const SectionTitle('Diagnóstico local'),
        UaiVozesCard(child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.bug_report_outlined),
          title: const Text('Erros do aplicativo'),
          subtitle: const Text('Consultar, copiar ou exportar relatório local'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const DiagnosticsPage())),
        )),
        const SectionTitle('Apoie o desenvolvimento'),
        UaiVozesCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [Icon(Icons.volunteer_activism_outlined), SizedBox(width: 10),
            Expanded(child: Text('Doação voluntária via Pix', style: TextStyle(fontWeight: FontWeight.bold)))]),
          const SizedBox(height: 11),
          Text('Contribuir não é necessário para acessar funcionalidades.', style: theme.textTheme.bodySmall),
          const SizedBox(height: 15),
          Text('Chave Pix • E-mail', style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          const SelectableText(AppModel.pix, style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 15),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(const ClipboardData(text: AppModel.pix));
              if (context.mounted) notice(context, 'Chave Pix copiada.');
            },
            icon: const Icon(Icons.copy_rounded), label: const Text('Copiar chave Pix'),
          )),
        ])),
        const SizedBox(height: 15),
        Text('Aplicativo independente, não afiliado à ElevenLabs.',
            textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
      ])),
    );
  }
}
