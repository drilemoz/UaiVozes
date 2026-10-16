import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'app_model.dart';
import 'diagnostics.dart';
import 'eleven_api.dart';
import 'models.dart';
import 'ui.dart';
import 'voice_browse_cache.dart';
import 'voice_access.dart';

const voiceStyles = <String, String>{
  'all': 'Todos os estilos',
  'calm': 'Calma', 'expressive': 'Expressiva', 'soft': 'Suave',
  'energetic': 'Enérgica', 'deep': 'Grave',
};

const voiceCategories = <String, String>{
  'all': 'Todas',
  'narrative_story': 'Narração', 'conversational': 'Conversa',
  'characters_animation': 'Personagens', 'educational': 'Educação',
  'social_media': 'Redes sociais', 'advertisement': 'Publicidade',
};

const voiceGenders = <String, String>{
  'all': 'Todos', 'female': 'Feminina', 'male': 'Masculina',
};
const voiceAges = <String, String>{
  'all': 'Todas', 'young': 'Jovem', 'middle_aged': 'Adulta', 'old': 'Idosa',
};
const voiceAccents = <String, String>{
  'all': 'Todos', 'brazilian': 'Brasileiro', 'portuguese': 'Português',
  'american': 'Americano', 'british': 'Britânico',
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
  final cache = VoiceBrowseCache();
  final List<Voice> ownVoices = [];
  final List<Voice> ranking = [];
  final Map<String, Voice> verifiedVoices = {};
  final Set<String> checkingVoices = {};
  VoiceAccessFilter accessFilter = VoiceAccessFilter.all;
  Timer? searchDebounce;
  StreamSubscription<PlayerState>? playerStateSubscription;
  String category = 'all';
  String voiceStyle = 'all';
  String gender = 'all';
  String age = 'all';
  String accent = 'all';
  String? nextToken;
  bool loading = false;
  bool loadingMore = false;
  bool rankingMode = false;
  bool favoritesOnly = false;
  String? error;
  String? playingId;
  int requestVersion = 0;
  int previewVersion = 0;
  late String observedKey;
  late String observedLanguage;
  late String observedTier;
  late bool observedRefreshingUsage;
  String? observedUsageError;

  @override
  void initState() {
    super.initState();
    observedKey = widget.model.key;
    observedLanguage = widget.model.language;
    observedTier = widget.model.subscription?.tier ?? '';
    observedRefreshingUsage = widget.model.refreshingUsage;
    observedUsageError = widget.model.usageError;
    widget.model.addListener(onModelUpdated);
    playerStateSubscription = previewPlayer.playerStateStream.listen((state) {
      if (mounted && state.processingState == ProcessingState.completed) {
        setState(() => playingId = null);
      }
    }, onError: (Object error, StackTrace stack) =>
        AppDiagnostics.instance.capture('VOZES_PREVIA_STREAM', error, stack));
    Future.microtask(refresh);
  }

  void onModelUpdated() {
    final keyChanged = observedKey != widget.model.key;
    final languageChanged = observedLanguage != widget.model.language;
    final nextTier = widget.model.subscription?.tier ?? '';
    final tierChanged = observedTier != nextTier;
    final usageChanged = observedRefreshingUsage != widget.model.refreshingUsage ||
        observedUsageError != widget.model.usageError;
    if (!keyChanged && !languageChanged && !tierChanged && !usageChanged) return;
    observedKey = widget.model.key;
    observedLanguage = widget.model.language;
    observedTier = nextTier;
    observedRefreshingUsage = widget.model.refreshingUsage;
    observedUsageError = widget.model.usageError;
    if (keyChanged || languageChanged) {
      cache.clear(); // dados e detalhes de outra conta/idioma não são reutilizados.
      verifiedVoices.clear();
      checkingVoices.clear();
      requestVersion++;
      previewVersion++;
      unawaited(previewPlayer.stop());
      unawaited(refresh());
    } else if (mounted) {
      // O plano mudou após GET /v1/user/subscription: recalcular filtro local.
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.model.removeListener(onModelUpdated);
    searchDebounce?.cancel();
    searchController.dispose();
    playerStateSubscription?.cancel();
    previewPlayer.dispose();
    super.dispose();
  }

  String cacheKey([String? token]) => voiceBrowseKey(
    language: widget.model.language, ranking: rankingMode,
    search: searchController.text, category: category,
    style: voiceStyle, gender: gender, age: age, accent: accent, token: token,
  );

  Future<VoicePage> fetch({String? token, required int revision}) async {
    final key = cacheKey(token);
    final activeKey = widget.model.key;
    final cached = cache.get(key);
    if (cached != null) return cached;
    late final VoicePage page;
    if (rankingMode) {
      if (widget.model.language == 'all') {
        throw const FormatException('Escolha um idioma antes de abrir o Top 10.');
      }
      final items = await widget.model.api.topTen(
        language: widget.model.language,
        useCase: category == 'all' ? null : category,
        descriptive: voiceStyle == 'all' ? null : voiceStyle,
      );
      page = VoicePage(items, null);
    } else {
      page = await widget.model.api.voices(
        language: widget.model.language, token: token,
        search: searchController.text.trim(),
        gender: gender, age: age, accent: accent, useCase: category,
      );
    }
    // Não reintroduzir dados da credencial anterior após uma troca de conta.
    if (mounted && revision == requestVersion && activeKey == widget.model.key) {
      cache.put(key, page);
    }
    return page;
  }

  Future<void> refresh({bool force = false}) async {
    if (!mounted) return;
    final request = ++requestVersion;
    final activeKey = widget.model.key;
    final activeLanguage = widget.model.language;
    if (force) { cache.clear(); verifiedVoices.clear(); checkingVoices.clear(); }
    setState(() {
      loading = true;
      loadingMore = false;
      error = null;
      nextToken = null;
      ownVoices.clear();
      ranking.clear();
      playingId = null;
    });
    if (activeKey.isEmpty) {
      if (mounted && request == requestVersion) setState(() => loading = false);
      return;
    }
    try {
      final result = await fetch(revision: request);
      if (!mounted || request != requestVersion || widget.model.key != activeKey ||
          widget.model.language != activeLanguage) return;
      setState(() {
        if (rankingMode) { ranking.addAll(result.voices); }
        else { ownVoices.addAll(result.voices); nextToken = result.nextToken; }
      });
    } catch (e, stack) {
      AppDiagnostics.instance.capture('VOZES_CARREGAR', e, stack);
      if (mounted && request == requestVersion) setState(() => error = friendlyError(e));
    } finally {
      if (mounted && request == requestVersion) setState(() => loading = false);
    }
  }

  Future<void> more() async {
    final token = nextToken;
    if (loading || loadingMore || rankingMode || token == null) return;
    final request = requestVersion;
    final activeKey = widget.model.key;
    setState(() => loadingMore = true);
    try {
      final result = await fetch(token: token, revision: request);
      if (!mounted || requestVersion != request || widget.model.key != activeKey) return;
      final known = ownVoices.map((e) => e.id).toSet();
      setState(() {
        ownVoices.addAll(result.voices.where((e) => known.add(e.id)));
        nextToken = result.nextToken == token ? null : result.nextToken;
      });
    } catch (e, stack) {
      AppDiagnostics.instance.capture('VOZES_PAGINAR', e, stack);
      if (mounted && requestVersion == request) notice(context, friendlyError(e));
    } finally {
      if (mounted && requestVersion == request) setState(() => loadingMore = false);
    }
  }

  void onSearch(String _) {
    searchDebounce?.cancel();
    if (!mounted) return;
    setState(() {});
    // O servidor pesquisa todo o catálogo, não apenas a primeira página.
    // No ranking a API pública não fornece busca por texto; filtro local.
    if (rankingMode) return;
    searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) unawaited(refresh());
    });
  }

  Future<void> preview(Voice voice) async {
    final sequence = ++previewVersion;
    try {
      if (playingId == voice.id) {
        await previewPlayer.stop();
        if (mounted && sequence == previewVersion) setState(() => playingId = null);
        return;
      }
      await previewPlayer.stop();
      var url = voice.previewUrl;
      if (url.isEmpty && !rankingMode) {
        url = (await widget.model.api.voiceDetail(voice.id)).previewUrl;
      }
      if (!mounted || sequence != previewVersion) return;
      if (url.isEmpty) {
        notice(context, 'Esta voz não oferece uma prévia.');
        return;
      }
      final uri = Uri.tryParse(url);
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
        throw const FormatException('Endereço de prévia inválido');
      }
      await previewPlayer.setUrl(url);
      if (!mounted || sequence != previewVersion) return;
      setState(() => playingId = voice.id);
      // play() só termina após a reprodução: não bloquear a interação até lá.
      unawaited(previewPlayer.play().catchError((Object error, StackTrace stack) {
        AppDiagnostics.instance.capture('VOZES_PREVIA_AUDIO', error, stack);
        if (mounted && sequence == previewVersion) {
          setState(() => playingId = null);
          notice(context, 'Não foi possível reproduzir a prévia.');
        }
      }));
    } catch (e, stack) {
      AppDiagnostics.instance.capture('VOZES_PREVIA', e, stack);
      if (mounted && sequence == previewVersion) notice(context, 'Não foi possível ouvir a prévia.');
    }
  }

  /// GET individual, somente por toque. Nunca executa TTS nem inicia
  /// uma verificação em lote ao filtrar ou paginar.
  Future<void> verifyVoice(Voice voice) async {
    if (checkingVoices.contains(voice.id) || widget.model.key.isEmpty) return;
    final key = widget.model.key;
    final revision = requestVersion;
    setState(() => checkingVoices.add(voice.id));
    try {
      final detail = await widget.model.api.voiceDetail(voice.id);
      if (!mounted || revision != requestVersion || key != widget.model.key) return;
      setState(() => verifiedVoices[voice.id] =
          mergeVoiceAccessMetadata(voice, detail));
      final info = evaluateVoiceAccess(verifiedVoices[voice.id]!,
          widget.model.subscription?.tier, publicLibrary: rankingMode);
      if (info.state == VoiceAccess.unknown) {
        notice(context, 'A API não confirmou o acesso a esta voz.');
      }
    } catch (e, stack) {
      AppDiagnostics.instance.capture('VOZES_DETALHE', e, stack);
      if (mounted && revision == requestVersion && key == widget.model.key) {
        notice(context, 'Não foi possível consultar os detalhes: ${friendlyError(e)}');
      }
    } finally {
      if (mounted && revision == requestVersion && key == widget.model.key) {
        setState(() => checkingVoices.remove(voice.id));
      }
    }
  }

  VoiceAccessInfo accessFor(Voice voice) => evaluateVoiceAccess(voice,
      widget.model.subscription?.tier, publicLibrary: rankingMode);

  Future<void> select(Voice voice) async {
    final access = accessFor(voice);
    if (access.isRestricted) {
      if (mounted) await showModalBottomSheet<void>(context: context,
        showDragHandle: true, builder: (ctx) => SafeArea(child: Padding(
          padding: const EdgeInsets.all(22), child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(access.label, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 10), Text(access.details),
            const SizedBox(height: 16), FilledButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Entendi')),
          ]))));
      return;
    }
    if (rankingMode && voice.publicOwnerId.isNotEmpty) {
      final confirmed = await confirmSheet(context,
        title: 'Adicionar voz à sua conta?',
        message: '“${voice.name}” pertence à biblioteca pública. Adicioná-la pode estar limitado por plano ou vagas.',
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
          availableForTiers: voice.availableForTiers,
          freeUsersAllowed: voice.freeUsersAllowed, hasCustomRate: voice.hasCustomRate,
        ));
        if (mounted) notice(context, 'Voz adicionada à conta.');
        widget.onChosen();
      } catch (e, stack) {
        AppDiagnostics.instance.capture('VOZES_SELECIONAR', e, stack);
        if (mounted) notice(context, friendlyError(e));
      }
      return;
    }
    widget.model.pickVoice(voice);
    widget.onChosen();
  }

  bool matches(Voice voice) {
    if (favoritesOnly && !widget.model.favoriteIds.contains(voice.id)) return false;
    if (!matchesVoiceAccessFilter(accessFilter, accessFor(voice))) return false;
    if (rankingMode) {
      final query = searchController.text.trim().toLowerCase();
      if (query.isNotEmpty &&
          !'${voice.name} ${voice.description} ${voice.summary}'.toLowerCase().contains(query)) return false;
      if (gender != 'all' && voice.gender.toLowerCase() != gender) return false;
      if (accent != 'all' && voice.accent.toLowerCase() != accent) return false;
    } else if (voiceStyle != 'all') {
      // Estilo é um filtro local: não presumir metadados que a API não fornece.
      if (!'${voice.style} ${voice.description}'.toLowerCase().contains(voiceStyle)) return false;
    }
    return true;
  }

  Widget _chip(String label, bool selected, VoidCallback onPressed) =>
      FilterChip(label: Text(label), selected: selected,
        onSelected: (_) => onPressed(), showCheckmark: false);

  Widget _filterRow(String title, Map<String, String> options, String selected,
      void Function(String) update, StateSetter updateSheet) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 14),
      Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 7),
      Wrap(spacing: 6, runSpacing: 2, children: options.entries.map((entry) =>
          ChoiceChip(label: Text(entry.value), selected: selected == entry.key,
            onSelected: (_) {
              setState(() => update(entry.key));
              updateSheet(() {});
            })).toList()),
    ]);
  }

  Future<void> showFilters() async {
    await showModalBottomSheet<void>(
      context: context, showDragHandle: true, isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(builder: (ctx, updateSheet) => SafeArea(
        child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Filtros de voz', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21)),
            _filterRow('Finalidade', voiceCategories, category, (v) => category = v, updateSheet),
            _filterRow('Estilo (descrição)', voiceStyles, voiceStyle, (v) => voiceStyle = v, updateSheet),
            _filterRow('Gênero', voiceGenders, gender, (v) => gender = v, updateSheet),
            if (!rankingMode) _filterRow('Faixa etária', voiceAges, age, (v) => age = v, updateSheet),
            _filterRow('Sotaque', voiceAccents, accent, (v) => accent = v, updateSheet),
            const SizedBox(height: 16),
            Row(children: [
              OutlinedButton(onPressed: () {
                setState(() { category = 'all'; voiceStyle = 'all'; gender = 'all';
                  age = 'all'; accent = 'all'; });
                Navigator.pop(ctx);
              }, child: const Text('Limpar')),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(onPressed: () => Navigator.pop(ctx),
                child: const Text('Aplicar filtros'))),
            ]),
          ]),
        ),
      )),
    );
    if (mounted) unawaited(refresh());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allLoaded = (rankingMode ? ranking : ownVoices)
        .map((voice) => verifiedVoices[voice.id] ?? voice).toList();
    final visible = allLoaded.where(matches).toList();
    final filterActive = category != 'all' || voiceStyle != 'all' || gender != 'all' ||
        age != 'all' || accent != 'all' || accessFilter != VoiceAccessFilter.all;
    return SafeArea(child: RefreshIndicator(
      onRefresh: () => refresh(force: true),
      child: ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 26), children: [
        Row(children: [
          Expanded(child: Text('Explorar vozes', style: theme.textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w800))),
          IconButton(
            icon: Icon(favoritesOnly ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: favoritesOnly ? theme.colorScheme.primary : null),
            tooltip: favoritesOnly ? 'Mostrar todas as vozes' : 'Mostrar só favoritas',
            isSelected: favoritesOnly,
            onPressed: () => setState(() => favoritesOnly = !favoritesOnly)),
          IconButton(icon: Icon(Icons.tune_rounded,
              color: filterActive ? theme.colorScheme.primary : null),
            tooltip: 'Filtrar vozes', onPressed: showFilters),
        ]),
        const SizedBox(height: 14),
        TextField(controller: searchController, onChanged: onSearch,
          decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded),
            hintText: rankingMode ? 'Buscar dentro das 10 vozes…' : 'Buscar em todas as vozes…',
            suffixIcon: searchController.text.isEmpty ? null : IconButton(
              icon: const Icon(Icons.clear_rounded), tooltip: 'Limpar busca',
              onPressed: () {searchController.clear(); onSearch('');}),
          )),
        const SizedBox(height: 11),
        SingleChildScrollView(scrollDirection: Axis.horizontal,
          child: Row(children: [
            DropdownButtonHideUnderline(child: DropdownButton<String>(
              value: widget.model.language,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              borderRadius: BorderRadius.circular(19),
              items: languages.entries.map((e) => DropdownMenuItem(
                value: e.key, child: Text(e.value))).toList(),
              onChanged: (val) async {
                if (val != null) await widget.model.setLanguage(val);
              },
            )),
            const SizedBox(width: 9),
            _chip('Minhas vozes', !rankingMode, () {
              if (rankingMode) {setState(() => rankingMode = false); unawaited(refresh());}
            }),
            const SizedBox(width: 7),
            _chip('Top 10', rankingMode, () {
              if (!rankingMode) {setState(() { rankingMode = true; age = 'all'; }); unawaited(refresh());}
            }),
          ])),
        const SizedBox(height: 8),
        SingleChildScrollView(scrollDirection: Axis.horizontal,
          child: Row(children: [
            _chip('Todas', accessFilter == VoiceAccessFilter.all,
              () => setState(() => accessFilter = VoiceAccessFilter.all)),
            const SizedBox(width: 6),
            _chip('Compatíveis com meu plano', accessFilter == VoiceAccessFilter.compatible,
              () => setState(() => accessFilter = VoiceAccessFilter.compatible)),
            const SizedBox(width: 6),
            _chip('Restritas', accessFilter == VoiceAccessFilter.restricted,
              () => setState(() => accessFilter = VoiceAccessFilter.restricted)),
            const SizedBox(width: 6),
            _chip('A confirmar', accessFilter == VoiceAccessFilter.unknown,
              () => setState(() => accessFilter = VoiceAccessFilter.unknown)),
          ])),
        if (filterActive) Padding(padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(children: [
            Icon(Icons.filter_list_rounded, color: theme.colorScheme.primary, size: 19),
            const SizedBox(width: 7),
            const Expanded(child: Text('Filtros ativos')),
            TextButton(onPressed: () {
              setState(() {category = 'all'; voiceStyle = 'all'; gender = 'all';
                age = 'all'; accent = 'all'; accessFilter = VoiceAccessFilter.all;});
              unawaited(refresh());
            }, child: const Text('Limpar')),
          ])),
        Padding(padding: const EdgeInsets.symmetric(vertical: 11),
          child: Text(rankingMode
              ? 'Top 10 real por uso no último ano; depende da permissão da conta. A busca filtra somente este Top 10.'
              : 'Busca e filtros de catálogo consultam a API. Compatibilidade é avaliada somente nas páginas carregadas, sem testar geração. Consulte detalhes de vozes a confirmar.',
            style: theme.textTheme.bodySmall)),
        if ((widget.model.subscription == null ||
             const ['desconhecido', 'unknown', ''].contains(
                 widget.model.subscription!.tier.trim().toLowerCase())) &&
            widget.model.key.isNotEmpty)
          Padding(padding: const EdgeInsets.only(bottom: 7), child: Row(children: [
            Expanded(child: Text('Plano desconhecido: consulte a assinatura para usar o filtro de compatibilidade.',
              style: theme.textTheme.bodySmall)),
            TextButton(onPressed: widget.model.refreshingUsage ? null : () =>
                unawaited(widget.model.refreshUsage()),
              child: Text(widget.model.refreshingUsage ? 'Consultando…' : 'Consultar plano')),
          ])),
        if (accessFilter != VoiceAccessFilter.all && widget.model.key.isNotEmpty)
          Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(
            '${visible.length} de ${allLoaded.length} vozes carregadas correspondem ao filtro. '
            'Sem garantia de acesso ao modelo, créditos ou custo.',
            style: theme.textTheme.bodySmall)),
        if (widget.model.key.isEmpty)
          EmptyState(icon: Icons.key_rounded, title: 'Conecte sua conta',
            description: 'Configure sua chave API para explorar vozes.',
            action: FilledButton(onPressed: widget.openSettings,
              child: const Text('Configurar API')))
        else if (error != null)
          EmptyState(icon: Icons.lock_outline_rounded,
            title: rankingMode ? 'Ranking indisponível' : 'Não foi possível listar vozes',
            description: error!,
            action: OutlinedButton(onPressed: () => refresh(force: true),
              child: const Text('Tentar novamente')))
        else if (visible.isEmpty && !loading)
          EmptyState(icon: Icons.mic_off_outlined, title: 'Nenhuma voz encontrada',
            description: loadingMore ? 'Buscando...' : rankingMode
                ? 'Sem dados para este idioma e filtro. O ranking pode exigir outro plano.'
                : accessFilter == VoiceAccessFilter.compatible
                    ? 'Nenhuma compatibilidade comprovada nas páginas carregadas. '
                      'Use “A confirmar” e consulte os detalhes de uma voz por vez.'
                    : accessFilter == VoiceAccessFilter.unknown
                      ? 'Nenhuma voz pendente de confirmação nas páginas carregadas.'
                      : accessFilter == VoiceAccessFilter.restricted
                        ? 'Nenhuma restrição identificada nas páginas carregadas.'
                        : 'A API não retornou vozes com estes filtros nesta página.',
            action: OutlinedButton(onPressed: () {
              searchDebounce?.cancel(); searchController.clear();
              setState(() {category = 'all'; voiceStyle = 'all'; gender = 'all';
                age = 'all'; accent = 'all'; favoritesOnly = false;
                accessFilter = VoiceAccessFilter.all;});
              unawaited(refresh(force: true));
            }, child: const Text('Limpar filtros')))
        else ...visible.map((voice) => Padding(padding: const EdgeInsets.only(bottom: 10),
          child: UaiVozesCard(child: Row(children: [
            CircleAvatar(radius: 25,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              child: Icon(Icons.mic_none_rounded, color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(width: 12),
            Expanded(child: InkWell(onTap: () => select(voice),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(voice.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                Text(voice.summary.isEmpty ? 'Voz ElevenLabs' : voice.summary,
                  maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                Builder(builder: (ctx) {
                  final info = accessFor(voice);
                  return Wrap(spacing: 7, runSpacing: 3, children: [
                    Text(info.label, style: theme.textTheme.labelSmall?.copyWith(
                      color: info.isRestricted ? theme.colorScheme.error
                          : info.isCompatible ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: info.state == VoiceAccess.unknown
                          ? FontWeight.normal : FontWeight.bold)),
                    if (info.specialRate) Text('Tarifa específica: conferir custo',
                        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)),
                  ]);
                }),
                if (rankingMode && voice.annualCharacters != null)
                  Text('${voice.annualCharacters} caracteres/ano', style: theme.textTheme.labelSmall),
                if (accessFor(voice).state == VoiceAccess.unknown)
                  Align(alignment: Alignment.centerLeft, child: TextButton.icon(
                    onPressed: checkingVoices.contains(voice.id) ? null : () => verifyVoice(voice),
                    icon: checkingVoices.contains(voice.id)
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.fact_check_outlined, size: 17),
                    label: const Text('Verificar acesso'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )),
              ]))),
            IconButton(tooltip: 'Ouvir prévia', onPressed: () => preview(voice),
              icon: Icon(playingId == voice.id ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
                color: theme.colorScheme.primary)),
            IconButton(tooltip: 'Favoritar', onPressed: () async {
              await widget.model.toggleFavorite(voice.id);
              if (mounted) setState(() {});
            }, icon: Icon(widget.model.favoriteIds.contains(voice.id)
                ? Icons.favorite_rounded : Icons.favorite_border_rounded)),
          ])))),
        if (loading) const Padding(padding: EdgeInsets.all(18),
          child: Center(child: CircularProgressIndicator())),
        if (!rankingMode && nextToken != null && !loading)
          OutlinedButton.icon(onPressed: loadingMore ? null : more,
            icon: loadingMore ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.expand_more_rounded),
            label: Text(loadingMore ? 'Carregando…' : 'Carregar mais vozes')),
      ]),
    ));
  }
}
