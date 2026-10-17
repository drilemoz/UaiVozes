import 'package:flutter_test/flutter_test.dart';
import 'package:uaivozes/src/app_model.dart';

void main() {
  test('voz que gerou áudio é registrada uma vez e notifica', () async {
    final model = AppModel();
    var notified = 0;
    model.addListener(() => notified++);
    await model.markVoiceWorked('voz1');
    await model.markVoiceWorked('voz1');
    await model.markVoiceWorked('  ');
    expect(model.workedVoiceIds, {'voz1'});
    expect(notified, 1);
    model.dispose();
  });

  test('remover voz da conta apaga o registro de voz validada', () async {
    final model = AppModel();
    await model.markVoiceWorked('voz2');
    await model.voiceRemovedFromAccount('voz2');
    expect(model.workedVoiceIds, isEmpty);
    model.dispose();
  });
}
