# Validação da versão 0.1.0-alpha.2+2

## Causa do workflow anterior

O workflow `Gerar APK Eleven` #1 concluiu a instalação do Flutter SDK 3.47.7 e `flutter pub get`, mas `flutter analyze` falhou com código 1 devido a seis ocorrências `deprecated_member_use` em `lib/src/settings_page.dart`, relativas a `RadioListTile.groupValue` / `onChanged` (linhas 153,154,160,161,167,168). O build e o APK não chegaram a ser executados.

## Correção

Os três `RadioListTile<ThemeMode>` ficam sob `RadioGroup<ThemeMode>` com `groupValue` e `onChanged` apenas no ancestral. Com Flutter >=3.35, este é o padrão suportado oficialmente. O workflow fixa Flutter 3.47.7 para reduzir variações entre compilações.

Também foram alterados o identificador Android (`com.drilemoz.uaivozes`), o pacote Flutter (`uaivozes`), os nomes exibidos, as notas, o workflow, o ícone de launcher nativo do Android e os metadados de versão.

## Pendências

Não há SDK Flutter ou Android no ambiente local; o resultado de `flutter analyze`, `flutter test`, `flutter build apk`, instalação e acesso à API precisa ser verificado pelo próximo run do workflow. Não declarar APK testado antes disso.
