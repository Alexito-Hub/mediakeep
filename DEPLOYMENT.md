# 🚀 Deployment a Cloud Run con Cloud Build

## ✅ Soluciones implementadas

### 1. **Dockerfile optimizado**
- Usa imagen oficial `ghcr.io/cirruslabs/flutter:stable` (más rápido)
- Multi-stage build con nginx:alpine
- Validación de configuración nginx en build time

### 2. **cloudbuild.yaml**
- Build automático con cache de Docker (`--cache-from`)
- Tag de imagen por COMMIT_SHA (cada commit = nueva versión garantizada)
- Deploy automático a Cloud Run

### 3. **nginx.conf profesional**
- Gzip compression optimizado
- CSP (Content Security Policy) configurado
- Cache correcto: index.html nunca cachea, assets por 1 año
- Headers de seguridad completos
- Soporte para Cloudflare real IP
- Health check endpoint

---

## 📋 Setup inicial (una sola vez)

### 1. Conectar GitHub con Cloud Build

```bash
# Ve a: https://console.cloud.google.com/cloud-build/triggers
# O ejecuta:
gcloud projects list
gcloud config set project TU_PROYECTO_ID
```

**En Cloud Console:**
1. Ve a **Cloud Build** → **Triggers**
2. Click **"Connect Repository"**
3. Selecciona **GitHub** → Autoriza
4. Selecciona tu repo: `Auralix/mediakeep`
5. Click **"Create Trigger"**

**Configuración del Trigger:**
```yaml
Name: mediakeep-deploy
Event: Push to branch
Source: ^main$
Configuration: Cloud Build configuration file
Location: /cloudbuild.yaml
```

6. Click **"Create"**

### 2. Habilitar APIs necesarias

```bash
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com
```

### 3. Permisos de Cloud Build

```bash
# Obtener el número de proyecto
PROJECT_NUMBER=$(gcloud projects describe $(gcloud config get-value project) --format="value(projectNumber)")

# Dar permisos a Cloud Build para deployar a Cloud Run
gcloud projects add-iam-policy-binding $(gcloud config get-value project) \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/run.admin"

gcloud iam service-accounts add-iam-policy-binding \
  ${PROJECT_NUMBER}-compute@developer.gserviceaccount.com \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"
```

---

## 🎯 Cómo hacer deployment

### Es automático! 🎉

```bash
# 1. Haz tus cambios
git add .
git commit -m "feat: nueva funcionalidad"

# 2. Push a GitHub
git push origin main

# 3. Cloud Build automáticamente:
#    ✅ Detecta el push
#    ✅ Clona el repo
#    ✅ Ejecuta cloudbuild.yaml
#    ✅ Construye la imagen Docker (con cache)
#    ✅ Sube a GCR
#    ✅ Deploya a Cloud Run
#    ✅ ¡Listo en ~3-5 minutos!
```

### Ver el progreso

```bash
# Ver builds recientes
gcloud builds list --limit=5

# Ver logs del último build
gcloud builds log $(gcloud builds list --limit=1 --format="value(id)")

# Ver en el navegador
# https://console.cloud.google.com/cloud-build/builds
```

---

## 🔄 Workflow recomendado

### Para cada actualización:

1. **Desarrolla localmente**
   ```bash
   flutter run -d chrome
   ```

2. **Incrementa versión** (opcional)
   ```powershell
   .\build.ps1 version
   ```

3. **Commit y push**
   ```bash
   git add .
   git commit -m "feat: descripción del cambio"
   git push origin main
   ```

4. **Espera ~3-5 minutos** ⏱️
   - Cloud Build construye automáticamente
   - Deploy automático a Cloud Run

5. **Si usas Cloudflare**
   - Dashboard → Caching → Purge Everything
   - O configura Cloudflare para purgar automáticamente

6. **Verifica en navegador**
   - Hard refresh: `Ctrl+Shift+R`
   - DevTools (F12) → Network
   - Verifica que archivos JS tengan timestamps nuevos

---

## 🐛 Solución de problemas

### "El build falla en Cloud Build"

```bash
# Ver logs completos
gcloud builds log $(gcloud builds list --limit=1 --format="value(id)")

# Errores comunes:
# - pubspec.yaml tiene dependencias que no existen
# - Falta de permisos (revisar Step 3 del setup)
```

### "La página sigue mostrando versión antigua"

**Causa:** Cache de Cloudflare o navegador

**Solución:**
1. Verifica que el build terminó exitosamente
   ```bash
   gcloud builds list --limit=1
   ```

2. Verifica que Cloud Run tiene la nueva revisión
   ```bash
   gcloud run services describe mediakeep-web --region=us-central1 --format="value(status.latestReadyRevisionName)"
   ```

3. Purga cache de Cloudflare (si aplica)

4. Hard refresh: `Ctrl+Shift+R` en navegador

### "No se triggerea el build automáticamente"

**Revisa:**
```bash
# Ver triggers configurados
gcloud builds triggers list

# Ver si el trigger está habilitado
gcloud builds triggers describe TRIGGER_NAME
```

**Fixes:**
- Ve a Cloud Console → Cloud Build → Triggers
- Verifica que el trigger esté "Enabled"
- Verifica que la rama sea `main` (o tu rama de deploy)
- Verifica que apunte a `/cloudbuild.yaml`

### "Permission denied en Cloud Run"

```bash
# Re-aplicar permisos (ver Setup inicial, Step 3)
PROJECT_NUMBER=$(gcloud projects describe $(gcloud config get-value project) --format="value(projectNumber)")

gcloud projects add-iam-policy-binding $(gcloud config get-value project) \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/run.admin"
```

---

## 📊 Monitoreo

### Ver servicios de Cloud Run

```bash
# Lista de servicios
gcloud run services list

# Detalles del servicio
gcloud run services describe mediakeep-web --region=us-central1

# URL del servicio
gcloud run services describe mediakeep-web --region=us-central1 --format="value(status.url)"

# Ver revisiones (versiones)
gcloud run revisions list --service=mediakeep-web --region=us-central1

# Ver logs en tiempo real
gcloud run services logs read mediakeep-web --region=us-central1
```

### Ver imágenes en Container Registry

```bash
# Lista de imágenes
gcloud container images list

# Tags de mediakeep-web
gcloud container images list-tags gcr.io/$(gcloud config get-value project)/mediakeep-web

# Eliminar imágenes viejas (opcional)
gcloud container images list-tags gcr.io/$(gcloud config get-value project)/mediakeep-web \
  --filter='-tags:*' --format='get(digest)' --limit=10 | \
  xargs -I {} gcloud container images delete gcr.io/$(gcloud config get-value project)/mediakeep-web@{} --quiet
```

---

## 🎨 Deployment manual (si necesitas)

Si por alguna razón necesitas hacer deploy manual sin GitHub:

```bash
# 1. Build local
docker build -t gcr.io/$(gcloud config get-value project)/mediakeep-web:manual .

# 2. Push
docker push gcr.io/$(gcloud config get-value project)/mediakeep-web:manual

# 3. Deploy
gcloud run deploy mediakeep-web \
  --image gcr.io/$(gcloud config get-value project)/mediakeep-web:manual \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 8080 \
  --memory 512Mi
```

---

## 📌 Archivos importantes

- **[Dockerfile](Dockerfile)**: Build de Flutter + nginx
- **[cloudbuild.yaml](cloudbuild.yaml)**: Configuración de Cloud Build
- **[nginx.conf](nginx.conf)**: Configuración del servidor web
- **[.dockerignore](.dockerignore)**: Archivos excluidos del build

---

## ✨ Por qué funciona

1. **Tag por COMMIT_SHA**: Cada commit genera una imagen única
   - `gcr.io/PROJECT/mediakeep-web:abc123def` (commit específico)
   - `gcr.io/PROJECT/mediakeep-web:latest` (actualizado cada vez)

2. **Cloud Run detecta cambios**: Al deployar con imagen nueva, Cloud Run:
   - Crea una nueva revisión
   - Hace health check
   - Switchea todo el tráfico a la nueva revisión
   - Mantiene la revisión anterior por si hay rollback

3. **Cache correcto en nginx**:
   - `index.html`: `Cache-Control: no-store` → Nunca cachea
   - Assets (JS/CSS): `max-age=31536000, immutable` → Cachea 1 año
   - Los archivos JS tienen hash en el nombre → Cada build genera nuevos nombres

4. **Docker cache**: `--cache-from` reutiliza layers:
   - `flutter pub get` solo si cambió `pubspec.yaml`
   - Build solo si cambió código fuente
   - ⚡ Builds de ~3 min en vez de 10+ min

---

## 🔥 Tip Pro: GitHub Actions (alternativa)

Si prefieres GitHub Actions en lugar de Cloud Build, crea `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Cloud Run

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    permissions:
      contents: read
      id-token: write
    
    steps:
    - uses: actions/checkout@v4
    
    - id: auth
      uses: google-github-actions/auth@v2
      with:
        workload_identity_provider: ${{ secrets.WIF_PROVIDER }}
        service_account: ${{ secrets.WIF_SERVICE_ACCOUNT }}
    
    - name: Set up Cloud SDK
      uses: google-github-actions/setup-gcloud@v2
    
    - name: Configure Docker
      run: gcloud auth configure-docker
    
    - name: Build and Push
      run: |
        docker build \
          --build-arg BUILDKIT_INLINE_CACHE=1 \
          --cache-from gcr.io/${{ secrets.GCP_PROJECT_ID }}/mediakeep-web:latest \
          -t gcr.io/${{ secrets.GCP_PROJECT_ID }}/mediakeep-web:${{ github.sha }} \
          -t gcr.io/${{ secrets.GCP_PROJECT_ID }}/mediakeep-web:latest \
          .
        docker push --all-tags gcr.io/${{ secrets.GCP_PROJECT_ID }}/mediakeep-web
    
    - name: Deploy to Cloud Run
      run: |
        gcloud run deploy mediakeep-web \
          --image gcr.io/${{ secrets.GCP_PROJECT_ID }}/mediakeep-web:${{ github.sha }} \
          --platform managed \
          --region us-central1 \
          --allow-unauthenticated
```

---

**¡Listo! Push y olvídate. Cloud Build se encarga de todo automáticamente.** 🚀
