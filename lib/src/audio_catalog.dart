import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'models.dart';

/// Índice local de áudios: escrita atômica, cópia de recuperação e migração
/// da antiga preferência `library` (v0.05 e anteriores).
/// Não usa rede, não inclui a chave API e não elimina o backup antigo.
class AudioCatalog {
  AudioCatalog(this.directory);

  final Directory directory;

  File get index => File('${directory.path}/catalog.json');
  File get backup => File('${directory.path}/catalog.json.bak');

  bool _inside(String path) {
    final root = directory.absolute.path;
    return File(path).absolute.path.startsWith('$root${Platform.pathSeparator}');
  }

  List<AudioRecord> _decode(String contents) {
    final data = jsonDecode(contents);
    if (data is! List) throw const FormatException('Catálogo não é uma lista.');
    return data.map((e) {
      if (e is! Map) throw const FormatException('Registro inválido.');
      return AudioRecord.fromJson(Map<String, dynamic>.from(e));
    }).where((r) => r.id.isNotEmpty && r.path.isNotEmpty && _inside(r.path)).toList();
  }

  Future<List<AudioRecord>> load({String legacyJson = '[]'}) async {
    await directory.create(recursive: true);
    List<AudioRecord> records;
    if (await index.exists()) {
      try {
        records = _decode(await index.readAsString());
      } catch (_) {
        if (!await backup.exists()) rethrow;
        records = _decode(await backup.readAsString());
        // Conservar o backup íntegro até a próxima gravação bem-sucedida.
        await persist(records);
      }
    } else if (await backup.exists()) {
      records = _decode(await backup.readAsString());
      await persist(records);
    } else {
      records = _decode(legacyJson);
      if (records.isNotEmpty) await persist(records);
    }

    // Recupera áudios cujo MP3 foi gravado mas o processo foi encerrado
    // antes de confirmar o índice. Um journal por geração evita perda.
    final recovered = <AudioRecord>[];
    await for (final file in directory.list(followLinks: false)) {
      if (file is! File || !file.path.endsWith('.pending.json')) continue;
      try {
        final entry = AudioRecord.fromJson(
          Map<String, dynamic>.from(jsonDecode(await file.readAsString()) as Map));
        if (!_inside(entry.path)) continue;
        if (await File(entry.path).exists() &&
            !records.any((item) => item.id == entry.id)) {
          recovered.add(entry);
        }
      } catch (_) {
        // Um journal truncado não substitui o catálogo principal.
      }
    }
    if (recovered.isNotEmpty) {
      records = [...recovered, ...records];
      await persist(records);
    }
    // Limpeza de journals já incorporados; jamais apagar áudio aqui.
    await for (final file in directory.list(followLinks: false)) {
      if (file is File && file.path.endsWith('.pending.json')) {
        try {
          final entry = AudioRecord.fromJson(Map<String, dynamic>.from(
            jsonDecode(await file.readAsString()) as Map));
          if (records.any((item) => item.id == entry.id)) await file.delete();
        } catch (_) {}
      }
    }
    final available = <AudioRecord>[];
    for (final item in records) {
      final audio = File(item.path);
      if (await audio.exists()) {
        available.add(item);
      } else {
        final staged = File('${item.path}.deleting');
        if (await staged.exists()) {
          await staged.rename(item.path); // Remoção interrompida, item ainda indexado.
          available.add(item);
        }
      }
    }
    // Se o Android removeu algum arquivo fora do aplicativo, corrigir a lista.
    if (available.length != records.length) await persist(available);
    return available;
  }

  Future<void> persist(List<AudioRecord> records) async {
    await directory.create(recursive: true);
    final temp = File('${index.path}.tmp');
    await temp.writeAsString(jsonEncode(records.map((e) => e.toJson()).toList()), flush: true);
    try {
      if (await index.exists()) {
        // Nunca substituir a última cópia válida por índice corrompido.
        try {
          _decode(await index.readAsString());
          await index.copy(backup.path);
        } catch (_) {}
      }
      await temp.rename(index.path);
      // Espelho íntegro da versão mais recente; falha do backup não invalida
      // um catálogo principal já confirmado no disco.
      final backupTemp = File('${backup.path}.tmp');
      try {
        await index.copy(backupTemp.path);
        await backupTemp.rename(backup.path);
      } catch (_) {
        // Não falhar a operação depois do índice principal salvo.
      } finally {
        if (await backupTemp.exists()) await backupTemp.delete();
      }
    } finally {
      if (await temp.exists()) await temp.delete();
    }
  }

  Future<void> save(Uint8List bytes, AudioRecord record, List<AudioRecord> current) async {
    if (bytes.isEmpty || !_inside(record.path)) {
      throw const FileSystemException('Áudio vazio ou caminho inválido.');
    }
    await directory.create(recursive: true);
    final target = File(record.path);
    if (await target.exists()) throw const FileSystemException('Áudio já existe.');
    final temp = File('${record.path}.tmp');
    final journal = File('${record.path}.pending.json');
    try {
      await temp.writeAsBytes(bytes, flush: true);
      await journal.writeAsString(jsonEncode(record.toJson()), flush: true);
      await temp.rename(target.path);
      await persist([record, ...current]);
      try { await journal.delete(); } catch (_) {}
    } finally {
      if (await temp.exists()) await temp.delete();
      // Se o índice falhou após gravar o áudio, preservar MP3 e journal.
      if (!await target.exists() && await journal.exists()) await journal.delete();
    }
  }

  Future<void> delete(AudioRecord record, List<AudioRecord> remaining) async {
    if (!_inside(record.path)) throw const FileSystemException('Caminho inválido.');
    final target = File(record.path);
    final staged = File('${record.path}.deleting');
    final existed = await target.exists();
    if (existed) await target.rename(staged.path);
    try {
      await persist(remaining);
    } catch (_) {
      if (existed && await staged.exists()) await staged.rename(target.path);
      rethrow;
    }
    // O registro já foi removido do índice. Erro na limpeza não desfaz a operação.
    if (await staged.exists()) {
      try { await staged.delete(); } catch (_) {}
    }
  }
}
