"""Verifica somente arquivos distribuídos, nunca caches temporários do build.

O GitHub Actions usa o índice do Git para saber o que será distribuído.
Para um ZIP fornecido, verifique explicitamente as entradas do arquivo.
"""
from pathlib import Path, PurePosixPath
import subprocess
import zipfile


BLOCKED_ROOTS = {'.dart_tool', '.gradle', '.pub-cache', '.pub', 'build', 'dist', 'android'}
PRIVATE_EXTENSIONS = {'.jks', '.keystore', '.p12', '.pfx'}
PRIVATE_NAMES = {'key.properties', '.env', '.env.local'}


def forbidden_path(raw_path: str) -> bool:
    # Pathlib normaliza '.' e '/', mas mantém '..' para detectar ZIP Slip.
    path = PurePosixPath(raw_path.replace('\\', '/'))
    parts = path.parts
    if path.is_absolute() or '..' in parts or not parts:
        return True
    if parts[0] in BLOCKED_ROOTS or '__pycache__' in parts or path.suffix.lower() == '.pyc':
        return True
    return (path.suffix.lower() in PRIVATE_EXTENSIONS
            or path.name.lower() in PRIVATE_NAMES
            or path.name.lower().startswith('.env.'))


def distribution_paths(root: Path, source_archive: Path | None = None) -> list[str] | None:
    """Lista os nomes efetivamente versionados ou embalados, sem caches gerados.

    Retorna None se não houver nem ZIP explícito nem checkout Git válido.
    """
    if source_archive is not None:
        with zipfile.ZipFile(source_archive) as archive:
            # Testa integridade CRC antes de validar conteúdo distribuído.
            first_bad = archive.testzip()
            if first_bad:
                raise ValueError(f'Arquivo ZIP corrompido: {first_bad}')
            return [item.filename for item in archive.infolist() if not item.is_dir()]
    try:
        repo = subprocess.run(['git', '-C', str(root), 'rev-parse', '--show-toplevel'],
                              capture_output=True, check=False, text=True)
        if repo.returncode != 0 or Path(repo.stdout.strip()).resolve() != root.resolve():
            return None
        files = subprocess.run(['git', '-C', str(root), 'ls-files', '--cached', '-z'],
                               capture_output=True, check=True)
    except (OSError, subprocess.CalledProcessError):
        return None
    return [name.decode('utf-8', errors='replace')
            for name in files.stdout.split(b'\0') if name]


def prohibited_paths(paths: list[str]) -> list[str]:
    return [path for path in paths if forbidden_path(path)]
