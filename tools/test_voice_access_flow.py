"""Regressões estáticas da integração do filtro, além dos testes Dart reais no CI."""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

class VoiceAccessFlowTests(unittest.TestCase):
    def test_filtros_sao_locais_e_nao_disparam_tts(self):
        ui = (ROOT/'lib/src/voices_page.dart').read_text(encoding='utf-8')
        for name in ('Compatíveis com meu plano', 'Restritas', 'A confirmar'):
            self.assertIn(name, ui)
        self.assertIn('allLoaded.where(matches).toList()', ui)
        self.assertIn('matchesVoiceAccessFilter(accessFilter, accessFor(voice))', ui)
        self.assertIn('more()', ui)

    def test_consulta_manual_isolada_e_sem_geracao(self):
        ui = (ROOT/'lib/src/voices_page.dart').read_text(encoding='utf-8')
        start = ui.index('Future<void> verifyVoice(')
        end = ui.index('VoiceAccessInfo accessFor(', start)
        scope = ui[start:end]
        self.assertIn('widget.model.api.voiceDetail(voice.id)', scope)
        self.assertIn('key != widget.model.key', scope)
        self.assertIn('revision != requestVersion', scope)
        self.assertIn('checkingVoices.contains(voice.id)', scope)
        self.assertNotIn('synthesize(', scope)
        self.assertNotIn('addSharedVoice(', scope)

    def test_estados_sao_documentados_sem_classificar_ausencia_como_gratis(self):
        access = (ROOT/'lib/src/voice_access.dart').read_text(encoding='utf-8')
        self.assertIn('listed.contains(plan)', access)
        self.assertIn('VoiceAccess.unknown', access)
        self.assertIn('publicLibrary && plan == \'free\'', access)
        self.assertNotIn('freeUsersAllowed == true', access)

if __name__ == '__main__':
    unittest.main()
