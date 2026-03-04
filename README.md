# 🎬 MediaKeep - Media Downloader

Aplicación Flutter Web para descargar videos e imágenes de múltiples plataformas.

## 🚀 Quick Start

### Desarrollo local
```bash
flutter pub get
flutter run -d chrome
```

### Build para producción
```bash
flutter build web --release
```

## 📦 Deployment a Cloud Run

**Deployment automático con cada push a `main`**

1. Configura Cloud Build (ver [DEPLOYMENT.md](DEPLOYMENT.md))
2. Push a GitHub → Deploy automático en ~3-5 minutos

### Manual
```bash
git add .
git commit -m "feat: descripción"
git push origin main
```

Cloud Build se encarga de:
- ✅ Build de Flutter Web
- ✅ Construcción de imagen Docker
- ✅ Deploy a Cloud Run

## 📚 Documentación

- **[DEPLOYMENT.md](DEPLOYMENT.md)**: Guía completa de deployment
- **[ARQUITECTURA.md](ARQUITECTURA.md)**: Arquitectura de la aplicación
- **[MEDIAKEEP.md](MEDIAKEEP.md)**: Documentación del proyecto

## 🛠️ Archivos clave

- `Dockerfile`: Build multi-stage con Flutter + nginx
- `cloudbuild.yaml`: Pipeline de CI/CD
- `nginx.conf`: Configuración optimizada del servidor
- `pubspec.yaml`: Dependencias y versión

## 📋 Plataformas soportadas

- TikTok
- Instagram
- Facebook
- YouTube
- Twitter/X
- Threads
- Spotify

## 🔧 Tecnologías

- **Flutter Web**: Framework
- **Firebase**: Auth + Firestore
- **Google Ads**: Monetización
- **Cloud Run**: Hosting
- **nginx**: Web server
- **Docker**: Containerización

## 📝 Versionamiento

```powershell
# Incrementar versión automáticamente
.\build.ps1 version           # Patch (1.0.4 → 1.0.5)
.\build.ps1 version -Minor    # Minor (1.0.4 → 1.1.0)
.\build.ps1 version -Major    # Major (1.0.4 → 2.0.0)
```

## 🐛 Troubleshooting

Ver [DEPLOYMENT.md](DEPLOYMENT.md#-solución-de-problemas) para solución de problemas comunes.

---

**Versión**: 1.0.4+8  
**Última actualización**: Marzo 2026
