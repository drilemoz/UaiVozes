import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:uaivozes/src/app_model.dart';
import 'package:uaivozes/src/settings_page.dart';

void main() {
  test('identidade Android, Flutter, metadados e APK sincronizados', () {
    final identity = jsonDecode(File('app_identity.json').readAsStringSync()) as Map<String, dynamic>;
    final manager = jsonDecode(File('github-manager.json').readAsStringSync()) as Map<String, dynamic>;
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final manifest = File('scripts/AndroidManifest.xml').readAsStringSync();
    final workflow = File('.github/workflows/gerar-apk.yml').readAsStringSync();
    expect(identity['name'], 'Uai Vozes');
    expect(identity['packageName'], 'com.drilemoz.uaivozes');
    expect(identity['versionName'], AppModel.version);
    expect(identity['versionCode'], AppModel.versionCode);
    expect(manager['projectName'], identity['name']);
    expect(manager['versionCode'], identity['versionCode']);
    final apkName = "Uai-Vozes-v0.${AppModel.versionCode.toString().padLeft(2, '0')}.apk";
    expect(manager['apkFileName'], apkName);
    expect(identity['apkFileName'], apkName);
    expect(pubspec, contains('name: uaivozes'));
    expect(pubspec, contains('version: ${AppModel.version}+${AppModel.versionCode}'));
    expect(manifest, contains('android:label="Uai Vozes"'));
    expect(manifest, contains('@android:drawable/ic_btn_speak_now'));
    expect(workflow, contains('dist/$apkName'));
    expect(workflow, contains('tag_name: v${AppModel.version}'));
    expect(releaseNotes.keys.first, AppModel.version);
  });
}
