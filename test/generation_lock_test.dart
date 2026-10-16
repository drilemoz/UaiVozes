import 'package:flutter_test/flutter_test.dart';
import 'package:uaivozes/src/app_model.dart';

void main() {
  test('trava global impede segunda geração até liberação explícita', () {
    final model = AppModel();
    expect(model.tryBeginGeneration(), isTrue);
    expect(model.generationInProgress, isTrue);
    expect(model.tryBeginGeneration(), isFalse);
    model.finishGeneration();
    expect(model.generationInProgress, isFalse);
    expect(model.tryBeginGeneration(), isTrue);
    model.finishGeneration();
    model.dispose();
  });
}
