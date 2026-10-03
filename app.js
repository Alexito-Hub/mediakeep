'use strict';
(async () => {
  const repo = document.body.dataset.repository;
  const status = document.querySelector('#status');
  const history = document.querySelector('#history');
  if (!status && !history) return;
  const list = document.querySelector('#assets');
  function safeUrl(value, prefix) {
    try { const u = new URL(value); return u.origin === 'https://github.com' && u.pathname.toLowerCase().startsWith('/' + repo.toLowerCase() + prefix) ? u.href : null; } catch { return null; }
  }
  const formatBytes = (bytes, decimals) => {
    if (!+bytes) return '0 B';
    const k = 1024, dm = decimals != null ? decimals : 1, sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
  };
  try {
    const endpoint = history ? '/releases?per_page=30' : '/releases/latest';
    const response = await fetch('https://api.github.com/repos/' + repo + endpoint, {signal: AbortSignal.timeout(10000), headers:{Accept:'application/vnd.github+json'}});
    if (response.status === 404) {
      if (status) { status.textContent = 'Todavía no hay una versión pública disponible.'; document.querySelector('#notes').textContent = 'Las notas aparecerán junto con la primera publicación.'; }
      if (history) history.textContent = 'Todavía no hay versiones estables publicadas.';
      return;
    }
    if (!response.ok) throw new Error('unavailable');
    const data = await response.json();
    if (history) {
      const releases = data.filter(r => !r.draft && !r.prerelease);
      history.replaceChildren();
      if (!releases.length) { history.textContent = 'Todavía no hay versiones estables publicadas.'; return; }
      for (const release of releases) {
        const url = safeUrl(release.html_url, '/releases/tag/');
        if (!url) continue;
        const article = document.createElement('section'); article.className = 'release-entry';
        const link = document.createElement('a'); link.href = url; link.textContent = release.name || release.tag_name;
        const notes = document.createElement('pre'); notes.textContent = release.body || 'Sin notas adicionales.';
        article.append(link,notes); history.append(article);
      }
      if (!history.children.length) history.textContent = 'Consulta el historial completo en GitHub.';
      return;
    }
    if (data.draft || data.prerelease) throw new Error('not stable');
    status.textContent = 'Versión ' + data.tag_name;
    document.querySelector('#notes').textContent = data.body || 'Consulta los detalles de esta versión en GitHub.';
    for (const asset of data.assets || []) {
      if (!/\.(apk|zip|exe|txt)$/.test(asset.name)) continue;
      const url = safeUrl(asset.browser_download_url, '/releases/download/');
      if (!url) continue;
      const tr = document.createElement('tr');
      const tdFile = document.createElement('td');
      tdFile.innerHTML = '<span class="file">' + asset.name + '</span>';
      const tdSize = document.createElement('td');
      tdSize.className = 'size';
      tdSize.textContent = asset.size ? formatBytes(asset.size) : '--';
      const tdAction = document.createElement('td');
      const link = document.createElement('a'); link.href = url; link.className = 'button'; link.style.padding = '10px 15px'; link.textContent = 'Descargar';
      tdAction.appendChild(link);
      tr.append(tdFile, tdSize, tdAction);
      list.append(tr);
    }
    if (!list.children.length) status.textContent += ' · Consulta los archivos en GitHub.';
    /* ── Version injection ── */
    if (typeof document.querySelectorAll === 'function') {
      document.querySelectorAll('[data-dynamic-version]').forEach(function (el) { el.textContent = data.tag_name; });
    }
    /* ── OS-aware hero download ── */
    renderHeroDownload(data.assets || [], data.tag_name);
  } catch {
    if (history) history.textContent = 'No se pudo consultar el historial. Usa el enlace a GitHub.';
    if (status) status.textContent = 'No se pudo consultar una versión pública. Revisa las publicaciones en GitHub.';
  }
  function renderHeroDownload(assets, tag) {
    var container = document.querySelector('#hero-download-actions');
    if (!container) return;
    var ua = (typeof navigator !== 'undefined' && navigator.userAgent) || '';
    var os = 'Unknown';
    if (/Windows/i.test(ua)) os = 'Windows';
    else if (/Android/i.test(ua)) os = 'Android';
    else if (/Macintosh|Mac OS X/i.test(ua)) os = 'Mac';
    else if (/iPhone|iPad|iPod/i.test(ua)) os = 'iOS';
    else if (/Linux/i.test(ua)) os = 'Linux';
    var find = function (kw, ignore) { return assets.find(function (a) { var n = a.name.toLowerCase(); return n.includes(kw) && (!ignore || !n.includes(ignore)); }); };
    var best = null, text = '', meta = '';
    if (os === 'Android') {
      best = find('universal.apk') || find('.apk');
      if (best) { text = 'Descargar para Android'; meta = formatBytes(best.size) + ' · APK'; }
    } else if (os === 'Windows') {
      best = find('.exe') || find('windows.zip') || find('windows');
      if (best) { text = 'Descargar para Windows'; meta = formatBytes(best.size) + ' · ' + best.name.split('.').pop().toUpperCase(); }
    } else if (os === 'Linux') {
      best = find('linux');
      if (best) { text = 'Descargar para Linux'; meta = formatBytes(best.size); }
    }
    if (!best) return; /* Keep original buttons as fallback */
    var href = safeUrl(best.browser_download_url, '/releases/download/');
    if (!href) return;
    container.innerHTML = '';
    var a = document.createElement('a');
    a.href = href; a.className = 'button';
    a.textContent = text;
    var span = document.createElement('span');
    span.className = 'btn-meta'; span.textContent = meta;
    a.appendChild(span);
    container.appendChild(a);
    var other = document.createElement('a');
    other.href = 'downloads.html'; other.className = 'text-link';
    other.textContent = 'Todas las descargas';
    container.appendChild(other);
  }
})();
