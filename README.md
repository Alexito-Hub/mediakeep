# MediaKeep
Web pública, documentación y distribución de MediaKeep.

Sitio: https://auralix-studio.github.io/mediakeep/
Publicaciones: https://github.com/Auralix-Studio/mediakeep/releases

## Estructura
- index.html: presentación del producto con su identidad visual.
- downloads.html: última versión estable y archivos publicados.
- docs.html: índice de guías.
- install.html, architecture.html, faq.html, troubleshoot.html: instalación, funcionamiento y ayuda.
- about.html, privacy.html, license.html: información del proyecto.
- changelog.html: historial de releases estables consultado desde GitHub.
- docs/: documentación en Markdown.
- assets/: recursos gráficos locales.
- PRIVACY.md, CHANGELOG.md, LICENSE: referencias del repositorio.

## Desarrollo
Sitio estático sin dependencias ni build obligatorio. Servir esta carpeta con un servidor HTTP. Los enlaces son relativos y funcionan bajo /mediakeep/ en GitHub Pages.

La consulta de releases no utiliza tokens. Los fallos de red y la ausencia de publicaciones muestran un aviso; no se inventan versiones ni enlaces a binarios inexistentes. Las notas externas se muestran como texto.

## Publicación
GitHub Pages usa el workflow .github/workflows/pages.yml al actualizar main. Configurar Pages con origen GitHub Actions.

El código de la app se mantiene en otro repositorio. Nunca copiar su historial ni sus carpetas a este repositorio. Los scripts de la app usan release.config.json para dirigir aquí los binarios y PUBLIC_RELEASE_TOKEN para publicar desde CI.

La transferencia del repositorio de código a Auralix se gestiona por separado. No es necesaria para servir esta web; después de transferir, actualizar origin en el checkout privado y revisar los secrets del workflow de la app.

## Mantenimiento
Editar HTML, CSS y app.js en este repositorio. La documentación Markdown debe mantenerse alineada con las páginas correspondientes. Publicar los cambios de la app desde su propio flujo de releases; la web leerá las nuevas versiones automáticamente.
