import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_model.dart';
import 'ui.dart';

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

  @override
  void dispose() {
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
    setState(() => saving = true);
    try {
      await widget.model.setKey(keyController.text);
      if (mounted) notice(context, 'Chave guardada no armazenamento seguro.');
    } catch (_) {
      if (mounted) notice(context, 'Falha ao guardar a chave. Verifique o Android Keystore.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> testKey() async {
    if (testing) return;
    setState(() => testing = true);
    try {
      if (widget.model.key != keyController.text.trim()) await widget.model.setKey(keyController.text);
      final data = await widget.model.testKey();
      if (!mounted) return;
      notice(context, 'Conexão válida! Plano ${data.tier}.');
    } catch (e) {
      if (mounted) notice(context, '$e');
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
      if (mounted) notice(context, 'Chave removida.');
    } catch (_) {
      if (mounted) notice(context, 'Não foi possível remover a chave.');
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
            enableSuggestions: false, autocorrect: false,
            decoration: InputDecoration(
              hintText: 'Cole sua chave da ElevenLabs',
              suffixIcon: IconButton(onPressed: () => setState(() => reveal = !reveal),
                  tooltip: reveal ? 'Ocultar chave' : 'Mostrar chave',
                  icon: Icon(reveal ? Icons.visibility_off_outlined : Icons.visibility_outlined)),
            ),
          ),
          const SizedBox(height: 9),
          Wrap(spacing: 4, runSpacing: 5, children: [
            TextButton.icon(onPressed: pasteKey, icon: const Icon(Icons.content_paste_rounded), label: const Text('Colar')),
            TextButton.icon(onPressed: copyKey, icon: const Icon(Icons.copy_rounded), label: const Text('Copiar')),
            TextButton.icon(onPressed: removeKey, icon: const Icon(Icons.delete_outline_rounded), label: const Text('Apagar')),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: testing ? null : testKey,
              child: Text(testing ? 'Verificando…' : 'Testar API'),
            )),
            const SizedBox(width: 10),
            Expanded(child: FilledButton(
              onPressed: saving ? null : saveKey,
              child: Text(saving ? 'Salvando…' : 'Salvar chave'),
            )),
          ]),
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
        header(context, 'Aparência'),
        UaiVozesCard(child: RadioGroup<ThemeMode>(
          groupValue: widget.model.themeMode,
          onChanged: (value) {
            if (value != null) widget.model.setTheme(value);
          },
          child: Column(children: [
          RadioListTile<ThemeMode>(
            contentPadding: EdgeInsets.zero, title: const Text('Branco'),
            subtitle: const Text('Fundo claro e superfícies limpas'),
            secondary: const Icon(Icons.light_mode_outlined),
            value: ThemeMode.light,
          ),
          RadioListTile<ThemeMode>(
            contentPadding: EdgeInsets.zero, title: const Text('Preto AMOLED'),
            subtitle: const Text('Preto real #000000, sem cinza lavado'),
            secondary: const Icon(Icons.dark_mode_outlined),
            value: ThemeMode.dark,
          ),
          RadioListTile<ThemeMode>(
            contentPadding: EdgeInsets.zero, title: const Text('Sistema'),
            subtitle: const Text('Segue o tema do Android'),
            secondary: const Icon(Icons.settings_suggest_outlined),
            value: ThemeMode.system,
          ),
        ]))),
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
            title: const Text('Sobre o Uai, Vozes'), subtitle: const Text('Versão, histórico e doação Pix'),
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
  '0.1.0-alpha.2': [
    'Novo nome Uai, Vozes e identificador Android com.drilemoz.uaivozes.',
    'Corrigida análise do Flutter: seletores de tema migrados para RadioGroup.',
    'Ícone do launcher usa o microfone oficial do Android, sem imagem extra.',
  ],
  '0.1.0-alpha.1': [
    'Primeira versão do Estúdio, com geração MP3 e salvamento local.',
    'Explorador de vozes e ranking real por idioma conforme permissões da API.',
    'Tema AMOLED, assistente inicial, biblioteca, API segura e doação Pix.',
  ],
};

void showChangesSheet(BuildContext context, AppModel model) {
  showModalBottomSheet<void>(context: context, showDragHandle: true,
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
      appBar: AppBar(title: const Text('Sobre o Uai, Vozes')),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(18), children: [
        UaiVozesCard(child: Column(children: [
          CircleAvatar(radius: 35, backgroundColor: theme.colorScheme.primaryContainer,
            child: const Icon(Icons.graphic_eq_rounded, size: 35)),
          const SizedBox(height: 12),
          Text('Uai, Vozes', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          Text('Versão ${AppModel.version} • code ${AppModel.versionCode}'),
          const SizedBox(height: 9),
          const Text('Uai, Vozes: estúdio de áudio com tecnologia ElevenLabs, desenvolvido em Flutter.', textAlign: TextAlign.center),
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
