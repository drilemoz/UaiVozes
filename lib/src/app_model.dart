import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'eleven_api.dart';
import 'audio_catalog.dart';
import 'credit_ledger.dart';
import 'text_drafts.dart';
import 'diagnostics.dart';
import 'models.dart';

class AppModel extends ChangeNotifier {
  static const version = '0.1.0-alpha.25';
  static const versionCode = 25;
  static const pix = 'drilemoz@gmail.com';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  late final ElevenApi api = ElevenApi(readKey);

  SharedPreferences? _prefs;
  AudioCatalog? _catalog;
  bool get canSaveAudio => _catalog != null;
  bool _generationInProgress = false;
  bool get generationInProgress => _generationInProgress;

  /// Pedido para a aba Vozes listar as vozes padrão da conta (sem TTS).
  int defaultVoicesRequest = 0;
  void requestDefaultVoices() {
    defaultVoicesRequest++;
    notifyListeners();
  }

  /// Trava no modelo, não na tela: evita dupla chamada TTS mesmo após reconstruir UI.
  bool tryBeginGeneration() {
    if (_generationInProgress) return false;
    _generationInProgress = true;
    notifyListeners();
    return true;
  }

  void finishGeneration() {
    if (!_generationInProgress) return;
    _generationInProgress = false;
    notifyListeners();
  }

  String key = '';
  ThemeMode themeMode = ThemeMode.system;
  String language = 'pt';
  String draft = '';
  final List<TextDraft> namedDrafts = [];
  String lastSeenVersion = '';
  bool confirmCreditsBeforeGenerate = true;
  bool creditAlertsEnabled = true;
  Voice? selectedVoice;
  Subscription? subscription;
  ElevenAccount? account;
  DateTime? usageUpdatedAt;
  bool refreshingUsage = false;
  bool refreshingAccount = false;
  String? usageError;
  String? accountError;
  int localGeneratedCharacters = 0;
  DateTime? localTrackingSince;
  String localUsageMonth = '';
  CreditLedger creditLedger = CreditLedger();
  int _accountRevision = 0;
  int get creditWarningThreshold => creditAlertsEnabled && usageError == null
      ? CreditWarning.percentThreshold(subscription?.used, subscription?.limit) ?? 0 : 0;
  final List<AudioRecord> library = [];
  final Set<String> favoriteIds = {};
  /// Vozes que já devolveram áudio válido NESTA conta (chave). Não é garantia
  /// futura: saldo, modelo ou plano podem mudar. Limpo ao trocar a chave.
  final Set<String> workedVoiceIds = {};
  static const _maxWorkedVoices = 200;
  /// Modelo de TTS escolhido no Estúdio; sempre um ID conhecido.
  String ttsModel = CreditEstimator.defaultModel;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    try {
      key = await _storage.read(key: 'elevenlabs_api_key') ?? '';
    } catch (e, stack) {
      AppDiagnostics.instance.capture('ARMAZENAMENTO_API', e, stack);
      key = '';
    }
    themeMode = switch (_prefs?.getString('theme')) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    language = _prefs?.getString('language') ?? 'pt';
    draft = _prefs?.getString('draft') ?? '';
    namedDrafts.addAll(TextDrafts.decode(_prefs?.getString('named_text_drafts_v1')));
    lastSeenVersion = _prefs?.getString('seen_version') ?? '';
    confirmCreditsBeforeGenerate = _prefs?.getBool('confirm_credits') ?? true;
    creditAlertsEnabled = _prefs?.getBool('credit_alerts_enabled') ?? true;
    creditLedger = CreditLedger.fromJson(_prefs?.getString('credit_ledger_v1'));
    localUsageMonth = _prefs?.getString('local_usage_month') ?? '';
    localGeneratedCharacters = _prefs?.getInt('local_usage_characters') ?? 0;
    localTrackingSince = DateTime.tryParse(_prefs?.getString('local_usage_start') ?? '');
    if (localUsageMonth != _monthKey(DateTime.now())) {
      await _resetLocalUsage();
    }
    favoriteIds.addAll(_prefs?.getStringList('favorites') ?? []);
    workedVoiceIds.addAll(_prefs?.getStringList('worked_voices') ?? []);
    final savedModel = _prefs?.getString('tts_model');
    if (CreditEstimator.isKnownModel(savedModel)) ttsModel = savedModel!;
    try {
      final rawVoice = _prefs?.getString('selected_voice');
      if (rawVoice != null) {
        final json = jsonDecode(rawVoice) as Map<String, dynamic>;
        final voice = Voice.fromJson(json);
        if (voice.id.isNotEmpty) selectedVoice = voice;
      }
    } catch (e, stack) {
      AppDiagnostics.instance.capture('PREFERENCIAS_VOZ', e, stack);
      selectedVoice = null;
    }
    // Migração sem apagar a preferência legada: a v0.05 armazenava toda a
    // biblioteca em SharedPreferences. Índice JSON agora possui backup e journal.
    try {
      final root = await getApplicationDocumentsDirectory();
      _catalog = AudioCatalog(Directory('${root.path}/audios'));
      library.addAll(await _catalog!.load(
        legacyJson: _prefs?.getString('library') ?? '[]'));
    } catch (error, stack) {
      AppDiagnostics.instance.capture('BIBLIOTECA_CARREGAR', error, stack);
      // Falhas de I/O não devem apagar o catálogo antigo nem fechar o app.
      library.addAll(decodeAudioRecords(_prefs?.getString('library') ?? '[]'));
      _catalog = null; // Impede alterações até que o armazenamento volte.
    }
    notifyListeners();
  }

  Future<String> readKey() async => key;

  Future<void> setKey(String value) async {
    final clean = value.trim();
    if (clean.isEmpty) {
      await _storage.delete(key: 'elevenlabs_api_key');
    } else {
      await _storage.write(key: 'elevenlabs_api_key', value: clean);
    }
    final changed = clean != key;
    key = clean;
    if (changed) {
      _accountRevision++;
      refreshingUsage = false;
      refreshingAccount = false;
      creditLedger = CreditLedger();
      await _prefs?.remove('credit_ledger_v1');
      workedVoiceIds.clear();
      await _prefs?.remove('worked_voices');
      await _resetLocalUsage();
    }
    subscription = null;
    account = null;
    usageUpdatedAt = null;
    usageError = null;
    accountError = null;
    notifyListeners();
  }

  Future<Subscription> testKey() async {
    final value = key;
    final revision = _accountRevision;
    final result = await api.checkCandidateKey(value);
    if (revision == _accountRevision && key == value) {
      subscription = result;
      usageUpdatedAt = DateTime.now();
      usageError = null;
      notifyListeners();
    }
    return result;
  }

  /// Só aplica dados da conta se a chave ainda for a mesma. Uma resposta da
  /// conta anterior não pode aparecer após uma troca de credencial.
  Future<void> refreshUsage() async {
    if (refreshingUsage || key.isEmpty) return;
    final activeRevision = _accountRevision;
    final activeKey = key;
    refreshingUsage = true;
    usageError = null;
    notifyListeners();
    try {
      final result = await api.checkCandidateKey(activeKey);
      if (activeRevision == _accountRevision) {
        subscription = result;
        usageUpdatedAt = DateTime.now();
        usageError = null;
      }
    } catch (error, stack) {
      AppDiagnostics.instance.capture('CONTA_CONSUMO', error, stack);
      if (activeRevision == _accountRevision) usageError = friendlyError(error);
    } finally {
      if (activeRevision == _accountRevision) {
        refreshingUsage = false;
        notifyListeners();
      }
    }
  }

  Future<void> refreshAccount() async {
    if (refreshingAccount || key.isEmpty) return;
    final activeRevision = _accountRevision;
    refreshingAccount = true;
    accountError = null;
    notifyListeners();
    try {
      final result = await api.getAccount();
      if (activeRevision == _accountRevision) {
        account = result;
        if (result.subscription != null) {
          subscription = result.subscription;
          usageUpdatedAt = DateTime.now();
          usageError = null;
        }
      }
    } catch (error, stack) {
      AppDiagnostics.instance.capture('CONTA_USUARIO', error, stack);
      if (activeRevision == _accountRevision) accountError = friendlyError(error);
    } finally {
      if (activeRevision == _accountRevision) {
        await refreshUsage();
        refreshingAccount = false;
        notifyListeners();
      }
    }
  }

  static String _monthKey(DateTime at) =>
      '${at.year}-${at.month.toString().padLeft(2, '0')}';

  Future<void> _resetLocalUsage() async {
    localUsageMonth = _monthKey(DateTime.now());
    localGeneratedCharacters = 0;
    localTrackingSince = DateTime.now();
    await _prefs?.setString('local_usage_month', localUsageMonth);
    await _prefs?.setInt('local_usage_characters', 0);
    await _prefs?.setString('local_usage_start', localTrackingSince!.toIso8601String());
    notifyListeners();
  }

  /// Contagem estimativa local: apenas textos enviados por este app desde o
  /// início do acompanhamento, nunca valor faturado em créditos reais.
  Future<void> recordGeneratedCharacters(String generatedText, {
    String modelId = CreditEstimator.defaultModel,
  }) async {
    if (localUsageMonth != _monthKey(DateTime.now())) await _resetLocalUsage();
    final now = DateTime.now();
    final count = CreditEstimator.characterCount(generatedText);
    if (count <= 0) return;
    localGeneratedCharacters += count;
    creditLedger.add(CreditEvent(
      id: now.microsecondsSinceEpoch.toString(), createdAt: now,
      characters: count, model: modelId,
      baseEstimate: CreditEstimator.baseEstimate(count, model: modelId),
    ));
    try {
      await _prefs?.setInt('local_usage_characters', localGeneratedCharacters);
      await _prefs?.setString('credit_ledger_v1', creditLedger.encode());
    } catch (error, stack) {
      AppDiagnostics.instance.capture('CONSUMO_LOCAL_SALVAR', error, stack);
      // Histórico local é auxiliar e não deve bloquear o áudio pago.
    }
    notifyListeners();
  }

  Future<void> setCreditAlerts(bool value) async {
    creditAlertsEnabled = value;
    await _prefs?.setBool('credit_alerts_enabled', value);
    notifyListeners();
  }

  Future<void> setConfirmCredits(bool value) async {
    confirmCreditsBeforeGenerate = value;
    await _prefs?.setBool('confirm_credits', value);
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode next) async {
    themeMode = next;
    final id = switch (next) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs?.setString('theme', id);
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    language = code;
    await _prefs?.setString('language', code);
    notifyListeners();
  }

  void pickVoice(Voice voice) {
    selectedVoice = voice;
    _prefs?.setString('selected_voice', jsonEncode(voice.toJson()));
    notifyListeners();
  }

  /// Remoção explícita de voz na API; não apaga áudios já gerados.
  Future<void> voiceRemovedFromAccount(String voiceId) async {
    if (selectedVoice?.id == voiceId) {
      selectedVoice = null;
      await _prefs?.remove('selected_voice');
    }
    if (favoriteIds.remove(voiceId)) {
      await _prefs?.setStringList('favorites', favoriteIds.toList());
    }
    if (workedVoiceIds.remove(voiceId)) {
      await _prefs?.setStringList('worked_voices', workedVoiceIds.toList());
    }
    notifyListeners();
  }

  Future<void> setTtsModel(String id) async {
    if (!CreditEstimator.isKnownModel(id) || id == ttsModel) return;
    ttsModel = id;
    await _prefs?.setString('tts_model', id);
    notifyListeners();
  }

  /// Chamado só depois que a API devolveu um MP3 válido. Não consulta a API.
  Future<void> markVoiceWorked(String voiceId) async {
    final id = voiceId.trim();
    if (id.isEmpty || workedVoiceIds.contains(id)) return;
    if (workedVoiceIds.length >= _maxWorkedVoices) {
      workedVoiceIds.remove(workedVoiceIds.first);
    }
    workedVoiceIds.add(id);
    await _prefs?.setStringList('worked_voices', workedVoiceIds.toList());
    notifyListeners();
  }

  Future<void> setDraft(String value) async {
    draft = value;
    await _prefs?.setString('draft', value);
  }

  Future<void> saveNamedDraft(String title, String content) async {
    if (title.trim().isEmpty || content.trim().isEmpty ||
        content.runes.length > TextDrafts.maxCharacters) {
      throw const FormatException('Título ou texto inválido (limite de 50.000 caracteres).');
    }
    final now = DateTime.now();
    final item = TextDraft(id: now.microsecondsSinceEpoch.toString(),
      title: title.trim(), content: content, savedAt: now);
    final updated = [item, ...namedDrafts].take(TextDrafts.maxSaved).toList();
    await _prefs?.setString('named_text_drafts_v1', TextDrafts.encode(updated));
    namedDrafts..clear()..addAll(updated);
    notifyListeners();
  }

  Future<void> deleteNamedDraft(String id) async {
    final updated = namedDrafts.where((e) => e.id != id).toList();
    await _prefs?.setString('named_text_drafts_v1', TextDrafts.encode(updated));
    namedDrafts..clear()..addAll(updated);
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    if (!favoriteIds.add(id)) favoriteIds.remove(id);
    await _prefs?.setStringList('favorites', favoriteIds.toList());
    notifyListeners();
  }

  Future<void> markChangelogSeen() async {
    lastSeenVersion = version;
    await _prefs?.setString('seen_version', version);
    notifyListeners();
  }

  Future<AudioCatalog> _requireCatalog() async {
    final active = _catalog;
    if (active != null) return active;
    throw const FileSystemException(
      'Biblioteca indisponível. Reinicie o app e consulte o diagnóstico.');
  }

  Future<AudioRecord> saveAudio(Uint8List audio, String text, Voice voice) async {
    final catalog = await _requireCatalog();
    final now = DateTime.now();
    final id = now.microsecondsSinceEpoch.toString();
    final path = '${catalog.directory.path}/uaivozes_$id.mp3';
    final title = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final item = AudioRecord(
      id: id,
      name: title.length > 45 ? '${title.substring(0, 45)}…' : title,
      path: path,
      voiceName: voice.name,
      voiceId: voice.id,
      text: text,
      createdAt: now,
    );
    await catalog.save(audio, item, library);
    library.insert(0, item);
    notifyListeners();
    return item;
  }

  Future<void> renameAudio(AudioRecord audio, String newName) async {
    final index = library.indexWhere((e) => e.id == audio.id);
    if (index == -1 || newName.trim().isEmpty) return;
    final updated = [...library];
    updated[index] = updated[index].withName(newName.trim());
    await (await _requireCatalog()).persist(updated);
    library[index] = updated[index];
    notifyListeners();
  }

  Future<void> deleteAudio(AudioRecord audio) async {
    if (!library.any((e) => e.id == audio.id)) return;
    final remaining = library.where((e) => e.id != audio.id).toList();
    await (await _requireCatalog()).delete(audio, remaining);
    library.removeWhere((e) => e.id == audio.id);
    notifyListeners();
  }

  @override
  void dispose() {
    api.dispose();
    super.dispose();
  }
}
