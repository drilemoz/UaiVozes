import 'dart:convert';

class TextDraft {
  const TextDraft({required this.id, required this.title, required this.content, required this.savedAt});
  final String id;
  final String title;
  final String content;
  final DateTime savedAt;
  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'content': content, 'savedAt': savedAt.toIso8601String(),
  };
  factory TextDraft.fromJson(Map<String, dynamic> value) => TextDraft(
    id: value['id'] is String ? value['id'] as String : '',
    title: value['title'] is String ? value['title'] as String : '',
    content: value['content'] is String ? value['content'] as String : '',
    savedAt: DateTime.tryParse(value['savedAt'] is String ? value['savedAt'] as String : '') ?? DateTime(2000),
  );
}

class TextDrafts {
  static const maxSaved = 20;
  static const maxCharacters = 50000;
  static List<TextDraft> decode(String? source) {
    try {
      final value = jsonDecode(source ?? '[]');
      if (value is! List) return [];
      return value.whereType<Map>().map((v) => TextDraft.fromJson(Map<String, dynamic>.from(v)))
          .where((v) => v.id.isNotEmpty && v.title.isNotEmpty && v.content.trim().isNotEmpty &&
              v.content.runes.length <= maxCharacters)
          .take(maxSaved).toList();
    } catch (_) { return []; }
  }
  static String encode(List<TextDraft> values) => jsonEncode(values.take(maxSaved).map((e) => e.toJson()).toList());
  static List<String> split(String content, {int limit = 5000}) {
    if (limit < 1) throw ArgumentError.value(limit, 'limit');
    var remaining = content.trim();
    final parts = <String>[];
    while (remaining.isNotEmpty) {
      final runes = remaining.runes.toList();
      if (runes.length <= limit) { parts.add(remaining); break; }
      var end = limit;
      // Preferir espaço ou quebra de linha no terço final de cada parte.
      for (var i = limit - 1; i >= (limit * 2 ~/ 3); i--) {
        if (runes[i] == 32 || runes[i] == 10) { end = i + 1; break; }
      }
      parts.add(String.fromCharCodes(runes.take(end)).trimRight());
      remaining = String.fromCharCodes(runes.skip(end)).trimLeft();
    }
    return parts;
  }
}
