"""Stage public files and the manifest belonging to the latest stable release.

Runs on pushes and release publication, so a later site edit never removes
version.json. No repository write token or generated commit is needed.
"""
from __future__ import annotations

import json
import os
from pathlib import Path
import re
import shutil
import urllib.error
import urllib.request


def validate_manifest(manifest: dict, release: dict, repository: str) -> None:
    slug = repository.split('/')[1]
    version = manifest.get('version')
    if (manifest.get('schema') != 1 or manifest.get('app') != slug
            or manifest.get('package') != f'com.auralix.{slug}'
            or not isinstance(version, str) or not re.fullmatch(r'\d+\.\d+\.\d+', version)
            or manifest.get('tag') != f'v{version}' or release.get('tag_name') != f'v{version}'
            or type(manifest.get('build')) is not int or manifest['build'] < 1
            or type(manifest.get('min_build')) is not int
            or not 0 <= manifest['min_build'] <= manifest['build']):
        raise ValueError('Manifest identity/version/build does not match the stable release')
    assets = manifest.get('assets')
    if not isinstance(assets, dict) or not assets:
        raise ValueError('Manifest has no downloadable artifacts')
    published = {asset['name']: asset for asset in release.get('assets', [])}
    for asset in assets.values():
        if not isinstance(asset, dict):
            raise ValueError('Invalid manifest artifact')
        name = asset.get('name', '')
        actual = published.get(name)
        expected = f'https://github.com/{repository}/releases/download/v{version}/{name}'
        if (not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9._-]*', name)
                or not actual or asset.get('url') != expected
                or actual.get('browser_download_url') != expected
                or type(asset.get('size')) is not int or asset['size'] <= 0
                or actual.get('size') != asset['size']
                or not re.fullmatch(r'[a-fA-F0-9]{64}', asset.get('sha256', ''))):
            raise ValueError(f'Manifest artifact does not match the release: {name}')
        digest = actual.get('digest')
        if digest and digest.lower() != 'sha256:' + asset['sha256'].lower():
            raise ValueError(f'Artifact digest mismatch: {name}')


def read_url(url: str, token: str | None = None) -> bytes:
    headers = {'Accept': 'application/vnd.github+json', 'User-Agent': 'Auralix-Pages'}
    if token:
        headers['Authorization'] = 'Bearer ' + token
    with urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=30) as response:
        return response.read()


def prepare(source: Path, output: Path, repository: str) -> None:
    if not re.fullmatch(r'Auralix-Studio/(mediakeep|flux)', repository):
        raise ValueError('Unexpected public repository')
    if output.exists():
        raise ValueError('Staging destination must be a new directory')
    output.mkdir(parents=True)
    # Publish only the static site, excluding Git, workflows and private tooling.
    for item in source.iterdir():
        if item.is_file() and (item.suffix in {'.html', '.css', '.js', '.md', '.ico', '.svg'}
                               or item.name in {'.nojekyll', 'LICENSE'}):
            shutil.copy2(item, output / item.name)
    for directory in ('assets', 'docs'):
        if (source / directory).is_dir():
            shutil.copytree(source / directory, output / directory)
    try:
        raw = read_url(f'https://api.github.com/repos/{repository}/releases/latest', os.environ.get('GH_TOKEN'))
    except urllib.error.HTTPError as error:
        if error.code != 404:
            raise
        print('No stable release yet; staging site without an update manifest.')
        return
    release = json.loads(raw)
    if release.get('draft') or release.get('prerelease'):
        raise ValueError('Latest release must be published and stable')
    manifest_asset = next((asset for asset in release.get('assets', []) if asset.get('name') == 'version.json'), None)
    if not manifest_asset:
        print('::warning::The latest release predates version.json; no update manifest will be published.')
        return
    tag = release.get('tag_name', '')
    if not re.fullmatch(r'v\d+\.\d+\.\d+', tag):
        raise ValueError('Invalid release tag')
    expected_url = f'https://github.com/{repository}/releases/download/{tag}/version.json'
    if manifest_asset.get('browser_download_url') != expected_url:
        raise ValueError('Manifest download URL does not match the release')
    manifest_bytes = read_url(expected_url)
    manifest = json.loads(manifest_bytes)
    validate_manifest(manifest, release, repository)
    (output / 'version.json').write_bytes(manifest_bytes)
    print(f'Staged {repository} and verified version.json for {tag}.')


if __name__ == '__main__':
    source = Path(__file__).resolve().parent.parent
    prepare(source, source / '_site', os.environ['GITHUB_REPOSITORY'])
