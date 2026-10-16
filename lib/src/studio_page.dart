import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'app_model.dart';
import 'account_page.dart';
import 'diagnostics.dart';
import 'models.dart';
import 'ui.dart';

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
        final estimate = content.runes.length;
        final remaining = widget.model.subscription?.remaining;
        final approved = await confirmSheet(context,
          title: 'Confirmar geração de áudio',
          message: 'Este texto tem $estimate caracteres. Com o modelo Eleven Multilingual v2, o consumo estimado é de aproximadamente $estimate créditos (referência de 1 por caractere). '
            'A cobrança efetiva depende das condições da ElevenLabs. '
            '${remaining == null ? 'Saldo não disponível na consulta atual.' : 'Saldo informado pela API: $remaining.'} '
            'Deseja gerar e salvar o áudio?',
          action: 'Gerar áudio');
        if (!approved || !mounted) return;
      }
      if (!widget.model.tryBeginGeneration()) {
        if (mounted) notice(context, 'Outra geração já está em andamento.');
        return;
      }
      if (mounted) setState(() => generating = true);
      try {
        final Uint8List bytes = await widget.model.api.synthesize(
          voiceId: voice.id, text: content);
        // A API já pode ter cobrado. Não repetir automaticamente em erro.
        await widget.model.recordGeneratedCharacters(content);
        final audio = await widget.model.saveAudio(bytes, content, voice);
        if (!mounted) return;
        setState(() => lastAudio = audio); // Salvo mesmo se o player falhar.
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
        AppDiagnostics.instance.capture('ESTUDIO_GERAR', error, stack);
        if (mounted) notice(context,
          'Não foi possível concluir a geração ou o salvamento. '
          'Antes de repetir, confira sua Biblioteca e os créditos da ElevenLabs.');
      } finally {
        widget.model.finishGeneration();
        if (mounted) setState(() => generating = false);
      }
    } finally {
      confirming = false;
    }
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
          const SizedBox(height: 4),
          Text('Suas palavras, outra dimensão sonora.', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 18),
          const SectionTitle('Seu texto'),
          TextField(
            controller: text,
            minLines: 6,
            maxLines: 12,
            maxLength: 5000,
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
