'use strict';
(async () => {
  const repo = document.body.dataset.repository;
  if (!/^Auralix-Studio\/(mediakeep|flux)$/.test(repo || '')) return;
  const slug = repo.split('/')[1];
  const status = document.querySelector('#status');
  const history = document.querySelector('#history');
  const hero = document.querySelector('#hero-download-actions');
  const versions = Array.from(document.querySelectorAll('[data-dynamic-version]'));
  if (!status && !history && !hero && !versions.length) return;
  const list = document.querySelector('#assets');
  const notes = document.querySelector('#notes');
  const tagPattern = /^v\d+\.\d+\.\d+$/;
  const cacheKey = slug + '.release.v3';
  const cacheAge = 5 * 60 * 1000;

  function safeUrl(value, prefix) {
    if (typeof value !== 'string') return null;
    try {
      const url = new URL(value);
      return url.origin === 'https://github.com' && !url.username && !url.password &&
        !url.search && !url.hash && url.pathname.startsWith('/' + repo + prefix)
        ? url.href : null;
    } catch { return null; }
  }
  function releaseUrl(release) {
    if (!release || !tagPattern.test(release.tag_name)) return null;
    const expected = 'https://github.com/' + repo + '/releases/tag/' + release.tag_name;
    return release.html_url === expected ? expected : null;
  }
  function isStable(release) {
    return release && !release.draft && !release.prerelease && releaseUrl(release) && Array.isArray(release.assets);
  }
  function assetUrl(asset, tag) {
    if (!asset || typeof asset.name !== 'string' || !/^[A-Za-z0-9][A-Za-z0-9._-]*$/.test(asset.name)) return null;
    const prefix = '/releases/download/' + tag + '/';
    const url = safeUrl(asset.browser_download_url, prefix);
    return url === 'https://github.com/' + repo + prefix + asset.name ? url : null;
  }
  function downloadable(asset, tag) {
    return assetUrl(asset, tag) && (/\.(apk|zip|exe|tar\.gz)$/i.test(asset.name) ||
      ['SHA256SUMS.txt', 'version.json', 'release-meta.json'].includes(asset.name));
  }
  function formatBytes(value) {
    const bytes = Number(value);
    if (!Number.isFinite(bytes) || bytes <= 0) return '—';
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.min(Math.floor(Math.log(bytes) / Math.log(1024)), sizes.length - 1);
    return Number((bytes / Math.pow(1024, i)).toFixed(1)) + ' ' + sizes[i];
  }
  function label(asset) {
    const name = asset.name.toLowerCase();
    if (name.endsWith('-universal.apk') || name === slug + '-android.apk') return 'Android · universal';
    if (name.endsWith('-arm64.apk')) return 'Android · ARM64';
    if (name.endsWith('-armv7.apk')) return 'Android · ARM de 32 bits';
    if (name.endsWith('-x86_64.apk')) return 'Android · x86_64';
    if (name.endsWith('-setup-x64.exe')) return 'Windows · instalador';
    if (name.endsWith('-windows-x64.zip')) return 'Windows · portable';
    if (name === 'sha256sums.txt') return 'Verificación SHA-256';
    if (name.endsWith('.json')) return 'Metadatos de la publicación';
    return 'Archivo de la publicación';
  }
  async function request(url) {
    const response = await fetch(url, {
      signal: AbortSignal.timeout(10000), cache: 'no-cache',
      headers: { Accept: 'application/json' }
    });
    if (!response.ok) {
      const error = new Error('HTTP ' + response.status);
      error.status = response.status;
      throw error;
    }
    return response.json();
  }
  function fromManifest(manifest) {
    if (!manifest || manifest.schema !== 1 || manifest.app !== slug ||
      manifest.package !== 'com.auralix.' + slug || !/^\d+\.\d+\.\d+$/.test(manifest.version) ||
      manifest.tag !== 'v' + manifest.version || !Number.isInteger(manifest.build) || manifest.build < 1 ||
      !manifest.assets || typeof manifest.assets !== 'object' || Array.isArray(manifest.assets)) {
      throw new Error('Invalid manifest');
    }
    const assets = Object.values(manifest.assets).filter(asset => asset &&
      /^[a-f\d]{64}$/i.test(asset.sha256 || '') && Number.isInteger(asset.size) && asset.size > 0)
      .map(asset => ({ name: asset.name, size: asset.size, browser_download_url: asset.url }))
      .filter(asset => downloadable(asset, manifest.tag));
    if (!assets.length) throw new Error('Empty manifest');
    return {
      tag_name: manifest.tag, name: manifest.version,
      html_url: 'https://github.com/' + repo + '/releases/tag/' + manifest.tag,
      body: typeof manifest.notes === 'string' ? manifest.notes : '',
      draft: false, prerelease: false, assets, fromManifest: true
    };
  }
  async function latestRelease() {
    try {
      const cached = JSON.parse(localStorage.getItem(cacheKey) || 'null');
      const elapsed = cached && Date.now() - cached.at;
      if (elapsed >= 0 && elapsed < cacheAge && isStable(cached.release)) return cached.release;
    } catch { /* Private browsing may disable storage. */ }
    let release;
    try {
      release = await request('https://api.github.com/repos/' + repo + '/releases/latest');
      if (!isStable(release)) throw new Error('Invalid stable release');
    } catch (error) {
      // A 404 is authoritative: do not revive a removed release from the site.
      if (error.status === 404) throw error;
      release = fromManifest(await request('version.json'));
    }
    try { localStorage.setItem(cacheKey, JSON.stringify({ at: Date.now(), release })); } catch { /* Optional cache. */ }
    return release;
  }
  function renderHero(assets, tag) {
    if (!hero) return;
    const ua = (typeof navigator !== 'undefined' && navigator.userAgent) || '';
    const find = suffix => assets.find(asset => asset.name === slug + '-' + tag + suffix);
    let best, title;
    if (/Android/i.test(ua)) {
      // The user agent does not reliably expose the Android ABI.
      best = find('-universal.apk') || assets.find(asset => asset.name === slug + '-android.apk');
      title = 'Descargar para Android';
    } else if (/Windows/i.test(ua)) {
      best = find('-setup-x64.exe') || find('-windows-x64.zip');
      title = 'Descargar para Windows';
    }
    if (!best) return;
    const link = document.createElement('a');
    link.href = assetUrl(best, tag); link.className = 'button'; link.textContent = title;
    const meta = document.createElement('span');
    meta.className = 'btn-meta'; meta.textContent = formatBytes(best.size) + ' · ' + label(best);
    link.append(meta);
    const other = document.createElement('a');
    other.href = 'downloads.html'; other.className = 'text-link'; other.textContent = 'Todas las descargas';
    hero.replaceChildren(link, other);
  }
  try {
    if (history) {
      const data = await request('https://api.github.com/repos/' + repo + '/releases?per_page=30');
      if (!Array.isArray(data)) throw new Error('Invalid history');
      history.replaceChildren();
      for (const release of data.filter(isStable)) {
        const article = document.createElement('section'); article.className = 'release-entry';
        const link = document.createElement('a');
        link.href = releaseUrl(release); link.textContent = release.name || release.tag_name;
        const body = document.createElement('pre'); body.textContent = release.body || 'Sin notas adicionales.';
        article.append(link, body); history.append(article);
      }
      if (!history.children.length) history.textContent = 'Todavía no hay versiones estables publicadas.';
      return;
    }
    const release = await latestRelease();
    const assets = release.assets.filter(asset => downloadable(asset, release.tag_name));
    if (status) status.textContent = 'Versión ' + release.tag_name + (release.fromManifest ? ' · Datos del manifiesto oficial.' : '');
    if (notes) notes.textContent = release.body || 'Consulta los detalles de esta versión en GitHub.';
    if (list) {
      list.replaceChildren();
      for (const asset of assets) {
        const row = document.createElement('tr');
        const file = document.createElement('td');
        const name = document.createElement('span'); name.className = 'file'; name.textContent = asset.name;
        const platform = document.createElement('small'); platform.textContent = label(asset);
        file.append(name, document.createElement('br'), platform);
        const size = document.createElement('td'); size.className = 'size'; size.textContent = formatBytes(asset.size);
        const action = document.createElement('td');
        const link = document.createElement('a'); link.href = assetUrl(asset, release.tag_name);
        link.className = 'button'; link.style.padding = '10px 15px'; link.textContent = 'Descargar';
        action.append(link); row.append(file, size, action); list.append(row);
      }
      if (!assets.length && status) status.textContent += ' · Consulta los archivos en GitHub.';
    }
    versions.forEach(element => { element.textContent = release.tag_name; });
    renderHero(assets, release.tag_name);
  } catch (error) {
    if (history) history.textContent = error.status === 404 ? 'Todavía no hay versiones estables publicadas.' : 'No se pudo consultar el historial. Usa el enlace a GitHub.';
    if (status) status.textContent = error.status === 404 ? 'Todavía no hay una versión pública disponible.' : 'No se pudo consultar una versión pública. Revisa las publicaciones en GitHub.';
    if (notes) notes.textContent = error.status === 404 ? 'Las notas aparecerán junto con la primera publicación.' : 'Consulta las notas mediante el enlace a las publicaciones de GitHub.';
    // Homepage links remain usable even when no release data is available.
  }
})();
