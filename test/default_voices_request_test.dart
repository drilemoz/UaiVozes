import 'package:flutter_test/flutter_test.dart';
import 'package:uaivozes/src/app_model.dart';

void main() {
  test('pedido de vozes padrão incrementa contador e notifica sem gerar áudio', () {
    final model = AppModel();
    var notified = 0;
    model.addListener(() => notified++);
    final before = model.defaultVoicesRequest;
    model.requestDefaultVoices();
    expect(model.defaultVoicesRequest, before + 1);
    expect(notified, 1);
    expect(model.generationInProgress, isFalse);
    model.dispose();
  });
}
