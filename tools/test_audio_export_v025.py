"""Alpha.25: salvar MP3 da Biblioteca pelo seletor nativo, sem rede nem API."""
from pathlib import Path
import unittest
ROOT=Path(__file__).resolve().parents[1]
def read(p): return (ROOT/p).read_text(encoding='utf-8')
class V025(unittest.TestCase):
    def test_kotlin_restringe_ao_armazenamento_do_app(self):
        k=read('scripts/android/MainActivity.kt')
        self.assertIn('"exportAudio"',k)
        self.assertIn('applicationInfo.dataDir',k)
        self.assertIn('canonicalFile',k)
        self.assertIn('startsWith(base.path + java.io.File.separator)',k)
        self.assertIn('50L * 1024L * 1024L',k)
        self.assertIn('type = "audio/mpeg"',k)
        self.assertEqual(k.count('requestCode != audioRequest'),1)
        self.assertGreaterEqual(k.count('exportAudioPath = null'),2)
    def test_dart_usa_mesmo_canal_e_nome_seguro(self):
        d=read('lib/src/audio_export.dart')
        self.assertIn("com.drilemoz.uaivozes/key_transfer",d)
        self.assertIn("invokeMethod<bool>('exportAudio'",d)
    def test_biblioteca_tem_os_dois_botoes_sem_api(self):
        l=read('lib/src/library_page.dart')
        self.assertIn('Compartilhar',l); self.assertIn('Salvar MP3',l)
        self.assertIn('AudioExport.saveMp3(item.path, item.name)',l)
        i=l.index('Future<void> saveToDevice'); blk=l[i:i+700]
        for bad in ('synthesize','ElevenApi','http'):
            self.assertNotIn(bad,blk)
    def test_sem_novas_permissoes_android(self):
        m=read('scripts/AndroidManifest.xml')
        self.assertNotIn('WRITE_EXTERNAL_STORAGE',m)
        self.assertNotIn('MANAGE_EXTERNAL_STORAGE',m)
if __name__=='__main__':unittest.main()
