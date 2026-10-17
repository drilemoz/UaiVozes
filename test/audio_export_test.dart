import 'package:flutter_test/flutter_test.dart';
import 'package:uaivozes/src/audio_export.dart';

void main() {
  test('nome do arquivo remove caracteres reservados e garante .mp3', () {
    expect(AudioExport.fileName('Meu áudio'), 'Meu áudio.mp3');
    expect(AudioExport.fileName('a/b\\c:d*e?f"g<h>i|j'), 'a_b_c_d_e_f_g_h_i_j.mp3');
    expect(AudioExport.fileName('já tem.MP3'), 'já tem.mp3');
    expect(AudioExport.fileName('  ..  '), 'Uai-Vozes-audio.mp3');
    expect(AudioExport.fileName(''), 'Uai-Vozes-audio.mp3');
  });

  test('nome muito longo é limitado', () {
    final name = AudioExport.fileName('x' * 300);
    expect(name.length, AudioExport.maxNameLength + 4);
    expect(name.endsWith('.mp3'), isTrue);
  });

  test('caminho vazio é recusado antes de abrir o seletor', () async {
    await expectLater(AudioExport.saveMp3('  ', 'x'), throwsA(isA<FormatException>()));
  });
}
