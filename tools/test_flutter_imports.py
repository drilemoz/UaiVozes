"""Regressões de importação que bloqueiam o lint estrito do GitHub Actions."""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class StudioImportsTests(unittest.TestCase):
    def test_studio_nao_reintroduz_import_duplicado(self):
        source = (ROOT / 'lib/src/studio_page.dart').read_text(encoding='utf-8')
        self.assertIn("import 'package:flutter/services.dart';", source)
        self.assertNotIn("import 'dart:typed_data';", source)


if __name__ == '__main__':
    unittest.main()
