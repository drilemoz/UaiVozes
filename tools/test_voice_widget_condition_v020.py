"""Protege a cadeia if/else do Explorador após falha de análise na alpha.19."""
from pathlib import Path
import re
import unittest
ROOT=Path(__file__).resolve().parents[1]
class VoiceWidgetCondition20(unittest.TestCase):
    def test_lista_tem_else_ligado_ao_estado_vazio(self):
        src=(ROOT/'lib/src/voices_page.dart').read_text(encoding='utf-8')
        start=src.index('if (widget.model.key.isEmpty)')
        end=src.index('if (loading) const Padding', start)
        block=src[start:end]
        self.assertRegex(block, r'else if \(visible\.isEmpty && !loading\)\s*EmptyState\(')
        # Entre o EmptyState vazio e a lista não pode haver outro if isolado.
        self.assertRegex(block, r"'Mostrar vozes da minha conta' : 'Limpar filtros'\)\)\)\s*else \.\.\.visible\.map\(")
        self.assertEqual(block.count('else ...visible.map'),1)
        self.assertIn('Consultar vozes padrão da minha conta',block)
        self.assertGreater(block.index('Consultar vozes padrão da minha conta'),block.index('else ...visible.map'))
    def test_sem_repetir_tts_ou_alterar_identificador(self):
        src=(ROOT/'lib/src/voices_page.dart').read_text(encoding='utf-8')
        self.assertIn('showAccountCandidates(defaultOnly: true)',src)
        self.assertEqual((ROOT/'pubspec.yaml').read_text(encoding='utf-8').count('version: 0.1.0-alpha.20+20'),1)
if __name__=='__main__':unittest.main()
