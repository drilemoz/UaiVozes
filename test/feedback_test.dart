import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uaivozes/main.dart';
import 'package:uaivozes/src/app_model.dart';
import 'package:uaivozes/src/settings_page.dart';

void main() {
  testWidgets('wizard exibe feedback visível quando chave estiver vazia',
      (tester) async {
    final model = AppModel();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body:
      WizardSheet(model: model, onExplore: () {}))));
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(find.text('Cole sua chave antes de guardar.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    model.dispose();
  });

  testWidgets('wizard pede para guardar chave digitada antes de avançar', (tester) async {
    final model = AppModel();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body:
      WizardSheet(model: model, onExplore: () {}))));
    await tester.enterText(find.byType(TextField).first, 'sk_test_unsaved');
    await tester.ensureVisible(find.text('Próximo'));
    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();
    expect(find.text('Chave ainda não guardada'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Etapa 1 de 4'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    model.dispose();
  });

  testWidgets('configurações exibe mensagem de teste sem chave',
      (tester) async {
    final model = AppModel();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SettingsPage(
      model: model, showChanges: () {}, showWizard: () {}))));
    await tester.ensureVisible(find.text('Testar'));
    await tester.tap(find.text('Testar'));
    await tester.pump();
    expect(find.text('Cole sua chave antes de testar.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    model.dispose();
  });
}
