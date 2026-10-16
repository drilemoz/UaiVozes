import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/app_model.dart';
import 'src/diagnostics.dart';
import 'src/eleven_links.dart';
import 'src/eleven_api.dart';
import 'src/library_page.dart';
import 'src/settings_page.dart';
import 'src/studio_page.dart';
import 'src/ui.dart';
import 'src/voices_page.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    final diagnostics = AppDiagnostics.instance;
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      diagnostics.capture('FLUTTER_UI', details.exception, details.stack);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      diagnostics.capture('DART_NAO_TRATADO', error, stack);
      return true;
    };
    await diagnostics.restore();
    final model = AppModel();
    await model.load();
    runApp(UaiVozesApp(model: model));
  }, (error, stack) {
    AppDiagnostics.instance.capture('ZONA_NAO_TRATADA', error, stack);
  });
}

class UaiVozesApp extends StatelessWidget {
  const UaiVozesApp({super.key, required this.model});
  final AppModel model;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: model,
    builder: (ctx, _) => MaterialApp(
      title: 'Uai, Vozes',
      debugShowCheckedModeBanner: false,
      theme: uaiVozesTheme(Brightness.light),
      darkTheme: uaiVozesTheme(Brightness.dark),
      themeMode: model.themeMode,
      locale: const Locale('pt', 'BR'),
      home: MainShell(model: model),
    ),
  );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.model});
  final AppModel model;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_initialFlow());
    });
  }

  void tab(int next) { if (mounted) setState(() => index = next); }

  Future<void> _initialFlow() async {
    // Novidades sempre primeiro, inclusive na instalação inicial.
    if (widget.model.lastSeenVersion != AppModel.version) {
      await showChangesSheet(context, widget.model);
    }
    if (!mounted) return;
    if (widget.model.key.isEmpty) {
      await showWizard();
    } else {
      unawaited(widget.model.refreshUsage());
    }
  }

  Future<void> showWizard() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (ctx) => WizardSheet(
        model: widget.model,
        onExplore: () { Navigator.pop(ctx); tab(1); },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: index, children: [
      StudioPage(model: widget.model, openVoices: () => tab(1), openSettings: () => tab(3)),
      VoicesPage(model: widget.model, onChosen: () => tab(0), openSettings: () => tab(3)),
      LibraryPage(model: widget.model),
      SettingsPage(model: widget.model,
        showChanges: () => showChangesSheet(context, widget.model), showWizard: showWizard),
    ]),
    bottomNavigationBar: NavigationBar(
      selectedIndex: index,
      onDestinationSelected: tab,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.graphic_eq_outlined), selectedIcon: Icon(Icons.graphic_eq_rounded), label: 'Estúdio'),
        NavigationDestination(icon: Icon(Icons.mic_none_rounded), selectedIcon: Icon(Icons.mic_rounded), label: 'Vozes'),
        NavigationDestination(icon: Icon(Icons.library_music_outlined), selectedIcon: Icon(Icons.library_music_rounded), label: 'Biblioteca'),
        NavigationDestination(icon: Icon(Icons.tune_outlined), selectedIcon: Icon(Icons.tune_rounded), label: 'Ajustes'),
      ],
    ),
  );
}

class WizardSheet extends StatefulWidget {
  const WizardSheet({super.key, required this.model, required this.onExplore});
  final AppModel model;
  final VoidCallback onExplore;

  @override
  State<WizardSheet> createState() => _WizardSheetState();
}

class _WizardSheetState extends State<WizardSheet> {
  int step = 0;
  bool busy = false;
  bool reveal = false;
  String feedback = '';
  bool feedbackError = false;
  void updateFeedback(String value, {bool error = false}) {
    if (mounted) setState(() { feedback = value; feedbackError = error; });
  }
  late final TextEditingController keyController = TextEditingController(text: widget.model.key);

  @override
  void dispose() {
    keyController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy) return;
    if (keyController.text.trim().isEmpty) {
      updateFeedback('Cole sua chave antes de guardar.', error: true);
      return;
    }
    setState(() => busy = true);
    updateFeedback('Guardando chave…');
    try {
      await widget.model.setKey(keyController.text);
      AppDiagnostics.instance.info('CHAVE_API', 'Chave armazenada com sucesso.');
      updateFeedback('Chave guardada com segurança.');
    } catch (e, stack) {
      AppDiagnostics.instance.capture('CHAVE_GUARDAR', e, stack);
      updateFeedback('Não foi possível guardar a chave API.', error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> paste() async {
    final clip = await Clipboard.getData(Clipboard.kTextPlain);
    if (clip?.text?.trim().isNotEmpty == true) {
      keyController.text = clip!.text!.trim();
      setState(() {});
    }
  }

  Future<void> test() async {
    if (busy) return;
    if (keyController.text.trim().isEmpty) {
      updateFeedback('Cole sua chave antes de testar.', error: true);
      return;
    }
    setState(() => busy = true);
    updateFeedback('Testando conexão com a ElevenLabs…');
    try {
      await widget.model.setKey(keyController.text);
      final result = await widget.model.testKey();
      AppDiagnostics.instance.info('API_TESTE', 'Conexão validada.');
      updateFeedback('Conexão válida! Plano: ${result.tier}.');
    } catch (e, stack) {
      AppDiagnostics.instance.capture('API_TESTE', e, stack);
      updateFeedback('Falha ao testar: ${e is Exception ? friendlyError(e) : 'erro inesperado'}.', error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const icons = [Icons.key_rounded, Icons.mic_none_rounded,
      Icons.palette_outlined, Icons.auto_awesome_rounded];
    const titles = ['Conectar ElevenLabs', 'Escolher uma voz', 'Seu estilo visual', 'Tudo preparado'];
    const details = [
      'Cole sua chave pessoal da API e valide o acesso.',
      'Explore vozes por idioma, categoria e estilo.',
      'Escolha um visual confortável para seu aparelho.',
      'Digite o texto, gere uma voz e encontre o MP3 na Biblioteca.',
    ];
    return SafeArea(child: Padding(
      padding: EdgeInsets.fromLTRB(22, 10, 22, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(child: Text('Assistente de configuração',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
          const Chip(label: Text('Primeiro acesso')),
        ]),
        const SizedBox(height: 17),
        Row(children: List.generate(4, (i) => Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: AnimatedContainer(duration: const Duration(milliseconds: 260), height: 5,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
                color: i <= step ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest)),
        )))),
        const SizedBox(height: 28),
        CircleAvatar(radius: 40, backgroundColor: theme.colorScheme.surfaceContainerHigh,
            child: Icon(icons[step], size: 34)),
        const SizedBox(height: 15),
        Text(titles[step], textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 7),
        Text(details[step], textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 20),
        if (step == 0) ...[
          TextField(controller: keyController, obscureText: !reveal,
            onChanged: (_) => updateFeedback(''),
            enableSuggestions: false, autocorrect: false,
            decoration: InputDecoration(hintText: 'Chave API',
              suffixIcon: IconButton(onPressed: () => setState(() => reveal = !reveal),
                icon: Icon(reveal ? Icons.visibility_off_outlined : Icons.visibility_outlined))),
          ),
          const SizedBox(height: 5),
          Wrap(spacing: 8, children: [
            TextButton.icon(onPressed: paste, icon: const Icon(Icons.content_paste), label: const Text('Colar')),
            TextButton.icon(onPressed: busy ? null : save, icon: const Icon(Icons.shield_outlined), label: const Text('Guardar')),
            TextButton.icon(onPressed: busy ? null : test, icon: const Icon(Icons.wifi_tethering), label: const Text('Testar')),
            TextButton.icon(onPressed: () async {
              final ok = await openElevenApiKeys();
              if (!ok) updateFeedback('Não foi possível abrir o navegador.', error: true);
            }, icon: const Icon(Icons.open_in_new_rounded), label: const Text('Obter chave')),
          ]),
          if (feedback.isNotEmpty) ...[
            const SizedBox(height: 8),
            InlineFeedback(message: feedback, isError: feedbackError),
          ],
        ],
        if (step == 1)
          OutlinedButton.icon(onPressed: widget.onExplore, icon: const Icon(Icons.mic_rounded),
            label: const Text('Abrir explorador de vozes')),
        if (step == 2)
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text('Claro')),
              ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Preto')),
              ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.phone_android), label: Text('Auto')),
            ],
            selected: {widget.model.themeMode},
            onSelectionChanged: (selection) => setState(() => widget.model.setTheme(selection.first)),
          ),
        if (step == 3)
          Text('O áudio será salvo automaticamente após cada geração.',
            textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
        const SizedBox(height: 25),
        Row(children: [
          OutlinedButton(onPressed: step == 0 ? null : () => setState(() => step--), child: const Text('Voltar')),
          const Spacer(),
          Text('Etapa ${step + 1} de 4', style: theme.textTheme.bodySmall),
          const Spacer(),
          FilledButton(onPressed: () {
            if (step == 3) Navigator.pop(context);
            else setState(() => step++);
          }, child: Text(step == 3 ? 'Concluir' : 'Próximo')),
        ]),
      ])),
    ));
  }
}
