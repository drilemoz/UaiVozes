"""Regressão do plano Free/Top 10 e fallback para vozes próprias.
Não faz chamadas à API nem TTS, deve rodar sem Flutter.
"""
import unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]

class AccountCandidatesTest(unittest.TestCase):
    def test_states_keep_no_false_positive(self):
        s=(ROOT/'lib/src/voice_access.dart').read_text(encoding='utf-8')
        self.assertIn('ownedCatalog && !info.isRestricted',s)
        self.assertIn('VoiceAccessFilter.compatible => info.isCompatible',s)
        self.assertIn('publicLibrary && plan == \'free\'',s)

    def test_top_ten_has_account_fallback_without_tts(self):
        s=(ROOT/'lib/src/voices_page.dart').read_text(encoding='utf-8')
        block=s.split('void showAccountCandidates(')[1].split('Future<void> showFilters()',1)[0]
        self.assertIn('accessFilter = VoiceAccessFilter.accountCandidates',block)
        self.assertIn('rankingMode = false',block)
        self.assertIn("voiceType = defaultOnly ? 'default' : 'all'",block)
        self.assertIn('unawaited(refresh())',block)
        self.assertNotIn('synthesize(',block)
        self.assertNotIn('addSharedVoice(',block)
        self.assertIn('Top 10 é biblioteca pública',s)
        self.assertIn('Mostrar vozes da minha conta',s)

    def test_candidates_are_own_catalog_only(self):
        s=(ROOT/'lib/src/voices_page.dart').read_text(encoding='utf-8')
        self.assertIn('ownedCatalog: !rankingMode',s)
        self.assertIn('filter != VoiceAccessFilter.accountCandidates',s)
        self.assertIn('Consultar vozes padrão da minha conta',s)
        self.assertIn('geração não confirmada',s)

    def test_diagnostic_insufficient_evidence_is_not_silenced(self):
        s=(ROOT/'lib/src/voice_block_diagnostics.dart').read_text(encoding='utf-8')
        self.assertIn('402',s)
        self.assertIn('inconclusiveDetail',s)

if __name__=='__main__': unittest.main()
