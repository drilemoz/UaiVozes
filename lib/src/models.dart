import 'dart:convert';

class Voice {
  const Voice({
    required this.id,
    required this.name,
    this.category = '',
    this.description = '',
    this.previewUrl = '',
    this.language = '',
    this.accent = '',
    this.useCase = '',
    this.gender = '',
    this.style = '',
    this.annualCharacters,
    this.publicOwnerId = '',
  });

  final String id;
  final String name;
  final String category;
  final String description;
  final String previewUrl;
  final String language;
  final String accent;
  final String useCase;
  final String gender;
  final String style;
  final int? annualCharacters;
  final String publicOwnerId;

  static String _str(dynamic v) => v is String ? v : '';

  factory Voice.fromJson(Map<String, dynamic> map) {
    final labels = (map['labels'] is Map)
        ? Map<String, dynamic>.from(map['labels'] as Map)
        : <String, dynamic>{};
    return Voice(
      id: _str(map['voice_id']),
      name: _str(map['name']).isEmpty ? 'Voz sem nome' : _str(map['name']),
      category: _str(map['category']),
      description: _str(map['description']),
      previewUrl: _str(map['preview_url']),
      language: _str(map['language']).isNotEmpty
          ? _str(map['language'])
          : _str(labels['language']),
      accent: _str(map['accent']).isNotEmpty
          ? _str(map['accent'])
          : _str(labels['accent']),
      useCase: _str(map['use_case']).isNotEmpty
          ? _str(map['use_case'])
          : _str(labels['use_case']),
      gender: _str(map['gender']).isNotEmpty
          ? _str(map['gender'])
          : _str(labels['gender']),
      style: _str(map['descriptive']).isNotEmpty
          ? _str(map['descriptive'])
          : _str(labels['description']),
      publicOwnerId: _str(map['public_owner_id']),
      annualCharacters: map['usage_character_count_1y'] is num
          ? (map['usage_character_count_1y'] as num).toInt()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'voice_id': id,
        'name': name,
        'category': category,
        'description': description,
        'preview_url': previewUrl,
        'language': language,
        'accent': accent,
        'use_case': useCase,
        'gender': gender,
        'descriptive': style,
      };

  /// Etiquetas de categorias traduzidas, sem modificar nomes oficiais de vozes.
  static const _labelsPt = <String, String>{
    'narrative_story': 'Narração', 'conversational': 'Conversa',
    'characters_animation': 'Personagem', 'social_media': 'Redes sociais',
    'educational': 'Educacional', 'advertisement': 'Publicidade',
    'calm': 'Calma', 'excited': 'Animada', 'soft': 'Suave',
    'casual': 'Descontraída', 'expressive': 'Expressiva',
    'energetic': 'Enérgica', 'deep': 'Grave', 'brazilian': 'Brasileiro',
    'portuguese': 'Português', 'american': 'Americano',
    'neutral': 'Neutra', 'professional': 'Profissional',
    'young': 'Jovem', 'female': 'Feminina', 'male': 'Masculina',
  };

  static String translateTag(String tag) => _labelsPt[tag.toLowerCase().trim()] ?? tag;

  String get summary {
    final parts = [useCase, style.isNotEmpty ? style : accent]
        .where((s) => s.trim().isNotEmpty)
        .map(translateTag).toList();
    return parts.isEmpty ? (description.isEmpty ? translateTag(category) : description)
        : parts.join(' • ');
  }
}

class AudioRecord {
  const AudioRecord({
    required this.id,
    required this.name,
    required this.path,
    required this.voiceName,
    required this.voiceId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String path;
  final String voiceName;
  final String voiceId;
  final String text;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'path': path,
        'voiceName': voiceName,
        'voiceId': voiceId,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AudioRecord.fromJson(Map<String, dynamic> json) => AudioRecord(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Áudio',
        path: json['path'] as String? ?? '',
        voiceName: json['voiceName'] as String? ?? '',
        voiceId: json['voiceId'] as String? ?? '',
        text: json['text'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  AudioRecord withName(String next) => AudioRecord(
        id: id,
        name: next,
        path: path,
        voiceName: voiceName,
        voiceId: voiceId,
        text: text,
        createdAt: createdAt,
      );
}

List<AudioRecord> decodeAudioRecords(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((e) => AudioRecord.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.path.isNotEmpty)
        .toList();
  } catch (_) {
    return [];
  }
}
