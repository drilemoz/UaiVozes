"""Resguarda integração de captura de bloqueios sem requisições TTS extras."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]

class VoiceBlockCaptureTests(unittest.TestCase):
    def test_select_and_manual_detail_logging(self):
        src = (ROOT/'lib/src/voices_page.dart').read_text()
        self.assertIn('VoiceCheckStage.select', src)
        self.assertIn('VoiceCheckStage.detail', src)
        self.assertIn('VoiceBlockDiagnostics.inconclusiveDetail', src)
        self.assertIn('VoiceBlockDiagnostics.apiFailure', src)
        self.assertIn('widget.model.api.voiceDetail(voice.id)', src)
    def test_studio_both_local_and_api_errors(self):
        src = (ROOT/'lib/src/studio_page.dart').read_text()
        self.assertIn('VoiceBlockDiagnostics.localRestriction', src)
        self.assertIn('VoiceBlockDiagnostics.apiFailure', src)
        self.assertNotIn('api.synthesize(', (ROOT/'lib/src/voice_block_diagnostics.dart').read_text())
    def test_export_filter_and_privacy(self):
        src = (ROOT/'lib/src/diagnostics_page.dart').read_text()
        self.assertIn('onlyVoiceEvents', src)
        self.assertIn('voiceOnly: onlyVoiceEvents', src)
        src = (ROOT/'lib/src/voice_block_diagnostics.dart').read_text()
        self.assertNotIn('voice.name', src)
        self.assertNotIn('voice.description', src)
        self.assertIn('_safeReasons', src)

if __name__ == '__main__':
    unittest.main()
