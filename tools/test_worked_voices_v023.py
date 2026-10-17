"""Alpha.23: selo e filtro de vozes que já geraram áudio, sem chamadas extras."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text(encoding='utf-8')
class V023(unittest.TestCase):
    def test_marca_so_depois_do_audio_recebido(self):
        s=read('lib/src/studio_page.dart')
        a=s.index('audioReceived = true;'); m=s.index('markVoiceWorked(voice.id)')
        self.assertLess(a,m); self.assertLess(m-a,300)
        self.assertEqual(s.count('api.synthesize('),1)
    def test_limpeza_por_conta_e_voz(self):
        s=read('lib/src/app_model.dart')
        self.assertIn("remove('worked_voices')",s)
        self.assertIn('workedVoiceIds.remove(voiceId)',s)
        self.assertIn('_maxWorkedVoices = 200',s)
    def test_filtro_e_selo(self):
        s=read('lib/src/voices_page.dart')
        self.assertIn('workedOnly && !widget.model.workedVoiceIds.contains(voice.id)',s)
        self.assertIn('Já gerou áudio nesta conta',s)
        self.assertGreaterEqual(s.count('workedOnly = false'),2)
        self.assertIn('observedWorkedCount != widget.model.workedVoiceIds.length',s)
    def test_sem_dados_sensiveis_no_registro(self):
        s=read('lib/src/app_model.dart')
        i=s.index('Future<void> markVoiceWorked'); blk=s[i:i+500]
        for bad in ('text','key','content'):
            self.assertNotIn(bad+')',blk)
if __name__=='__main__':unittest.main()
