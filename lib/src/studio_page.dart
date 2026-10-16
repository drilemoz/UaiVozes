import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import 'app_model.dart';
import 'credit_ledger.dart';
import 'account_page.dart';
import 'diagnostics.dart';
import 'generation_failure.dart';
import 'models.dart';
import 'ui.dart';
import 'voice_access.dart';
import 'text_drafts.dart';
import 'text_transfer.dart';

class StudioPage extends StatefulWidget {
  const StudioPage({super.key, required this.model, required this.openVoices, required this.openSettings});
  final AppModel model;
  final VoidCallback openVoices;
  final VoidCallback openSettings;

  @override
  State<StudioPage> createState() => _StudioPageState();
}

class _StudioPageState extends State<StudioPage> {
  late final TextEditingController text = TextEditingController(text: widget.model.draft);
  late final AudioPlayer player = AudioPlayer();
  bool generating = false;
  bool confirming = false;
  StreamSubscription<PlayerState>? playbackStateSubscription;
  StreamSubscription<PlaybackEvent>? playbackErrorSubscription;
  AudioRecord? lastAudio;
  bool playing = false;
  Timer? draftTimer;

  @override
  void initState() {
    super.initState();
    playbackStateSubscription = player.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        unawaited(player.pause().then((_) => player.seek(Duration.zero)).catchError(
          (Object error, StackTrace stack) {
            AppDiagnostics.instance.capture('ESTUDIO_FINALIZAR_PLAYER', error, stack);
          }));
      }
      setState(() => playing = player.playing);
    });
    playbackErrorSubscription = player.playbackEventStream.listen(
      (_) {},
      onError: (Object error, StackTrace stack) {
        AppDiagnostics.instance.capture('ESTUDIO_PLAYER_EVENTO', error, stack);
        if (mounted) notice(context, 'Erro de reprodução. O MP3 salvo continua na Biblioteca.');
      },
    );
  }

  @override
  void dispose() {
    draftTimer?.cancel();
    unawaited(widget.model.setDraft(text.text));
    unawaited(playbackStateSubscription?.cancel() ?? Future<void>.value());
    unawaited(playbackErrorSubscription?.cancel() ?? Future<void>.value());
    text.dispose();
    unawaited(player.dispose());
    super.dispose();
  }

  Future<void> saveNamedDraft() async {
    final content = text.text.trim();
    if (content.isEmpty) { notice(context, 'Digite um texto para salvar.'); return; }
    final titleController = TextEditingController(
      text: content.replaceAll(RegExp(r'\s+'), ' ').substring(0,
        content.length > 32 ? 32 : content.length));
    try {
      final title = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Salvar rascunho'),
        content: TextField(controller: titleController, autofocus: true,
          maxLength: 80, decoration: const InputDecoration(labelText: 'Título')),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, titleController.text.trim()),
            child: const Text('Salvar'))],
      ));
      if (!mounted || title == null || title.isEmpty) return;
      await widget.model.saveNamedDraft(title, content);
      if (mounted) notice(context, 'Rascunho salvo neste aparelho.');
    } catch (error, stack) {
      AppDiagnostics.instance.capture('RASCUNHO_SALVAR', error, stack);
      if (mounted) notice(context, 'Não foi possível salvar o rascunho.');
    } finally { titleController.dispose(); }
  }

  Future<void> showDrafts() async {
    await showModalBottomSheet<void>(context: context, showDragHandle: true,
      isScrollControlled: true, builder: (ctx) => SafeArea(child: SizedBox(
      height: MediaQuery.sizeOf(ctx).height * .65,
      child: StatefulBuilder(builder: (ctx, refreshSheet) => ListView(
        padding: const EdgeInsets.all(18), children: [
        Text('Rascunhos salvos', style: Theme.of(ctx).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text('Os rascunhos ficam no aparelho. Os áudios continuam na Biblioteca.'),
        const SizedBox(height: 16),
        if (widget.model.namedDrafts.isEmpty) const Text('Nenhum rascunho salvo.'),
        ...widget.model.namedDrafts.map((draft) => ListTile(
          title: Text(draft.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${draft.content.runes.length} caracteres'),
          onTap: () async {
            final replace = text.text.trim().isEmpty || await confirmSheet(ctx,
              title: 'Abrir rascunho?',
              message: 'O texto atual será substituído. Salve-o como rascunho antes, se desejar.',
              action: 'Abrir');
            if (!replace || !mounted || !ctx.mounted) return;
            draftTimer?.cancel();
            text.text = draft.content;
            await widget.model.setDraft(draft.content);
            if (mounted) setState(() {});
            if (ctx.mounted) Navigator.pop(ctx);
          },
          trailing: IconButton(icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Excluir rascunho', onPressed: () async {
              final yes = await confirmSheet(ctx, title: 'Excluir rascunho?',
                message: 'O texto salvo será removido. Áudios não serão afetados.',
                action: 'Excluir', destructive: true);
              if (!yes) return;
              await widget.model.deleteNamedDraft(draft.id);
              refreshSheet(() {});
            }),
        )),
      ]))),
    ));
  }

  Future<void> importTextFile() async {
    try {
      final imported = await TextTransfer.importText();
      if (!mounted || imported == null) return;
      final proceed = text.text.trim().isEmpty || await confirmSheet(context,
        title: 'Importar texto?', message: 'Isso substituirá o texto atual. Salve como rascunho antes, se necessário.',
        action: 'Importar');
      if (!proceed || !mounted) return;
      draftTimer?.cancel();
      text.text = imported;
      await widget.model.setDraft(imported);
      if (mounted) { setState(() {}); notice(context, 'Texto importado.'); }
    } catch (e, stack) {
      AppDiagnostics.instance.capture('TEXTO_IMPORTAR', e, stack);
      if (mounted) notice(context, 'Não foi possível importar. Use um arquivo TXT com até 50.000 caracteres.');
    }
  }

  Future<void> showParts() async {
    final parts = TextDrafts.split(text.text);
    if (parts.length <= 1) { notice(context, 'O texto já cabe em uma geração.'); return; }
    await showModalBottomSheet<void>(context: context, showDragHandle: true,
      isScrollControlled: true, builder: (ctx) => SafeArea(child: SizedBox(
      height: MediaQuery.sizeOf(ctx).height * .65,
      child: ListView(padding: const EdgeInsets.all(18), children: [
        Text('Dividir em ${parts.length} partes', style: Theme.of(ctx).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text('Selecione uma parte para editar e gerar individualmente. Salve o texto completo como rascunho antes de substituir.'),
        for (var i = 0; i < parts.length; i++) ListTile(
          title: Text('Parte ${i + 1} • ${parts[i].runes.length} caracteres'),
          subtitle: Text(parts[i], maxLines: 2, overflow: TextOverflow.ellipsis),
          onTap: () async {
            final confirmed = await confirmSheet(ctx, title: 'Abrir parte ${i + 1}?',
              message: 'O texto completo será substituído no editor. Salve o texto inteiro como rascunho antes de prosseguir.',
              action: 'Abrir parte');
            if (!confirmed || !mounted || !ctx.mounted) return;
            draftTimer?.cancel();
            text.text = parts[i];
            await widget.model.setDraft(parts[i]);
            if (mounted) setState(() {});
            if (ctx.mounted) Navigator.pop(ctx);
          },
        ),
      ]))));
  }

  Future<void> generate() async {
    // Trava imediata inclusive durante a confirmação e compartilhada no modelo.
    if (confirming || generating || widget.model.generationInProgress) return;
    confirming = true;
    try {
      if (widget.model.key.isEmpty) {
        notice(context, 'Adicione sua chave API em Configurações.');
        widget.openSettings();
        return;
      }
      if (!widget.model.canSaveAudio) {
        notice(context, 'Biblioteca indisponível. Reinicie o aplicativo e consulte o Diagnóstico antes de gastar créditos.');
        return;
      }
      final voice = widget.model.selectedVoice;
      if (voice == null) {
        notice(context, 'Escolha uma voz para gerar o áudio.');
        widget.openVoices();
        return;
      }
      final access = evaluateVoiceAccess(voice, widget.model.subscription?.tier);
      if (access.isRestricted) {
        notice(context, '${access.label}: escolha outra voz ou confira sua assinatura.');
        return;
      }
      final content = text.text.trim();
      if (content.isEmpty) {
        notice(context, 'Digite seu texto primeiro.');
        return;
      }
      if (content.runes.length > 5000) {
        notice(context, 'O texto deve ter no máximo 5.000 caracteres.');
        return;
      }
      if (widget.model.confirmCreditsBeforeGenerate) {
        final estimate = CreditEstimator.baseEstimate(
          CreditEstimator.characterCount(content))!;
        final remaining = widget.model.subscription?.remaining;
        final charCount = CreditEstimator.characterCount(content);
        final approved = await confirmSheet(context,
          title: 'Confirmar geração de áudio',
          message: 'Este texto tem $charCount caracteres. Para Eleven Multilingual v2, a referência base é de aproximadamente $estimate créditos, antes de eventuais multiplicadores e condições da conta. '
            'A cobrança efetiva depende das condições da ElevenLabs. '
            '${remaining == null ? 'Saldo não disponível na consulta atual.' : 'Saldo informado pela API: $remaining.'} '
            '${voice.hasCustomRate ? 'A voz informa tarifa específica: o valor real pode ser superior à base. ' : ''}'
            'Deseja gerar e salvar o áudio?',
          action: 'Gerar áudio');
        if (!approved || !mounted) return;
      }
      if (!widget.model.tryBeginGeneration()) {
        if (mounted) notice(context, 'Outra geração já está em andamento.');
        return;
      }
      if (mounted) setState(() => generating = true);
      var audioReceived = false;
      var audioSaved = false;
      try {
        final Uint8List bytes = await widget.model.api.synthesize(
          voiceId: voice.id, text: content);
        audioReceived = true;
        // Primeiro preservar os bytes recebidos. Um erro de preferências ou
        // histórico não pode impedir o MP3 de chegar à Biblioteca.
        final audio = await widget.model.saveAudio(bytes, content, voice);
        audioSaved = true;
        if (mounted) setState(() => lastAudio = audio);
        try {
          await widget.model.recordGeneratedCharacters(content,
            modelId: CreditEstimator.defaultModel);
        } catch (ledgerError, ledgerStack) {
          AppDiagnostics.instance.capture('ESTUDIO_CONSUMO_LOCAL', ledgerError, ledgerStack);
          // A geração já foi salva: não informar falha de geração.
        }
        if (!mounted) return;
        try {
          await player.setFilePath(audio.path);
        } catch (error, stack) {
          AppDiagnostics.instance.capture('ESTUDIO_CARREGAR_PLAYER', error, stack);
          if (mounted) notice(context, 'MP3 salvo na Biblioteca, mas o player não conseguiu abri-lo.');
          return;
        }
        if (!mounted) return;
        unawaited(widget.model.refreshUsage());
        notice(context, 'Áudio gerado e salvo na Biblioteca.');
      } catch (error, stack) {
        final failure = GenerationFailure.classify(error,
          audioReceived: audioReceived, audioSaved: audioSaved);
        AppDiagnostics.instance.capture('ESTUDIO_GERAR', error, stack);
        AppDiagnostics.instance.failure('ESTUDIO_ETAPA', failure.diagnostic);
        if (mounted) {
          FocusScope.of(context).unfocus();
          await showGenerationFailure(context, failure);
        }
      } finally {
        widget.model.finishGeneration();
        if (mounted) setState(() => generating = false);
      }
    } finally {
      confirming = false;
    }
  }

  Future<void> showGenerationFailure(BuildContext context, GenerationFailure failure) async {
    await showModalBottomSheet<void>(
      context: context, isScrollControlled: true, showDragHandle: true,
      builder: (ctx) => SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.error_outline_rounded, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(failure.title,
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 16),
          Text(failure.message),
          if (failure.httpStatus != null) ...[
            const SizedBox(height: 10),
            Text('Código da API: HTTP ${failure.httpStatus}',
              style: Theme.of(ctx).textTheme.labelLarge),
          ],
          const SizedBox(height: 10),
          Text(failure.nextAction),
          if (failure.httpStatus == 402) ...[
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text('Consultar créditos e consumo'),
              onPressed: () {
                Navigator.of(ctx).pop();
                if (!mounted) return;
                unawaited(widget.model.refreshUsage());
                unawaited(showUsageSheet(context, widget.model));
              },
            )),
          ],
          const SizedBox(height: 18),
          Row(children: [
            OutlinedButton.icon(onPressed: () async {
              await Clipboard.setData(ClipboardData(text: failure.report));
              if (ctx.mounted) notice(ctx, 'Resumo técnico copiado, sem textos nem chave.');
            }, icon: const Icon(Icons.copy_rounded), label: const Text('Copiar erro')),
            const SizedBox(width: 10),
            Expanded(child: FilledButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Fechar'))),
          ]),
        ]),
      )),
    );
  }

  Future<void> togglePlay() async {
    if (lastAudio == null) return;
    try {
      if (player.playing) {
        await player.pause();
      } else {
        if (player.processingState == ProcessingState.completed) {
          await player.seek(Duration.zero);
        }
        await player.play();
      }
    } catch (e, stack) {
      AppDiagnostics.instance.capture('ESTUDIO_REPRODUZIR', e, stack);
      if (mounted) notice(context, 'Falha ao reproduzir o áudio salvo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final voice = widget.model.selectedVoice;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(19, 8, 19, 30),
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Text('Estúdio', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(width: 9),
            Expanded(child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () => showUsageSheet(context, widget.model,
                upcomingCharacters: text.text.trim().runes.length),
              icon: const Icon(Icons.toll_outlined, size: 17),
              label: FittedBox(fit: BoxFit.scaleDown, child: Text(
                widget.model.subscription?.used != null &&
                widget.model.subscription?.limit != null
                ? '${widget.model.subscription!.used} / ${widget.model.subscription!.limit}'
                : widget.model.refreshingUsage ? 'Consultando…' : 'Consumo mensal',
                maxLines: 1,
              )),
            )),
          ]),
          if (widget.model.creditWarningThreshold > 0) ...[
            const SizedBox(height: 8),
            Semantics(label: 'Aviso de consumo da assinatura', child: UaiVozesCard(
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('Sua conta atingiu pelo menos '
                    '${widget.model.creditWarningThreshold}% do limite reportado. '
                    'Confira o consumo antes de gerar.',
                    style: const TextStyle(fontSize: 12))),
              ]))),
          ],
          const SizedBox(height: 4),
          Text('Suas palavras, outra dimensão sonora.', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 18),
          Row(children: [
            const Expanded(child: SectionTitle('Seu texto')),
            IconButton(onPressed: importTextFile, tooltip: 'Importar TXT',
              icon: const Icon(Icons.file_open_rounded)),
            IconButton(onPressed: saveNamedDraft, tooltip: 'Salvar rascunho',
              icon: const Icon(Icons.save_outlined)),
            IconButton(onPressed: showDrafts, tooltip: 'Rascunhos salvos',
              icon: const Icon(Icons.folder_open_rounded)),
          ]),
          TextField(
            controller: text,
            minLines: 6,
            maxLines: 12,
            maxLength: TextDrafts.maxCharacters,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Digite ou cole aqui o texto que deseja transformar em áudio…',
              alignLabelWithHint: true,
            ),
            onChanged: (_) {
              setState(() {});
              draftTimer?.cancel();
              draftTimer = Timer(const Duration(milliseconds: 700),
                  () => widget.model.setDraft(text.text));
            },
          ),
          if (text.text.trim().runes.length > 5000) Padding(
            padding: const EdgeInsets.only(top: 7), child: OutlinedButton.icon(
              icon: const Icon(Icons.call_split_rounded), onPressed: showParts,
              label: const Text('Dividir texto em partes de até 5.000 caracteres'))),
          const SizedBox(height: 10),
          const SectionTitle('Voz selecionada'),
          UaiVozesCard(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: widget.openVoices,
              child: Row(children: [
                CircleAvatar(radius: 25, backgroundColor: theme.colorScheme.primaryContainer,
                    child: const Icon(Icons.mic_none_rounded)),
                const SizedBox(width: 13),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(voice?.name ?? 'Escolher voz',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(voice == null ? 'Explore as vozes disponíveis' :
                      (voice.summary.isEmpty ? 'ElevenLabs' : voice.summary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
                const Icon(Icons.keyboard_arrow_right_rounded),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          UaiVozesCard(child: Row(children: [
            const Icon(Icons.language_rounded),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Modelo multilíngue', style: TextStyle(fontWeight: FontWeight.w700)),
              Text(languages[widget.model.language] ?? 'Multilíngue', style: theme.textTheme.bodySmall),
            ])),
            const Icon(Icons.check_circle_outline_rounded),
          ])),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: generating || confirming || widget.model.generationInProgress ? null : generate,
            icon: generating
                ? const SizedBox(height: 19, width: 19, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_awesome_rounded),
            label: Padding(padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text(generating ? 'Gerando áudio…' : 'Gerar e salvar áudio')),
          ),
          const SizedBox(height: 9),
          Text('A geração pode consumir créditos ElevenLabs e requer internet.',
              textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
          if (lastAudio != null) ...[
            const SizedBox(height: 22),
            const SectionTitle('Resultado'),
            UaiVozesCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.library_music_rounded),
                const SizedBox(width: 10),
                Expanded(child: Text(lastAudio!.name, maxLines: 2,
                    overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                IconButton.filledTonal(
                    onPressed: togglePlay,
                    icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded)),
                Expanded(child: StreamBuilder<Duration>(
                  stream: player.positionStream,
                  builder: (ctx, snapshot) {
                    final total = player.duration?.inMilliseconds ?? 0;
                    final now = snapshot.data?.inMilliseconds ?? 0;
                    return Slider(
                      value: (total > 0 ? now.clamp(0, total).toDouble() / total : 0),
                      onChanged: total <= 0 ? null : (v) => player.seek(Duration(milliseconds: (v * total).round())),
                    );
                  },
                )),
              ]),
              Text('Salvo na Biblioteca • Disponível offline', style: theme.textTheme.bodySmall),
            ])),
          ],
        ],
      ),
    );
  }
}
