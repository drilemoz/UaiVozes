"""Alpha.22: botão do aviso 402 abre vozes padrão sem TTS."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text(encoding='utf-8')
class V022(unittest.TestCase):
    def test_botao_no_aviso_402(self):
        s=read('lib/src/studio_page.dart')
        i=s.index("Ver vozes padrão da minha conta")
        block=s[i-300:i+500]
        self.assertIn('widget.openVoices()',block)
        self.assertIn('widget.model.requestDefaultVoices()',block)
        self.assertNotIn('synthesize',block)
    def test_aba_vozes_reage_ao_pedido(self):
        s=read('lib/src/voices_page.dart')
        self.assertIn('observedDefaultRequest != widget.model.defaultVoicesRequest',s)
        self.assertIn('showAccountCandidates(defaultOnly: true)',s)
    def test_modelo_expõe_pedido(self):
        s=read('lib/src/app_model.dart')
        self.assertIn('void requestDefaultVoices()',s)
    def test_um_unico_synthesize_no_estudio(self):
        self.assertEqual(read('lib/src/studio_page.dart').count('api.synthesize('),1)
if __name__=='__main__':unittest.main()
