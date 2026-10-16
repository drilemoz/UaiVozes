import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'app_model.dart';
import 'diagnostics.dart';
import 'ui.dart';

class DiagnosticsPage extends StatefulWidget {
  const DiagnosticsPage({super.key});

  @override
  State<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<DiagnosticsPage> {
  bool exporting = false;

  Future<void> copyReport() async {
    try {
      await Clipboard.setData(ClipboardData(text:
        AppDiagnostics.instance.report(version: AppModel.version)));
      if (mounted) notice(context, 'Relatório copiado.');
    } catch (e, stack) {
      AppDiagnostics.instance.capture('DIAGNOSTICO_COPIAR', e, stack);
      if (mounted) notice(context, 'Falha ao copiar relatório.');
    }
  }

  Future<void> exportReport() async {
    if (exporting) return;
    setState(() => exporting = true);
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/Uai-Vozes-Diagnostico.txt');
      await file.writeAsString(
        AppDiagnostics.instance.report(version: AppModel.version), flush: true);
      // Compartilhamento nativo: usuário escolhe onde salvar/enviar o TXT.
      await Share.shareXFiles([XFile(file.path, mimeType: 'text/plain')],
        text: 'Diagnóstico local do Uai Vozes');
    } catch (e, stack) {
      AppDiagnostics.instance.capture('DIAGNOSTICO_EXPORTAR', e, stack);
      if (mounted) notice(context, 'Não foi possível exportar o relatório.');
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  Future<void> clearReport() async {
    if (!await confirmSheet(context, title: 'Limpar diagnóstico?',
      message: 'Todos os registros locais serão apagados deste aparelho.',
      action: 'Limpar', destructive: true)) return;
    await AppDiagnostics.instance.clear();
    if (mounted) notice(context, 'Histórico de diagnóstico limpo.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monitor = AppDiagnostics.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnóstico local'), actions: [
        IconButton(icon: const Icon(Icons.close_rounded), tooltip: 'Fechar',
          onPressed: () => Navigator.of(context).pop()),
      ]),
      body: SafeArea(child: AnimatedBuilder(animation: monitor, builder: (context, _) {
        final events = monitor.entries;
        return ListView(padding: const EdgeInsets.fromLTRB(18, 10, 18, 24), children: [
          UaiVozesCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Icon(Icons.shield_outlined), const SizedBox(width: 10),
              Expanded(child: Text('Erros e eventos deste aparelho',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
            ]),
            const SizedBox(height: 10),
            Text('${events.length} registros recentes (limite ${AppDiagnostics.maxEntries}).',
              style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text('Funciona offline. Não registra chave API, texto digitado, '
              'conteúdo de áudio ou dados de autenticação. Exportação somente por sua escolha.',
              style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: [
              FilledButton.icon(onPressed: copyReport,
                icon: const Icon(Icons.copy_rounded), label: const Text('Copiar')),
              OutlinedButton.icon(onPressed: exporting ? null : exportReport,
                icon: const Icon(Icons.ios_share_rounded),
                label: Text(exporting ? 'Exportando…' : 'Exportar')),
              TextButton.icon(onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded), label: const Text('Fechar')),
            ]),
          ])),
          const SectionTitle('Registro de eventos'),
          if (events.isEmpty) const UaiVozesCard(child: Text(
            'Nenhum erro registrado. Os próximos eventos aparecerão aqui.')),
          ...events.map((entry) => Padding(padding: const EdgeInsets.only(bottom: 9),
            child: UaiVozesCard(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(entry.kind == 'ERRO' ? Icons.error_outline :
                    entry.kind == 'AVISO' ? Icons.warning_amber_rounded : Icons.info_outline,
                    size: 21, color: entry.kind == 'ERRO' ? theme.colorScheme.error :
                      theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${entry.kind} • ${entry.category}',
                    style: const TextStyle(fontWeight: FontWeight.w700))),
                ]),
                const SizedBox(height: 5),
                Text(entry.time.toLocal().toString().split('.').first,
                  style: theme.textTheme.bodySmall),
                const SizedBox(height: 5),
                SelectableText(entry.detail),
              ],
            )),
          )),
          const SizedBox(height: 10),
          Center(child: TextButton.icon(onPressed: clearReport,
            icon: const Icon(Icons.delete_outline), label: const Text('Limpar histórico'))),
        ]);
      })),
    );
  }
}
