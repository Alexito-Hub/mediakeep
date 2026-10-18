import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import urllib.error

from prepare_site import prepare, validate_manifest


class SiteReleaseTests(unittest.TestCase):
    def setUp(self):
        self.repo = 'Auralix-Studio/mediakeep'
        self.asset = {'name': 'mediakeep-v1.2.3-universal.apk', 'size': 1024, 'sha256': 'a' * 64,
                      'url': f'https://github.com/{self.repo}/releases/download/v1.2.3/mediakeep-v1.2.3-universal.apk'}
        self.manifest = {'schema': 1, 'app': 'mediakeep', 'package': 'com.auralix.mediakeep',
                         'version': '1.2.3', 'tag': 'v1.2.3', 'build': 12, 'min_build': 0,
                         'assets': {'android-universal': self.asset}}
        self.release = {'tag_name': 'v1.2.3', 'draft': False, 'prerelease': False, 'assets': [
            {'name': self.asset['name'], 'size': 1024, 'browser_download_url': self.asset['url'], 'digest': 'sha256:' + 'a' * 64},
            {'name': 'version.json', 'browser_download_url': f'https://github.com/{self.repo}/releases/download/v1.2.3/version.json'}]}

    def test_matching_release(self):
        validate_manifest(self.manifest, self.release, self.repo)

    def test_rejects_mismatches(self):
        for key, value in [('package', 'com.example.app'), ('tag', 'v1.2.4'), ('build', 0), ('min_build', 100), ('assets', {})]:
            with self.subTest(key=key), self.assertRaises(ValueError):
                validate_manifest({**self.manifest, key: value}, self.release, self.repo)
        for key, value in [('url', 'https://example.org/a.apk'), ('size', 1), ('sha256', 'b' * 64), ('name', 'missing.apk')]:
            manifest = {**self.manifest, 'assets': {'apk': {**self.asset, key: value}}}
            with self.subTest(key=key), self.assertRaises(ValueError):
                validate_manifest(manifest, self.release, self.repo)

    def test_stages_current_release_and_excludes_repository_files(self):
        with tempfile.TemporaryDirectory(dir=Path(__file__).resolve().parent) as folder:
            source = Path(folder)
            (source / 'index.html').write_text('<h1>App</h1>')
            (source / '.env').write_text('SECRET')
            (source / 'version.json').write_text('outdated')
            (source / '.git').mkdir()
            with patch('prepare_site.read_url', side_effect=[json.dumps(self.release).encode(), json.dumps(self.manifest).encode()]):
                prepare(source, source / '_site', self.repo)
            self.assertEqual(json.loads((source / '_site/version.json').read_bytes()), self.manifest)
            self.assertTrue((source / '_site/index.html').exists())
            self.assertFalse((source / '_site/.env').exists())
            self.assertFalse((source / '_site/.git').exists())

    def test_no_release_does_not_publish_stale_manifest(self):
        with tempfile.TemporaryDirectory(dir=Path(__file__).resolve().parent) as folder:
            source = Path(folder)
            (source / 'version.json').write_text('outdated')
            error = urllib.error.HTTPError('url', 404, 'Not found', {}, None)
            with patch('prepare_site.read_url', side_effect=error):
                prepare(source, source / '_site', self.repo)
            self.assertFalse((source / '_site/version.json').exists())

    def test_api_failure_blocks_deploy(self):
        with tempfile.TemporaryDirectory(dir=Path(__file__).resolve().parent) as folder:
            error = urllib.error.HTTPError('url', 403, 'Forbidden', {}, None)
            with patch('prepare_site.read_url', side_effect=error), self.assertRaises(urllib.error.HTTPError):
                prepare(Path(folder), Path(folder) / '_site', self.repo)


if __name__ == '__main__':
    unittest.main()
