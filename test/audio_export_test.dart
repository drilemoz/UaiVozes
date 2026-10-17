import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uaivozes/src/audio_export.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('nome do arquivo remove caracteres reservados e garante .mp3', () {
    expect(AudioExport.fileName('Meu áudio'), 'Meu áudio.mp3');
    expect(AudioExport.fileName('a/b\\c:d*e?f"g<h>i|j'), 'a_b_c_d_e_f_g_h_i_j.mp3');
    expect(AudioExport.fileName('já tem.MP3'), 'já tem.mp3');
    expect(AudioExport.fileName('  ..  '), 'Uai-Vozes-audio.mp3');
    expect(AudioExport.fileName(''), 'Uai-Vozes-audio.mp3');
  });

  test('nome muito longo é limitado', () {
    final name = AudioExport.fileName(List.filled(300, 'x').join());
    expect(name.length, AudioExport.maxNameLength + 4);
    expect(name.endsWith('.mp3'), isTrue);
  });

  test('caminho vazio é recusado antes de abrir o seletor', () async {
    await expectLater(AudioExport.saveMp3('  ', 'x'), throwsA(isA<FormatException>()));
  });

  test('Salvar MP3 usa apenas o seletor nativo e informa cancelamento', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AudioExport.channel, (call) async {
      calls.add(call);
      return calls.length == 1 ? true : null;
    });
    try {
      expect(await AudioExport.saveMp3('/data/user/0/app/files/audio.mp3', 'Minha gravação'), isTrue);
      expect(await AudioExport.saveMp3('/data/user/0/app/files/audio.mp3', 'Outra'), isFalse);
      expect(calls.map((c) => c.method).toList(), ['exportAudio', 'exportAudio']);
      expect((calls.first.arguments as Map)['name'], 'Minha gravação.mp3');
      expect((calls.first.arguments as Map)['path'], '/data/user/0/app/files/audio.mp3');
    } finally {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(AudioExport.channel, null);
    }
  });

}
