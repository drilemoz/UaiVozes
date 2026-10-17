import 'package:flutter_test/flutter_test.dart';
import 'package:uaivozes/src/app_model.dart';
import 'package:uaivozes/src/credit_ledger.dart';
import 'package:uaivozes/src/generation_failure.dart';
import 'package:uaivozes/src/eleven_api.dart';

void main() {
  test('estimativa do Flash v2.5 é metade, arredondada para cima', () {
    expect(CreditEstimator.baseEstimate(100, model: CreditEstimator.flashModel), 50);
    expect(CreditEstimator.baseEstimate(101, model: CreditEstimator.flashModel), 51);
    expect(CreditEstimator.baseEstimate(0, model: CreditEstimator.flashModel), 0);
    expect(CreditEstimator.baseEstimate(100), 100);
    expect(CreditEstimator.baseEstimate(10, model: 'eleven_turbo_v2_5'), isNull);
  });

  test('só IDs conhecidos são aceitos', () async {
    expect(CreditEstimator.isKnownModel('eleven_flash_v2_5'), isTrue);
    expect(CreditEstimator.isKnownModel('qualquer'), isFalse);
    final model = AppModel();
    await model.setTtsModel('qualquer');
    expect(model.ttsModel, CreditEstimator.defaultModel);
    await model.setTtsModel(CreditEstimator.flashModel);
    expect(model.ttsModel, CreditEstimator.flashModel);
    model.dispose();
  });

  test('erro com modelo alternativo registra modelo e sugere voltar ao padrão', () {
    const error = ElevenApiException('segredo', 422);
    final failure = GenerationFailure.classify(error,
      audioReceived: false, audioSaved: false, model: CreditEstimator.flashModel);
    expect(failure.diagnostic, contains('modelo=eleven_flash_v2_5'));
    expect(failure.nextAction, contains('Multilingual v2'));
    final standard = GenerationFailure.classify(error,
      audioReceived: false, audioSaved: false, model: CreditEstimator.defaultModel);
    expect(standard.diagnostic, isNot(contains('modelo=')));
  });
}
