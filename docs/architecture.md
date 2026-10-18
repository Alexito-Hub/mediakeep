# Arquitectura · MediaKeep

## Aplicación Flutter

La interfaz coordina la entrada de enlaces, las descargas, el historial y los ajustes. En Android se integra con enlaces compartidos, almacenamiento y notificaciones.

## Procesamiento y servicios

Las solicitudes de contenido pueden pasar por un backend. La versión actual no requiere una cuenta de Firebase. El procesamiento depende de la disponibilidad del backend y de las plataformas de origen.

## Distribución independiente

La web contiene guías y enlaces a binarios. Las publicaciones incluyen notas y sumas SHA-256; el código de la aplicación se mantiene separado del repositorio público de distribución.

## Versiones y actualizaciones

Cada publicación contiene paquetes versionados, sumas SHA-256 y un manifiesto version.json. El número de compilación determina si hay una actualización. Este sitio consulta la última release estable y, si la API no responde, puede usar el manifiesto de la publicación sincronizado con la web.
