import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'eleven_api.dart';
import 'diagnostics.dart';
import 'models.dart';

class AppModel extends ChangeNotifier {
  static const version = '0.1.0-alpha.5';
  static const versionCode = 5;
  static const pix = 'drilemoz@gmail.com';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  late final ElevenApi api = ElevenApi(readKey);

  SharedPreferences? _prefs;
  String key = '';
  ThemeMode themeMode = ThemeMode.system;
  String language = 'pt';
  String draft = '';
  String lastSeenVersion = '';
  bool confirmCreditsBeforeGenerate = true;
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
  final List<AudioRecord> library = [];
  final Set<String> favoriteIds = {};

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
    lastSeenVersion = _prefs?.getString('seen_version') ?? '';
    confirmCreditsBeforeGenerate = _prefs?.getBool('confirm_credits') ?? true;
    localUsageMonth = _prefs?.getString('local_usage_month') ?? '';
    localGeneratedCharacters = _prefs?.getInt('local_usage_characters') ?? 0;
    localTrackingSince = DateTime.tryParse(_prefs?.getString('local_usage_start') ?? '');
    if (localUsageMonth != _monthKey(DateTime.now())) {
      await _resetLocalUsage();
    }
    favoriteIds.addAll(_prefs?.getStringList('favorites') ?? []);
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
    library.addAll(decodeAudioRecords(_prefs?.getString('library') ?? '[]'));
    // Arquivos podem ser apagados pelo Android/usuário.
    library.removeWhere((e) => !File(e.path).existsSync());
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
    if (changed) await _resetLocalUsage();
    subscription = null;
    account = null;
    usageUpdatedAt = null;
    usageError = null;
    accountError = null;
    notifyListeners();
  }

  Future<Subscription> testKey() async {
    final result = await api.checkSubscription();
    subscription = result;
    usageUpdatedAt = DateTime.now();
    usageError = null;
    notifyListeners();
    return result;
  }

  /// Atualização sob demanda ou na entrada do app. Não cobra créditos por gerar
  /// áudio e não faz tentativas automáticas em caso de falha.
  Future<void> refreshUsage() async {
    if (refreshingUsage || key.isEmpty) return;
    refreshingUsage = true;
    usageError = null;
    notifyListeners();
    try {
      await testKey();
    } catch (error, stack) {
      AppDiagnostics.instance.capture('CONTA_CONSUMO', error, stack);
      usageError = friendlyError(error);
    } finally {
      refreshingUsage = false;
      notifyListeners();
    }
  }

  /// Mantém dados básicos opcionais separados da assinatura: chaves sem
  /// permissão User: Read ainda conseguem ver o consumo, se autorizadas.
  Future<void> refreshAccount() async {
    if (refreshingAccount || key.isEmpty) return;
    refreshingAccount = true;
    accountError = null;
    notifyListeners();
    try {
      account = await api.getAccount();
      if (account!.subscription != null) {
        subscription = account!.subscription;
        usageUpdatedAt = DateTime.now();
        usageError = null;
      }
    } catch (error, stack) {
      AppDiagnostics.instance.capture('CONTA_USUARIO', error, stack);
      accountError = friendlyError(error);
    }
    // Mesmo com escopo User: Read restrito, tenta atualizar a assinatura.
    await refreshUsage();
    refreshingAccount = false;
    notifyListeners();
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
  Future<void> recordGeneratedCharacters(String generatedText) async {
    if (localUsageMonth != _monthKey(DateTime.now())) await _resetLocalUsage();
    localGeneratedCharacters += generatedText.trim().runes.length;
    try {
      await _prefs?.setInt('local_usage_characters', localGeneratedCharacters);
    } catch (error, stack) {
      AppDiagnostics.instance.capture('CONSUMO_LOCAL_SALVAR', error, stack);
      // A falha desta estimativa não deve impedir salvar um áudio pago.
    }
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

  Future<void> setDraft(String value) async {
    draft = value;
    await _prefs?.setString('draft', value);
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

  Future<AudioRecord> saveAudio(Uint8List audio, String text, Voice voice) async {
    final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/audios');
    await dir.create(recursive: true);
    final now = DateTime.now();
    final id = now.microsecondsSinceEpoch.toString();
    final path = '${dir.path}/uaivozes_$id.mp3';
    await File(path).writeAsBytes(audio, flush: true);
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
    library.insert(0, item);
    await _persistLibrary();
    notifyListeners();
    return item;
  }

  Future<void> renameAudio(AudioRecord audio, String newName) async {
    final index = library.indexWhere((e) => e.id == audio.id);
    if (index == -1 || newName.trim().isEmpty) return;
    library[index] = library[index].withName(newName.trim());
    await _persistLibrary();
    notifyListeners();
  }

  Future<void> deleteAudio(AudioRecord audio) async {
    final file = File(audio.path);
    if (await file.exists()) await file.delete();
    library.removeWhere((e) => e.id == audio.id);
    await _persistLibrary();
    notifyListeners();
  }

  Future<void> _persistLibrary() async {
    await _prefs?.setString('library', jsonEncode(library.map((e) => e.toJson()).toList()));
  }

  @override
  void dispose() {
    api.dispose();
    super.dispose();
  }
}
