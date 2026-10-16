import 'eleven_api.dart';

/// Cache efêmero apenas de metadados de vozes durante esta sessão.
/// Sem chaves API, áudios, textos do usuário ou persistência em disco.
class VoiceBrowseCache {
  VoiceBrowseCache({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;
  final DateTime Function() _clock;
  static const ttl = Duration(minutes: 3);
  static const maxPages = 10;
  final Map<String, _Snapshot> _pages = {};

  VoicePage? get(String key) {
    final value = _pages.remove(key);
    if (value == null || _clock().difference(value.created) >= ttl) return null;
    _pages[key] = value; // LRU: entradas antigas saem primeiro.
    return value.page;
  }

  void put(String key, VoicePage page) {
    _pages.remove(key);
    _pages[key] = _Snapshot(page, _clock());
    while (_pages.length > maxPages) {
      _pages.remove(_pages.keys.first);
    }
  }

  void clear() => _pages.clear();
  int get count => _pages.length;
}

class _Snapshot {
  const _Snapshot(this.page, this.created);
  final VoicePage page;
  final DateTime created;
}

/// Entrada somente de filtros aceitos pela API; token evita misturar páginas.
String voiceBrowseKey({
  required String language,
  required bool ranking,
  String search = '',
  String category = 'all',
  String style = 'all',
  String gender = 'all',
  String age = 'all',
  String accent = 'all',
  String sharedCategory = 'all',
  String voiceType = 'all',
  String? token,
}) => [language, ranking ? 'top' : 'minhas', search.trim().toLowerCase(),
      category, style, gender, age, accent, sharedCategory, voiceType, token ?? ''].join('\u001f');
