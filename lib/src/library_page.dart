import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';

import 'app_model.dart';
import 'diagnostics.dart';
import 'models.dart';
import 'ui.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, required this.model});
  final AppModel model;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final player = AudioPlayer();
  String? current;
  bool playing = false;
  bool loadingAudio = false;
  StreamSubscription<PlayerState>? playbackStateSubscription;
  StreamSubscription<PlaybackEvent>? playbackErrorSubscription;
  String query = '';

  @override
  void initState() {
    super.initState();
    playbackStateSubscription = player.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        setState(() { playing = false; current = null; });
      } else {
        setState(() => playing = player.playing);
      }
    });
    playbackErrorSubscription = player.playbackEventStream.listen(
      (_) {}, onError: (Object error, StackTrace stack) {
        AppDiagnostics.instance.capture('BIBLIOTECA_PLAYER_EVENTO', error, stack);
        if (mounted) notice(context, 'Falha no player. O arquivo continua salvo.');
      });
    widget.model.addListener(reload);
  }

  void reload() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    widget.model.removeListener(reload);
    unawaited(playbackStateSubscription?.cancel() ?? Future<void>.value());
    unawaited(playbackErrorSubscription?.cancel() ?? Future<void>.value());
    unawaited(player.dispose());
    super.dispose();
  }

  Future<void> play(AudioRecord item) async {
    if (loadingAudio) return;
    loadingAudio = true;
    try {
      if (current == item.id && player.playing) {
        await player.pause();
        return;
      }
      if (current != item.id) {
        await player.stop();
        await player.setFilePath(item.path);
      } else if (player.processingState == ProcessingState.completed) {
        await player.seek(Duration.zero);
      }
      setState(() => current = item.id);
      // just_audio completa play() quando a reprodução termina; não bloquear
      // o botão Pausar durante todo o áudio.
      unawaited(player.play().catchError((Object error, StackTrace stack) {
        AppDiagnostics.instance.capture('BIBLIOTECA_PLAYER_ASYNC', error, stack);
        if (mounted) notice(context, 'Não foi possível reproduzir o áudio.');
      }));
    } catch (e, stack) {
      AppDiagnostics.instance.capture('BIBLIOTECA_REPRODUZIR', e, stack);
      if (mounted) notice(context, 'Arquivo de áudio indisponível.');
    } finally {
      loadingAudio = false;
    }
  }

  Future<void> rename(AudioRecord item) async {
    final controller = TextEditingController(text: item.name);
    final next = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(child: Padding(
        padding: EdgeInsets.fromLTRB(20, 5, 20, MediaQuery.viewInsetsOf(ctx).bottom + 25),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Renomear áudio', style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 15),
          TextField(controller: controller, autofocus: true, maxLength: 100,
              onSubmitted: (value) => Navigator.pop(ctx, value),
              decoration: const InputDecoration(labelText: 'Nome na biblioteca')),
          const SizedBox(height: 14),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Salvar nome')),
        ]),
      )),
    );
    // TextEditingController é descartado após o modal fechar.
    controller.dispose();
    if (next != null && next.trim().isNotEmpty) await widget.model.renameAudio(item, next);
  }

  Future<void> remove(AudioRecord item) async {
    final confirmed = await confirmSheet(context, title: 'Excluir áudio?',
      message: '“${item.name}” será removido permanentemente do armazenamento do aplicativo.',
      action: 'Excluir', destructive: true);
    if (!confirmed) return;
    if (current == item.id) {
      await player.stop();
      current = null;
    }
    try {
      await widget.model.deleteAudio(item);
      if (mounted) notice(context, 'Áudio excluído.');
    } catch (e, stack) {
      AppDiagnostics.instance.capture('BIBLIOTECA_EXCLUIR', e, stack);
      if (mounted) notice(context, 'Não foi possível remover o arquivo.');
    }
  }

  Future<void> share(AudioRecord item) async {
    if (!await File(item.path).exists()) {
      if (mounted) notice(context, 'Arquivo não encontrado.');
      return;
    }
    try {
      await Share.shareXFiles([XFile(item.path, mimeType: 'audio/mpeg')],
          subject: item.name);
    } catch (e, stack) {
      AppDiagnostics.instance.capture('BIBLIOTECA_EXPORTAR', e, stack);
      if (mounted) notice(context, 'Não foi possível compartilhar o arquivo.');
    }
  }

  String dateLabel(DateTime date) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(date.day)}/${p(date.month)}/${date.year} • ${p(date.hour)}:${p(date.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = widget.model.library.where((e) =>
      '${e.name} ${e.voiceName} ${e.text}'.toLowerCase().contains(query.toLowerCase())).toList();
    return SafeArea(child: ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
      children: [
        Text('Biblioteca', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('${widget.model.library.length} áudio(s) salvos • Reprodução sem internet',
            style: theme.textTheme.bodyMedium),
        const SizedBox(height: 17),
        TextField(onChanged: (s) => setState(() => query = s),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Buscar nos áudios…')),
        const SizedBox(height: 17),
        if (items.isEmpty)
          EmptyState(icon: Icons.library_music_outlined,
              title: widget.model.library.isEmpty ? 'Nenhum áudio salvo' : 'Nada encontrado',
              description: widget.model.library.isEmpty
                  ? 'Gere seu primeiro áudio no Estúdio. Ele aparecerá aqui automaticamente.'
                  : 'Experimente buscar outro nome ou trecho de texto.')
        else ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: UaiVozesCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(backgroundColor: theme.colorScheme.primaryContainer,
                  child: const Icon(Icons.music_note_rounded)),
              const SizedBox(width: 11),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text('${item.voiceName} • ${dateLabel(item.createdAt)}',
                    maxLines: 2, style: theme.textTheme.bodySmall),
              ])),
              IconButton.filledTonal(onPressed: () => play(item),
                  icon: Icon(current == item.id && playing ? Icons.pause_rounded : Icons.play_arrow_rounded)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              TextButton.icon(onPressed: () => share(item), icon: const Icon(Icons.ios_share_rounded, size: 18),
                  label: const Text('Exportar')),
              const Spacer(),
              IconButton(onPressed: () => rename(item), tooltip: 'Renomear',
                  icon: const Icon(Icons.edit_outlined, size: 21)),
              IconButton(onPressed: () => remove(item), tooltip: 'Excluir',
                  icon: const Icon(Icons.delete_outline_rounded, size: 21)),
            ]),
          ])),
        )),
      ],
    ));
  }
}
