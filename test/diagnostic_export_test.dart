import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uaivozes/src/diagnostic_export.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.drilemoz.uaivozes/key_transfer');

  test('Exportação fornece o relatório completo ao Kotlin SAF', () async {
    const fullText = 'Uai Vozes | Diagnóstico local\nRegistros: 2\n---\nA\nB';
    String? nativeContent;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'exportDiagnostic');
        nativeContent = call.arguments['content'] as String;
        return true;
      });
    expect(await DiagnosticExport.save(fullText),true);
    expect(nativeContent,fullText);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null);
  });

  test('Cancelamento do documento não é relatado como sucesso', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async => null);
    expect(await DiagnosticExport.save('relatório'),false);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null);
  });
}
