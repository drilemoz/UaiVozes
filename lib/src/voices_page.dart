import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'app_model.dart';
import 'diagnostics.dart';
import 'models.dart';
import 'ui.dart';

const voiceStyles = <String, String>{
  'all': 'Todos os estilos',
  'calm': 'Calma',
  'expressive': 'Expressiva',
  'soft': 'Suave',
  'energetic': 'Enérgica',
  'deep': 'Grave',
};

const voiceCategories = <String, String>{
  'all': 'Todas',
  'narrative_story': 'Narração',
  'conversational': 'Conversa',
  'characters_animation': 'Personagens',
  'educational': 'Educação',
  'social_media': 'Redes sociais',
  'advertisement': 'Publicidade',
};

class VoicesPage extends StatefulWidget {
  const VoicesPage({super.key, required this.model, required this.onChosen, required this.openSettings});
  final AppModel model;
  final VoidCallback onChosen;
  final VoidCallback openSettings;

  @override
  State<VoicesPage> createState() => _VoicesPageState();
}

class _VoicesPageState extends State<VoicesPage> {
  final searchController = TextEditingController();
  final previewPlayer = AudioPlayer();
  final List<Voice> ownVoices = [];
  final List<Voice> ranking = [];
  String category = 'all';
  String voiceStyle = 'all';
  String? nextToken;
  bool loading = false;
  bool rankingMode = false;
  bool favoritesOnly = false;
  bool usingLanguageFallback = false;
  String? error;
  String? playingId;

  @override
  void initState() {
    super.initState();
    Future.microtask(refresh);
    previewPlayer.playerStateStream.listen((state) {
      if (mounted && state.processingState == ProcessingState.completed) {
        setState(() => playingId = null);
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    previewPlayer.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    if (loading) return;
    setState(() {
      loading = true;
      error = null;
      nextToken = null;
      usingLanguageFallback = false;
      ownVoices.clear();
      ranking.clear();
    });
    try {
      if (rankingMode) {
        if (widget.model.language == 'all') {
          throw const FormatException('Selecione um idioma para ver as 10 mais usadas.');
        }
        final result = await widget.model.api.topTen(
          language: widget.model.language,
          useCase: category == 'all' ? null : category,
          descriptive: voiceStyle == 'all' ? null : voiceStyle,
        );
        if (!mounted) return;
        ranking.addAll(result);
      } else {
        var result = await widget.model.api.voices(language: widget.model.language);
        // Algumas vozes padrão são multilíngues mas não possuem rótulo de idioma.
        // Fallback informado, sem atribuir idioma inexistente à voz.
        if (result.voices.isEmpty && widget.model.language != 'all') {
          result = await widget.model.api.voices();
          usingLanguageFallback = true;
        }
        if (!mounted) return;
        ownVoices.addAll(result.voices);
        nextToken = result.nextToken;
      }
    } catch (e, stack) {
      AppDiagnostics.instance.capture('VOZES_CARREGAR', e, stack);
      if (mounted) error = '$e';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> more() async {
    if (loading || rankingMode || nextToken == null) return;
    setState(() => loading = true);
    try {
      final result = await widget.model.api.voices(
          language: usingLanguageFallback ? null : widget.model.language, token: nextToken);
      if (!mounted) return;
      ownVoices.addAll(result.voices);
      nextToken = result.nextToken;
    } catch (e, stack) {
      AppDiagnostics.instance.capture('VOZES_REDE', e, stack);
      if (mounted) notice(context, '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> preview(Voice voice) async {
    try {
      var url = voice.previewUrl;
      if (playingId == voice.id && previewPlayer.playing) {
        await previewPlayer.stop();
        if (mounted) setState(() => playingId = null);
        return;
      }
      await previewPlayer.stop();
      if (url.isEmpty && !rankingMode) {
        final detail = await widget.model.api.voiceDetail(voice.id);
        url = detail.previewUrl;
      }
      if (url.isEmpty) {
        if (mounted) notice(context, 'Esta voz não fornece uma prévia de áudio.');
        return;
      }
      final uri = Uri.tryParse(url);
      if (uri == null || uri.scheme != 'https') {
        throw const FormatException('URL de prévia inválida');
      }
      await previewPlayer.setUrl(url);
      if (!mounted) return;
      setState(() => playingId = voice.id);
      await previewPlayer.play();
    } catch (e, stack) {
      AppDiagnostics.instance.capture('VOZES_PREVIA', e, stack);
      if (mounted) notice(context, 'Não foi possível ouvir a prévia.');
    }
  }

  Future<void> select(Voice voice) async {
    if (rankingMode && voice.publicOwnerId.isNotEmpty) {
      final confirmed = await confirmSheet(context,
        title: 'Adicionar voz à sua conta?',
        message: '“${voice.name}” está na biblioteca pública. A ElevenLabs precisa adicionar essa voz à sua conta antes de gerar áudio. Pode haver restrições de plano ou de vagas.',
        action: 'Adicionar voz',
      );
      if (!confirmed || !mounted) return;
      try {
        final id = await widget.model.api.addSharedVoice(voice);
        widget.model.pickVoice(Voice(
          id: id, name: voice.name, category: voice.category,
          description: voice.description, accent: voice.accent,
          language: voice.language, useCase: voice.useCase, style: voice.style,
          previewUrl: voice.previewUrl,
        ));
        if (mounted) notice(context, 'Voz adicionada à conta.');
        widget.onChosen();
      } catch (e, stack) {
        AppDiagnostics.instance.capture('VOZES_SELECIONAR', e, stack);
        if (mounted) notice(context, '$e');
      }
      return;
    }
    widget.model.pickVoice(voice);
    widget.onChosen();
  }

  bool matches(Voice voice) {
    final query = searchController.text.trim().toLowerCase();
    final haystack = '${voice.name} ${voice.description} ${voice.summary} ${voice.accent} ${voice.gender}'
        .toLowerCase();
    if (query.isNotEmpty && !haystack.contains(query)) return false;
    if (favoritesOnly && !widget.model.favoriteIds.contains(voice.id)) return false;
    if (voiceStyle != 'all' && !rankingMode &&
        !'${voice.style} ${voice.description}'.toLowerCase().contains(voiceStyle)) {
      return false;
    }
    if (!rankingMode && category != 'all') {
      final hay = '${voice.useCase} ${voice.description}'.toLowerCase().replaceAll(' ', '_');
      final key = category.toLowerCase();
      if (!hay.contains(key) && !(key == 'narrative_story' && hay.contains('narrat')) &&
          !(key == 'conversational' && hay.contains('convers'))) return false;
    }
    return true;
  }

  Widget _chip(String label, bool selected, VoidCallback onPressed) =>
      FilterChip(label: Text(label), selected: selected, onSelected: (_) => onPressed(),
          showCheckmark: false);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visible = (rankingMode ? ranking : ownVoices).where(matches).toList();
    return SafeArea(child: RefreshIndicator(
      onRefresh: refresh,
      child: ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 26), children: [
        Row(children: [
          Expanded(child: Text('Explorar vozes', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800))),
          IconButton(icon: const Icon(Icons.tune_rounded), tooltip: 'Filtrar vozes', onPressed: () => showModalBottomSheet(
              context: context, showDragHandle: true, isScrollControlled: true,
              builder: (ctx) => SafeArea(child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 5, 24, 24),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Filtrar por categoria', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 5, children: voiceCategories.entries.map((e) =>
                      ChoiceChip(label: Text(e.value), selected: category == e.key, onSelected: (_) {
                        setState(() => category = e.key);
                        Navigator.pop(ctx);
                        if (rankingMode) refresh();
                      })).toList()),
                  const SizedBox(height: 19),
                  const Text('Estilo da voz', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 9),
                  Wrap(spacing: 8, runSpacing: 5, children: voiceStyles.entries.map((e) =>
                      ChoiceChip(label: Text(e.value), selected: voiceStyle == e.key,
                        onSelected: (_) {
                          setState(() => voiceStyle = e.key);
                          Navigator.pop(ctx);
                          if (rankingMode) refresh();
                        })).toList()),
                ]),
              )))
          ),
        ]),
        const SizedBox(height: 16),
        TextField(
          controller: searchController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            hintText: 'Buscar por nome ou característica…',
          ),
        ),
        const SizedBox(height: 13),
        Wrap(spacing: 8, runSpacing: 2, crossAxisAlignment: WrapCrossAlignment.center, children: [
          DropdownButtonHideUnderline(child: DropdownButton<String>(
            value: widget.model.language,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            borderRadius: BorderRadius.circular(19),
            items: languages.entries.map((e) => DropdownMenuItem(
                value: e.key, child: Text(e.value))).toList(),
            onChanged: (val) async {
              if (val == null) return;
              await widget.model.setLanguage(val);
              await refresh();
            },
          )),
          _chip('Minhas vozes', !rankingMode, () {setState(() => rankingMode = false); refresh();}),
          _chip('Top 10', rankingMode, () {setState(() => rankingMode = true); refresh();}),
          _chip('Favoritas', favoritesOnly, () => setState(() => favoritesOnly = !favoritesOnly)),
        ]),
        if (category != 'all' || voiceStyle != 'all') Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Icon(Icons.filter_list_rounded, color: theme.colorScheme.primary, size: 19),
            const SizedBox(width: 7),
            Expanded(child: Text([
              if (category != 'all') voiceCategories[category] ?? category,
              if (voiceStyle != 'all') voiceStyles[voiceStyle] ?? voiceStyle,
            ].join(' • '))),
            TextButton(onPressed: () { setState(() { category = 'all'; voiceStyle = 'all'; }); if (rankingMode) refresh(); },
                child: const Text('Limpar')),
          ]),
        ),
        Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(
          rankingMode ? 'Classificação real por caracteres utilizados no último ano. Depende do acesso à Voice Library.'
              : 'Vozes retornadas pela sua conta ElevenLabs. Toque numa voz para usá-la.',
          style: theme.textTheme.bodySmall,
        )),
        if (usingLanguageFallback && !rankingMode && widget.model.key.isNotEmpty)
          Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(
            'Não há vozes marcadas com esse idioma. Exibindo vozes da conta, que podem ser multilíngues.',
            style: theme.textTheme.bodySmall)),
        if (widget.model.key.isEmpty)
          EmptyState(icon: Icons.key_rounded, title: 'Conecte sua conta',
              description: 'É necessário configurar uma chave API para explorar vozes.',
              action: FilledButton(onPressed: widget.openSettings, child: const Text('Configurar API')))
        else if (error != null)
          EmptyState(icon: Icons.lock_outline_rounded, title: rankingMode ? 'Ranking indisponível' : 'Não foi possível listar vozes',
              description: error!,
              action: OutlinedButton(onPressed: refresh, child: const Text('Tentar novamente')))
        else if (visible.isEmpty && !loading)
          EmptyState(icon: Icons.mic_off_outlined, title: 'Nenhuma voz encontrada',
              description: rankingMode ? 'Não há ranking acessível para esse idioma/filtro.'
                  : 'Experimente outra categoria, idioma ou termo de busca.',
              action: OutlinedButton(onPressed: () {searchController.clear(); setState(() { category = 'all'; voiceStyle = 'all'; }); refresh();},
                  child: const Text('Limpar filtros')))
        else ...visible.map((voice) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: UaiVozesCard(child: Row(children: [
            CircleAvatar(radius: 25,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              child: Icon(Icons.mic_none_rounded, color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(width: 12),
            Expanded(child: InkWell(
              onTap: () => select(voice),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(voice.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                Text(voice.summary.isEmpty ? 'Voz ElevenLabs' : voice.summary,
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                if (rankingMode && voice.annualCharacters != null)
                  Text('${voice.annualCharacters} caracteres/ano', style: theme.textTheme.labelSmall),
              ]),
            )),
            IconButton(tooltip: 'Ouvir prévia', onPressed: () => preview(voice),
              icon: Icon(playingId == voice.id ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
                  color: theme.colorScheme.primary)),
            IconButton(tooltip: 'Favoritar', onPressed: () async {
              await widget.model.toggleFavorite(voice.id);
              if (mounted) setState(() {});
            }, icon: Icon(widget.model.favoriteIds.contains(voice.id)
                ? Icons.favorite_rounded : Icons.favorite_border_rounded)),
          ])),
        )),
        if (loading) const Padding(padding: EdgeInsets.all(18),
            child: Center(child: CircularProgressIndicator())),
        if (!rankingMode && nextToken != null && !loading)
          OutlinedButton.icon(onPressed: more,
              icon: const Icon(Icons.expand_more_rounded), label: const Text('Carregar mais vozes')),
      ]),
    ));
  }
}
