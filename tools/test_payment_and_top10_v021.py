"""Regressões da alpha.21: 402 explicado por plano e Top 10 sem idioma."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text(encoding='utf-8')
class V021(unittest.TestCase):
    def test_top10_sem_idioma_nao_vira_erro_de_diagnostico(self):
        src=read('lib/src/voices_page.dart')
        i=src.index("if (rankingMode && activeLanguage == 'all')")
        j=src.index('final result = await fetch(revision: request);')
        self.assertLess(i,j)
        self.assertNotIn('AppDiagnostics',src[i:j])
        self.assertIn('return;',src[i:j])
    def test_motivos_de_pagamento_permitidos(self):
        src=read('lib/src/eleven_api.dart')
        self.assertIn("'payment_required', 'paid_plan_required'",src)
    def test_plano_passado_ao_classificador(self):
        self.assertIn('plan: widget.model.subscription?.tier',read('lib/src/studio_page.dart'))
        self.assertIn('String? plan',read('lib/src/generation_failure.dart'))
    def test_sem_tts_extra(self):
        self.assertEqual(read('lib/src/studio_page.dart').count('api.synthesize('),1)
if __name__=='__main__':unittest.main()
