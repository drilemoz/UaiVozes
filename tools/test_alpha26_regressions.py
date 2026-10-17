"""Preflight of alpha.26 integration even when Flutter/Android SDK absent."""
from pathlib import Path
import unittest
ROOT = Path(__file__).resolve().parents[1]
def read(path): return (ROOT/path).read_text(encoding='utf8')

class Alpha26Tests(unittest.TestCase):
    def test_android_speech_and_saf_export_coexist(self):
        main=read('scripts/android/MainActivity.kt')
        self.assertIn('AndroidSpeechBridge(this, flutterEngine.dartExecutor.binaryMessenger)',main)
        self.assertIn('androidSpeech?.close()',main)
        self.assertIn('"exportAudio"',main)
        self.assertIn('"exportDiagnostic"',main)
        self.assertIn('val copied = stream.use',main)
        self.assertIn('copied != source.length()',main)
        self.assertIn('canonicalFile',main)
        self.assertIn('startsWith(base.path + java.io.File.separator)',main)
        prep=read('scripts/prepare_android.sh')
        for kotlin_file in ('MainActivity.kt','AndroidSpeechBridge.kt'):
            self.assertIn('cp scripts/android/'+kotlin_file,prep)
        self.assertIn('com.drilemoz.uaivozes/android_speech',read('scripts/android/AndroidSpeechBridge.kt'))
    def test_local_speech_no_billing_and_free_option(self):
        studio=read('lib/src/studio_page.dart')
        android=read('lib/src/android_speech.dart')
        block=studio.split('Future<void> readWithAndroid() async')[1].split('Future<void> generate() async')[0]
        self.assertIn('androidSpeech.speak(',block)
        self.assertNotIn('api.synthesize(',block)
        self.assertNotIn('saveAudio(',block)
        self.assertEqual(studio.count('api.synthesize('),1)
        self.assertIn('Ouvir texto com voz do Android (sem créditos)',studio)
        self.assertIn('Ouvir com voz do Android, sem créditos ElevenLabs',studio)
        self.assertIn('AndroidSpeech(',studio)
        self.assertIn('languageTag',android)
        self.assertNotIn('ElevenApi',android)
        self.assertIn('android.intent.action.TTS_SERVICE',read('scripts/AndroidManifest.xml'))
    def test_zero_confirmed_balance_blocks_generation(self):
        studio=read('lib/src/studio_page.dart')
        guard=studio.split('if (widget.model.subscription?.remaining == 0) {')[1].split('if (widget.model.confirmCreditsBeforeGenerate) {')[0]
        self.assertIn('await widget.model.refreshUsage();',guard)
        self.assertIn('widget.model.usageError != null',guard)
        self.assertIn('remainingAfterRefresh <= 0',guard)
        self.assertIn('widget.model.refreshingUsage',guard)
        self.assertLess(studio.index('remainingAfterRefresh <= 0'),studio.index('widget.model.tryBeginGeneration()'))
    def test_dart_test_uses_supported_repetition(self):
        dart=read('test/audio_export_test.dart')
        self.assertNotIn("'x' * 300",dart)
        self.assertIn("List.filled(300, 'x').join()",dart)
    def test_versioning_and_data_preserved(self):
        self.assertIn('0.1.0-alpha.26+26',read('pubspec.yaml'))
        self.assertIn('0.1.0-alpha.26',read('lib/src/settings_page.dart'))
        self.assertIn('Uai-Vozes-v0.26.apk',read('.github/workflows/gerar-apk.yml'))
        for field in ('KEYSTORE_BASE64','KEYSTORE_PASSWORD','KEY_ALIAS','KEY_PASSWORD'):
            self.assertIn(field,read('.github/workflows/gerar-apk.yml'))
        self.assertIn('AudioCatalog',read('lib/src/app_model.dart'))

if __name__ == '__main__': unittest.main()
