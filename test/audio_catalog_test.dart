import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:uaivozes/src/audio_catalog.dart';
import 'package:uaivozes/src/models.dart';

AudioRecord sample(Directory folder, String id) => AudioRecord(
  id: id,
  name: 'Teste $id',
  path: '${folder.path}/uaivozes_$id.mp3',
  voiceName: 'Voz',
  voiceId: 'voice_1',
  text: 'Texto para testar gravação.',
  createdAt: DateTime.utc(2026, 10, 16),
);

void main() {
  late Directory root;
  late AudioCatalog store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('uaivozes_catalog_');
    store = AudioCatalog(Directory('${root.path}/audios'));
  });
  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('migra biblioteca legada sem apagar arquivo ou preferência original', () async {
    await store.directory.create(recursive: true);
    final item = sample(store.directory, 'old');
    await File(item.path).writeAsBytes([1, 2, 3]);
    final oldIndex = jsonEncode([item.toJson()]);
    final migrated = await store.load(legacyJson: oldIndex);
    expect(migrated.single.id, 'old');
    expect(await store.index.exists(), isTrue);
    expect(await File(item.path).exists(), isTrue);
    expect(oldIndex, contains('Texto para testar')); // O chamador conserva o legado.
    final nextLoad = await store.load(legacyJson: '[]');
    expect(nextLoad.single.id, 'old');
  });

  test('salvamento persiste MP3 e índice antes de disponibilizar item', () async {
    final item = sample(store.directory, '001');
    await store.save(Uint8List.fromList([0x49, 0x44, 0x33, 1]), item, []);
    final loaded = await store.load();
    expect(loaded.single.id, item.id);
    expect(await File(item.path).readAsBytes(), [0x49, 0x44, 0x33, 1]);
    expect(await File('${item.path}.pending.json').exists(), isFalse);
  });

  test('journal permite recuperar MP3 após encerramento entre áudio e índice', () async {
    await store.directory.create(recursive: true);
    final item = sample(store.directory, 'recuperar');
    await File(item.path).writeAsBytes([4, 5, 6]);
    await File('${item.path}.pending.json').writeAsString(jsonEncode(item.toJson()));
    final restored = await store.load();
    expect(restored.single.id, item.id);
    expect(await store.index.exists(), isTrue);
    expect(await File('${item.path}.pending.json').exists(), isFalse);
  });

  test('índice corrompido usa backup íntegro', () async {
    final a = sample(store.directory, 'a');
    final b = sample(store.directory, 'b');
    await store.directory.create(recursive: true);
    await File(a.path).writeAsBytes([1]);
    await File(b.path).writeAsBytes([1]);
    await store.persist([a]);
    await store.persist([a, b]); // Backup espelha o índice mais recente.
    await store.index.writeAsString('{arquivo danificado');
    final recovered = await store.load();
    expect(recovered.map((e) => e.id), ['a', 'b']);
    expect(await File(a.path).exists(), isTrue);
  });

  test('remoção mantém arquivo recuperável se interrompida antes do índice', () async {
    final item = sample(store.directory, 'delete');
    await store.save(Uint8List.fromList([1, 2]), item, []);
    await File(item.path).rename('${item.path}.deleting');
    final restored = await store.load();
    expect(restored.single.id, 'delete');
    expect(await File(item.path).exists(), isTrue);
  });

  test('remoção concluída não deixa registro nem MP3', () async {
    final item = sample(store.directory, 'delete');
    await store.save(Uint8List.fromList([1, 2]), item, []);
    await store.delete(item, []);
    expect(await store.load(), isEmpty);
    expect(await File(item.path).exists(), isFalse);
  });

  test('não aceita caminhos de áudio fora do diretório gerenciado', () async {
    final item = AudioRecord(id: 'bad', name: 'Teste',
      path: '${root.path}/fora.mp3', voiceName: 'Voz',
      voiceId: 'x', text: 'X', createdAt: DateTime.now());
    expect(() => store.save(Uint8List.fromList([1]), item, []),
      throwsA(isA<FileSystemException>()));
  });
}
