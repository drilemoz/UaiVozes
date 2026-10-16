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

  testWidgets('configurações exibe mensagem de teste sem chave',
      (tester) async {
    final model = AppModel();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SettingsPage(
      model: model, showChanges: () {}, showWizard: () {}))));
    await tester.ensureVisible(find.text('Testar API'));
    await tester.tap(find.text('Testar API'));
    await tester.pump();
    expect(find.text('Cole sua chave antes de testar.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    model.dispose();
  });
}
