"""Regressão do build #8: GitHub Actions isola ambiente entre passos."""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SECRETS = ('KEYSTORE_BASE64', 'KEYSTORE_PASSWORD', 'KEY_ALIAS', 'KEY_PASSWORD')


def _step(name, workflow):
    match = re.search(
        rf'(?ms)^      - name: {re.escape(name)}\n(.*?)(?=^      - name:|\Z)', workflow
    )
    if not match:
        raise AssertionError(f'Etapa não encontrada: {name}')
    return match.group(1)


class SigningWorkflowTest(unittest.TestCase):
    def setUp(self):
        self.workflow = (ROOT / '.github/workflows/gerar-apk.yml').read_text()
        self.prepare = (ROOT / 'scripts/prepare_android.sh').read_text()

    def test_secrets_estao_disponiveis_em_cada_passo_necessario(self):
        for step in ('Gerar Android nativo e configurar assinatura', 'Compilar APK ARM64 otimizado'):
            body = _step(step, self.workflow)
            for secret in SECRETS:
                self.assertIn(f'{secret}: ${{{{ secrets.{secret} }}}}', body, msg=f'{step}: {secret}')

    def test_reconhece_regressao_de_variavel_ausente_no_build(self):
        block = _step('Compilar APK ARM64 otimizado', self.workflow)
        broken = block.replace('KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}', '')
        self.assertNotIn('KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}', broken)
        self.assertIn('KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}', block)

    def test_keystore_nao_e_assinatura_de_debug(self):
        self.assertIn('System.getenv("KEYSTORE_PASSWORD")', self.prepare)
        self.assertIn('signingConfigs.getByName("release")', self.prepare)
        self.assertIn('-storepass:env KEYSTORE_PASSWORD', self.prepare)
        self.assertIn('umask 077', self.prepare)
        self.assertIn('base64 -d > android/app/release-key.jks', self.prepare)
        self.assertNotIn('storePassword = "', self.prepare)


if __name__ == '__main__':
    unittest.main()
