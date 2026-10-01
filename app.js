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
      const link = document.createElement('a'); link.href = url;
      link.textContent = asset.name + (asset.size ? ' · ' + (asset.size/1048576).toFixed(1) + ' MB' : '');
      list.append(link);
    }
    if (!list.children.length) status.textContent += ' · Consulta los archivos en GitHub.';
  } catch {
    if (history) history.textContent = 'No se pudo consultar el historial. Usa el enlace a GitHub.';
    if (status) status.textContent = 'No se pudo consultar una versión pública. Revisa las publicaciones en GitHub.';
  }
})();
