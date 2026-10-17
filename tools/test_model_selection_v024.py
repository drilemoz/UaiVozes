"""Alpha.24: seletor de modelo com lista fechada, sem chamadas extras."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text(encoding='utf-8')
class V024(unittest.TestCase):
    def test_lista_fechada(self):
        s=read('lib/src/credit_ledger.dart')
        self.assertIn("flashModel = 'eleven_flash_v2_5'",s)
        self.assertIn('(characters + 1) ~/ 2',s)
        self.assertEqual(s.count('TtsModelOption('),3)  # classe + 2 opções
    def test_modelo_validado_ao_carregar_e_trocar(self):
        s=read('lib/src/app_model.dart')
        self.assertIn('CreditEstimator.isKnownModel(savedModel)',s)
        self.assertIn('!CreditEstimator.isKnownModel(id)',s)
    def test_estudio_usa_modelo_escolhido(self):
        s=read('lib/src/studio_page.dart')
        self.assertIn('model: widget.model.ttsModel)',s)
        self.assertIn('modelId: widget.model.ttsModel',s)
        self.assertNotIn('CreditEstimator.defaultModel',s)
        self.assertEqual(s.count('api.synthesize('),1)
    def test_conta_e_falha_usam_modelo(self):
        self.assertIn('model.ttsModel',read('lib/src/account_page.dart'))
        self.assertIn('modelo=$model',read('lib/src/generation_failure.dart'))
if __name__=='__main__':unittest.main()
