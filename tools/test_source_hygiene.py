"""Testes sem dependências: python3 -m unittest discover -s tools -p 'test_*.py'."""
import subprocess
import tempfile
import unittest
from pathlib import Path
from zipfile import ZipFile

from source_hygiene import distribution_paths, forbidden_path, prohibited_paths


class SourceHygieneTests(unittest.TestCase):
    def test_forbidden_generated_and_private_files(self):
        for path in ('.dart_tool/package_config.json', 'build/app/outputs/app.apk',
                     'android/app/release-key.jks', '.gradle/cache', 'dist/app.apk',
                     'Uai-Vozes-Secrets-IMPORTAR.p12', '.env', '.env.test',
                     'tools/__pycache__/cache.pyc', '../outside.txt'):
            with self.subTest(path=path):
                self.assertTrue(forbidden_path(path))
        for path in ('tools/validate_source.py', 'lib/src/app_model.dart',
                     'scripts/android/MainActivity.kt', '.github/workflows/gerar-apk.yml'):
            with self.subTest(path=path):
                self.assertFalse(forbidden_path(path))

    def test_zip_checks_contents_not_extracted_workspace(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / '.dart_tool').mkdir()
            (root / '.dart_tool' / 'generated.json').write_text('{}')
            archive = root / 'source.zip'
            with ZipFile(archive, 'w') as zip_file:
                zip_file.writestr('lib/main.dart', 'void main() {}')
            self.assertEqual(prohibited_paths(distribution_paths(root, archive)), [])
            with ZipFile(archive, 'a') as zip_file:
                zip_file.writestr('android/app/release-key.jks', 'private key')
            self.assertEqual(prohibited_paths(distribution_paths(root, archive)),
                             ['android/app/release-key.jks'])

    def test_git_index_ignores_untracked_flutter_output(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            subprocess.run(['git', '-C', str(root), 'init', '-q'], check=True)
            (root / 'pubspec.yaml').write_text('name: uaivozes\n')
            (root / '.gitignore').write_text('/android/\n')
            native_dir = root / 'scripts' / 'android'
            native_dir.mkdir(parents=True)
            (native_dir / 'MainActivity.kt').write_text('package com.drilemoz.uaivozes')
            subprocess.run(['git', '-C', str(root), 'add', '.'], check=True)
            (root / '.dart_tool').mkdir()
            (root / '.dart_tool' / 'package_config.json').write_text('{}')
            (root / 'android').mkdir()
            (root / 'android' / 'release-key.jks').write_text('private key')
            self.assertIn('scripts/android/MainActivity.kt', distribution_paths(root))
            self.assertIn('pubspec.yaml', distribution_paths(root))
            subprocess.run(['git', '-C', str(root), 'add', '-f', 'android/release-key.jks'], check=True)
            self.assertIn('android/release-key.jks', prohibited_paths(distribution_paths(root)))


if __name__ == '__main__':
    unittest.main()
