"""Checagens de regressão simples sem Flutter SDK."""
import json
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]
def read(path):return (ROOT/path).read_text(encoding='utf-8')

class VoiceUx18Tests(unittest.TestCase):
    def test_voice_filters_and_no_auto_tts(self):
        voices=read('lib/src/voices_page.dart')
        self.assertIn('voiceType: voiceType',voices)
        self.assertIn('sharedCategory: sharedCategory',voices)
        self.assertIn('languageLabel(e.key)',voices)
        self.assertIn('Compatíveis com meu plano',voices)
        self.assertIn('verifyLoadedAccess()',voices)
        self.assertIn('.take(10).toList()',voices)
        section=voices.split('Future<void> verifyLoadedAccess() async')[1].split('Future<void> removeVoice')[0]
        self.assertIn('api.voiceDetail',section)
        self.assertNotIn('synthesize(',section)
        self.assertIn('bulkCheckedVoices.add(voice.id)',section)
    def test_deletion_with_confirmation_without_local_audio_delete(self):
        voices=read('lib/src/voices_page.dart')
        section=voices.split('Future<void> removeVoice(Voice voice) async')[1].split('Future<void> showVoiceHelp')[0]
        self.assertLess(section.index('confirmSheet('),section.index('api.deleteVoice'))
        self.assertLess(section.index('api.deleteVoice'),section.index('voiceRemovedFromAccount'))
        self.assertNotIn('removeAudio',section)
        api=read('lib/src/eleven_api.dart')
        self.assertIn("_client.delete(",api)
        self.assertIn("data['status'] != 'ok'",api)
    def test_diagnostic_export_is_native_full_text(self):
        dart=read('lib/src/diagnostics_page.dart')
        native=read('scripts/android/MainActivity.kt')
        self.assertIn('DiagnosticExport.save(',dart)
        self.assertNotIn('Share.shareXFiles',dart)
        self.assertIn('ACTION_CREATE_DOCUMENT',native)
        self.assertIn('"exportDiagnostic"',native)
        self.assertIn('"Uai-Vozes-Diagnostico.txt"',native)
        self.assertIn('toByteArray(Charsets.UTF_8)',native)
        self.assertIn('label: const Text(\'Excluir\')',dart)
    def test_moves_diagnostics_to_settings(self):
        settings=read('lib/src/settings_page.dart')
        main=settings.split('class AboutPage')[0]
        about=settings.split('class AboutPage')[1]
        self.assertIn("title: const Text('Diagnóstico local')",main)
        self.assertNotIn("SectionTitle('Diagnóstico local')",about)
    def test_version_integrity(self):
        self.assertIn('0.1.0-alpha.26+26',read('pubspec.yaml'))
        for path in ['github-manager.json','app_identity.json']:
            data=json.loads(read(path));self.assertEqual(data['versionCode'],26)
            self.assertEqual(data['packageName'] if path=='app_identity.json' else data['projectName'],
                'com.drilemoz.uaivozes' if path=='app_identity.json' else 'Uai Vozes')

if __name__=='__main__':unittest.main()
