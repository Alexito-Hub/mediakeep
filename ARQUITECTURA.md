# MediaKeep — Arquitectura Completa del Proyecto

> **Versión del estudio:** 2026-02-27  
> **Propósito:** Documentar la base real del proyecto antes de cualquier modificación. Esta es la fuente de verdad de diseño para todas las implementaciones futuras.

---

## 1. Visión General

MediaKeep es un sistema de dos capas:

| Capa | Tecnología | Repositorio |
|------|-----------|-------------|
| **Frontend** | Flutter 3.x · Dart · SDK ^3.9.2 | `/mediakeep` |
| **Backend** | Node.js · Express 5 · TypeScript | `/backend` |

La app permite descargar medios (video, audio, imágenes) de 8 plataformas sociales sin marca de agua. Tiene sistema de límites de uso, monetización por MercadoPago, autenticación Firebase y publicidad AdMob.

**Plataformas soportadas:** TikTok · Instagram · Facebook · YouTube · Twitter/X · Spotify · Threads · Bilibili

---

## 2. Backend — `backend/src/`

### 2.1 Punto de Entrada — `server.ts`

```
server.ts
 ├── Inicializa MongoDB, SQLite y Google Cloud Storage
 ├── Configura express + Socket.IO (CORS compartido)
 ├── Middlewares globales (en orden):
 │    request-ip → Helmet → CORS → express-rate-limit (global)
 │    → cookieParser → express.json → urlencoded → morgan → session
 ├── GET /health  (health check público)
 ├── GET /uploads (servir archivos locales)
 └── Rutas dinámicas cargadas por Create.routes()
```

**CORS permitido:**
- `process.env.FRONTEND_URL`
- `process.env.CLOUD_RUN_URL`
- `/^https:\/\/.*\.mediakeep\.com$/`
- `/^http:\/\/localhost:\d+$/` (solo desarrollo)
- `/^https:\/\/.*\.run\.app$/`

**Rate limit global:** 100 req / 5 min (producción), 500 (desarrollo), independiente de los límites de uso de la app.

**Bases de datos activas:**
- **Firestore** (Firebase Admin SDK) — usuarios, límites, pagos, historial de anonimos
- **MongoDB** — sesiones de usuario (connect-mongo + express-session)
- **SQLite** (`./Storage/database.db`) — datos auxiliares con profiling activado
- **Google Cloud Storage** — archivos de media procesados

---

### 2.2 Cargador de Rutas Dinámico — `Utils/handler.ts`

```typescript
// Carga recursivamente todos los archivos de /Routes/
// Cada archivo exporta un objeto con estructura:
{
  name: string,       // Nombre legible
  path: string,       // Ruta HTTP (e.g. '/download/tiktok')
  method: string,     // 'post' | 'get' | 'put' | 'delete'
  category: string,   // Agrupación visual
  parameter?: string[], // Parámetros requeridos
  premium?: boolean,  // Flag para UI informativa
  error?: boolean,    // Si true → responde error inmediatamente
  logger?: boolean,   // Registrar en Config.routes
  requires?: Middleware,   // Validación de parámetros
  validator?: Middleware,  // Middleware de seguridad
  execution: Handler,      // Controlador final
}
```

El handler registra la ruta como: `router[method](path, error, requires, validator, execution)`

También carga sockets desde `/Socket/` de forma dinámica.

---

### 2.3 Rutas — `Routes/mediakeep/`

```
Routes/
└── mediakeep/
    ├── middlewares.ts          ← CENTRAL: define guest/member/pay
    ├── public/                 ← 8 scrapers (tiktok, instagram, fb,
    │   │                          youtube, twitter, spotify, threads, bilibili)
    │   └── *.ts
    ├── auth/                   ← [VACÍO — por implementar]
    ├── admin/                  ← [VACÍO — por implementar]
    └── payment/
        ├── checkout.ts         ← Genera init_point de MercadoPago
        └── webhook.ts          ← Listener asíncrono con validación HMAC
```

**Música:** `Routes/music/` (2 archivos, no relacionado con MediaKeep directamente)

---

### 2.4 Middleware Central — `Routes/mediakeep/middlewares.ts`

Define tres stacks de middleware reutilizables:

| Stack | Cadena | Usado en |
|-------|--------|----------|
| `guest(name)` | AppToken → UsageLimit.user → UsageLimit.limit → Cache(600s) | Rutas `/download/*` |
| `member` | AppToken → FirebaseAuth → UsageLimit.limit | Rutas auth (pendientes) |
| `pay` | AppToken → FirebaseAuth | Ruta `/payment/checkout` |

El método `run()` ejecuta middlewares en secuencia async, abortando si alguno envía respuesta.

**Cache:** In-memory (No externo), key = `{name}_{url}`, TTL 600s, solo se guarda si `status !== false`.

---

### 2.5 Middlewares Individuales — `Middleware/`

#### `appToken.ts`
- Valida `req.headers['x-app-token']` contra `process.env.APP_SECRET_TOKEN`
- Rechaza con 403 si inválido o ausente

#### `firebaseAuth.ts`
- Valida `Authorization: Bearer {token}` usando `firebase-admin.auth().verifyIdToken()`
- Inyecta `req.user = decodedToken` para handlers posteriores

#### `usageLimit.ts`
Dos métodos:

1. **`user`** (opcional): Si hay Bearer token válido, inyecta `req.user` sin fallar. Permite public routes con tracking condicional.

2. **`limit`** (obligatorio): 
   - **Autenticado** (`req.user` presente): Lee `users/{uid}` en Firestore con transacción atómica. Si `plan === 'free'` y `requestsCount >= totalLimit` → 403 `AUTH_LIMIT_REACHED`. Si no existe el doc → lo crea con defaults (plan: free, totalLimit: 10). Incrementa `requestsCount`.
   - **No autenticado**: Hash SHA-256 de `IP + x-device-fingerprint` → busca en `unauth_usage/{hash}`. Si `requestsCount >= 5` → 403 `UNAUTH_LIMIT_REACHED`. Si no existe → crea con count: 1.

#### `appCheck.ts`
- Firebase App Check (existe pero no está conectado al stack actual de middlewares)

---

### 2.6 Rutas Públicas de Scraping — `Routes/mediakeep/public/`

Todas siguen el mismo patrón:

```typescript
export default {
  path: '/download/{plataforma}',
  method: 'post',
  category: 'download',
  requires: (req, res, next) => { /* valida req.body.url */ },
  validator: Middlewares.guest('{plataforma}'),  // aplica stack completo
  execution: async (req, res) => {
    const result = await {Plataforma}Scraper.download(url);
    return res.status(200).json(result);
  }
};
```

Scrapers disponibles en `Utils/scrapper/`: tiktok, instagram, facebook, youtube, twitter, spotify, threads, bilibili.

---

### 2.7 Rutas de Pago — `Routes/mediakeep/payment/`

#### `checkout.ts` — POST `/payment/checkout`
- **Seguridad:** `Middlewares.pay` (AppToken + FirebaseAuth)
- Recibe `{ packageId, userId }` del body
- Diccionario de precios en backend (anti-spoofing):
  ```
  pack_50     → $15 MXN → +50 requests
  pack_100    → $25 MXN → +100 requests
  sub_premium → $49 MXN/mes → +99999 requests (ilimitado)
  ```
- Crea preferencia MercadoPago con metadatos (`user_id`, `package_requests`, `plan_type`, `expected_amount`)
- Retorna `{ init_point, preference_id }`

> **Bug detectado:** `userId` se toma de `req.body`, pero debería tomarse de `req.user.uid` (ya verificado por FirebaseAuth). Esto es un vector de suplantación menor.

#### `webhook.ts` — POST `/payment/webhook`
- Sin middleware especial (MercadoPago no envía `x-app-token`)
- Responde `200 OK` inmediatamente (requerimiento de MP)
- Valida firma HMAC SHA-256 contra `MP_WEBHOOK_SECRET`
- Descarga el pago por ID desde API oficial (no confía en body)
- Verifica `status === 'approved'` y que `transactionAmount >= expectedAmount`
- Actualiza Firestore en transacción atómica: `users/{uid}.totalLimit += packageRequests`, guarda en `payments/{paymentId}` para idempotencia

---

### 2.8 Firestore — Colecciones

```
/users/{uid}
  email: string
  name: string
  picture: string
  plan: 'free' | 'premium'
  requestsCount: int
  totalLimit: int         (10 free, +50/+100/+99999 por compra)
  lastPaymentId: string
  createdAt: Timestamp
  updatedAt: string

/unauth_usage/{sha256(ip+fingerprint)}
  requestsCount: int      (máx 5)
  ip: string
  fingerprint: string
  createdAt: Timestamp
  lastUsed: Timestamp

/payments/{paymentId}
  userId: string
  amount: number
  status: 'approved'
  type: 'premium'
  timestamp: string
  payment_method_id: string
  issuer_id: any
  installments: any
```

**Reglas de Firestore (`firestore.rules`):**
- `/users/{uid}`: lectura solo propia (auth), creación solo con valores default seguros, update solo `displayName/photoURL/lastActive`, delete bloqueado
- `/unauth_usage/*`: bloqueado completamente (solo Admin SDK)
- `/payments/{paymentId}`: lectura si `userId == request.auth.uid`, escritura bloqueada

---

### 2.9 Variables de Entorno relevantes (`backend/.env`)

```
PORT / WEBSERVER_PORT
NODE_ENV
APP_SECRET_TOKEN        ← x-app-token esperado
FIREBASE_SERVICE_ACCOUNT ← JSON del service account
MP_ACCESS_TOKEN         ← MercadoPago
MP_WEBHOOK_SECRET       ← HMAC para webhooks
FRONTEND_URL            ← CORS + back_urls de MP
CLOUD_RUN_URL
MONGODB_URL
SESSION_SECRET / JWT_SECRET
COOKIE_DOMAIN
```

---

## 3. Frontend — `mediakeep/lib/`

### 3.1 Punto de Entrada — `main.dart`

```
main() {
  FlutterDownloader.initialize()  // solo mobile (Android/iOS)
  MobileAds.instance.initialize() // solo mobile
  initFirebase()                  // todas las plataformas
  initializeDateFormatting('es')
  WidgetService.initialize()      // home screen widget (mobile)
  SystemChrome.setPreferredOrientations([portrait])
  runApp(DownloaderApp())
}
```

**App raíz:** `DownloaderApp` (StatefulWidget)
- Gestiona `ThemeMode` (sistema)
- Inicializa `QuickActionsService` (accesos directos al mantener app)
- Configura `WidgetService.onActionReceived` (home widget callbacks)
- `navigatorKey` global para navegación desde background/widgets
- Builder: `AdBlockGuard` wrapping todo el árbol
- Home: `DownloadScreen()`

---

### 3.2 Tema Visual

**Fuente:** Google Fonts — `Outfit`

**Paleta (Light):**
- Primary: `#00B4D8` (cian)
- Secondary: `#48CAE4`
- Surface: `#FFFFFF`
- OnSurface: `#18181B`
- Background `Card`: `#FAFAFA`

**Paleta (Dark):**
- Surface: `#18181B` (matte black)
- OnSurface: `#E4E4E7`
- Primary accent: `#4CC9F0`
- Card: `#27272A`

Material 3, AppBar transparente (elevation 0), border-radius 16-24px consistente.

---

### 3.3 Constantes — `utils/constants.dart`

```
apiBaseUrl:  'https://api.auralixpe.xyz'
appSecret:   'a8f9c1...f9a0'  ← x-app-token (hardcoded en cliente)
apiTimeout:  15 segundos
debounceDelay: 500ms
autoFetchDelay: 300ms
autoPasteDelay: 800ms
```

**Detección de plataforma:** patrones de dominio para los 8 servicios.

---

### 3.4 Navegación

No usa GoRouter ni Navigator 2. Usa Navigator 1 con `MaterialPageRoute` imperativa:

```
DownloadScreen (home)
 ├── → HistoryScreen
 ├── → SettingsScreen
 ├── → ActiveDownloadsScreen
 ├── → CheckoutScreen
 └── → MediaPreviewScreen
```

No existe `Router` configurado, sin deep linking declarativo.

---

### 3.5 Pantallas — `screens/`

| Archivo | Propósito | Estado |
|---------|-----------|--------|
| `download_screen.dart` | Pantalla principal (845 líneas) · URL input · detección de plataforma · fetch API · download trigger · HistoryService | ✅ Funcional |
| `history_screen.dart` | Historial local (SharedPreferences) | ✅ Funcional |
| `active_downloads_screen.dart` | Downloads activos en tiempo real | ⚠️ Stub (TODO) |
| `auth_screen.dart` | Login/registro (email + Google) | ✅ Funcional |
| `settings_screen.dart` | Tema, idioma, sobre la app | ✅ Funcional |
| `checkout_screen.dart` | Planes y compra in-app (MP) | ✅ Funcional |
| `media_preview_screen.dart` | Previsualización post-descarga | ⚠️ Básico |
| `status_screen.dart` | Estado del sistema/API | ✅ Funcional |
| `author_screen.dart` | Info del desarrollador | ✅ Funcional |
| `changelog_screen.dart` | Historial de versiones | ✅ Funcional |
| `privacy_screen.dart` | Política de privacidad | ✅ Funcional |

---

### 3.6 Servicios — `services/`

| Servicio | Función | Almacenamiento |
|----------|---------|---------------|
| `ApiService` | HTTP al backend · fingerprint · headers Auth | — |
| `AuthService` | Firebase Auth email/Google · initUser post-login | Firebase Auth |
| `FirestoreService` | Lectura de perfil en stream · getAuthToken · initializeUser | Firestore |
| `HistoryService` | CRUD historial de descargas · duplicate check | **SharedPreferences** |
| `DownloadService` | Factory (plataforma) → native/web | — |
| `DownloadServiceNative` | FlutterDownloader.enqueue · carpetas MediaKeep/{tipo} | SO |
| `DownloadServiceWeb` | URL redirect / open in browser | Browser |
| `AdManager` | Banner + Interstitial (AdMob, solo mobile) | — |
| `SettingsService` | ThemeMode persistente | SharedPreferences |
| `PermissionService` | Storage permissions (Android) | — |
| `QuickActionsService` | App shortcuts (mantener ícono) | — |
| `WidgetService` | Home screen widget Android (home_widget) | SharedPreferences |
| `StatusService` | Ping a endpoints para status check | — |
| `AppVersionService` | Versión actual | pubspec.yaml (asset) |
| `ChangelogService` | Lee assets/changelog.json | Assets |
| `BackgroundService` | Coordinador de descargas en background via MethodChannel | — |

> **⚠️ Importante:** `HistoryService` usa **SharedPreferences** (local, no Firestore). El historial NO está sincronizado en la nube y se pierde si se desinstala la app o se usa en otro dispositivo.

---

### 3.7 Modelos — `models/`

| Modelo | Plataforma |
|--------|-----------|
| `TikTokData` | TikTok (videos + imágenes slideshows) |
| `InstagramData` | Instagram (multiple media items con options) |
| `FacebookData` | Facebook (video/imagen) |
| `YouTubeData` | YouTube (info + videos[] con calidades) |
| `TwitterData` | Twitter/X (media[] con type) |
| `SpotifyData` | Spotify (audio, title, download URL) |
| `ThreadsData` | Threads (media[] con url+type) |
| `BilibiliData` | Bilibili |
| `DownloadHistoryItem` | Historial local |
| `StatusModel` | Estado de API endpoints |
| `ChangelogModel` | Versiones del changelog |

Todos tienen `fromJson` factory constructors.

---

### 3.8 Core — `core/`

```
core/
├── responses/
│   ├── api_response.dart      ← ApiResponse(success, data, platform, limitReached, errorMessage)
│   └── download_response.dart ← DownloadResponse(success, filePath, fileName, subfolder, errorMessage)
└── types/
    └── typedefs.dart          ← ProgressCallback = Function(double progress, String status)
```

---

### 3.9 Widgets — `widgets/`

```
widgets/
├── ads/
│   ├── adblock_guard.dart     ← DetectaAdBlock, bloquea acceso si detectado
│   ├── web_ad_view.dart       ← Ad HTML embebido para web
│   └── ...
├── auth/
│   ├── google_button_web.dart ← Botón Google Sign-In nativo web
│   └── ...
├── common/
│   ├── shimmer_widget.dart    ← Loading skeleton
│   └── ...
├── dialogs/
│   └── share_dialog.dart      ← Dialog post-descarga (share_plus)
├── media/
│   ├── video_player_widget.dart ← (video_player + video_player_win)
│   └── audio_player_widget.dart ← (audioplayers)
└── result_cards/
    └── {plataforma}_result_card.dart (8 archivos) ← UI de resultados
```

---

### 3.10 Utilidades — `utils/`

| Archivo | Función |
|---------|---------|
| `constants.dart` | API URL, secrets, timeouts, platform patterns |
| `platform_detector.dart` | Detecta plataforma desde URL por patrones |
| `platform_config.dart` | Colores/icons/nombres por plataforma para UI |
| `responsive.dart` | `Responsive.getContentPadding()`, breakpoints |

**Breakpoints responsive actuales:** `responsive.dart` define padding según ancho. No existen layouts completamente diferenciados para tablet vs desktop, solo padding adaptive.

---

### 3.11 Flujo de Descarga Actual

```
Usuario pega URL
  → _detectPlatform() → debounce 500ms → _fetchMedia()
    → ApiService.fetchMedia(url, platform)
      → POST /download/{platform}
        → [AppToken] → [UsageLimit.user] → [UsageLimit.limit] → [Cache]
        → Execution: Scraper.download(url)
      ← { status: true, data: {...} }
    → ApiService.parseResponseData() → modelo tipado
    → setState (muestra ResultCard)
  → Usuario toca "Descargar" en ResultCard
    → _startDownload(url, type)
      → PermissionService.requestStoragePermissions()
      → HistoryService.isContentAlreadyDownloaded()
      → DownloadService.startDownload() [muestra overlay con blur + progress]
        → FlutterDownloader.enqueue() (background, notificación nativa)
        → HistoryService.addDownload()
      ← DownloadResponse.success
    → MethodChannel → showDownloadNotification (Android)
    → showShareDialog()
    → AdManager.showInterstitialAd() (si no premium)
```

**Limitación actual:** La descarga bloquea navegación (overlay modal). `ActiveDownloadsScreen` existe pero es un stub sin datos reales. El progreso en tiempo real de FlutterDownloader no está conectado.

---

### 3.12 Plataformas Target

| Plataforma | Soporte | Notas |
|-----------|---------|-------|
| Android | ✅ Completo | FlutterDownloader, permisos storage, AdMob, share intent, home widget, ClipboardMonitorService |
| iOS | ✅ Completo | FlutterDownloader, compartir, AdMob |
| Web | ✅ Parcial | Sin FlutterDownloader (abre URL en tab), WebAdView, Firebase Auth con popups |
| Windows | ✅ Básico | video_player_win, getDownloadsDirectory |
| macOS/Linux | ⚠️ No priorizado | Compila pero sin garantías |

---

### 3.13 Android Nativo — `android/`

- `ClipboardMonitorService.java` — Monitorea portapapeles, detecta URLs de redes sociales y dispara descarga desde background
- `MainActivity.java` — MethodChannels: `com.mediakeep.aur/background`, `com.mediakeep.aur/notifications`
- Package: `com.mediakeep.aur`
- `google-services.json` incluido (Firebase)

---

## 4. Integración Firebase

### Frontend (`mediakeep`)
- `firebase_options.dart` — generado por FlutterFire CLI, proyecto `media-keep-e1636`
- `firebase_core: ^3.9.0` + `firebase_auth: ^5.4.0` + `cloud_firestore: ^5.6.0`
- `google_sign_in: ^6.2.2` + `google_sign_in_web: ^0.12.0`
- Web Client ID: `354908157298-50aud2k7amfugeqhqu2hdpstb9jf4psi.apps.googleusercontent.com`

### Backend
- `firebase-admin: ^13.6.0`
- Config en `Config/firebase.ts`: Lee `FIREBASE_SERVICE_ACCOUNT` env var (prod) o `firebase-adminsdk.json` (dev)
- Proyecto: `media-keep-e1636`

---

## 5. Estado Actual — Qué Funciona y Qué No

### ✅ Implementado y Funcional
- Scraping de 8 plataformas con middleware stack completo
- Límite 5 req anónimos (IP+fingerprint, Firestore)
- Límite 10 req usuario free (Firestore, transacciones atómicas)
- Firebase Auth email+password + Google
- MercadoPago checkout + webhook con HMAC + idempotencia
- AdMob banner + interstitial (mobile)
- AdBlock detection
- Historial de descargas (local SharedPreferences)
- FlutterDownloader background (Android/iOS)
- Notificaciones nativas Android
- ClipboardMonitorService (Android)
- Home screen widget (Android)
- Quick Actions (holds app icon)
- Rate limiting global HTTP
- CORS estricto
- Helmet.js security headers
- x-app-token validation

### ⚠️ Pendiente o Incompleto
- **`auth/` y `admin/` routes backend:** Directorios vacíos
- **`ActiveDownloadsScreen`:** Stub, no conectado a datos reales
- **`MediaPreviewScreen`:** Básico, sin viewers completos
- **Historial en nube:** HistoryService usa SharedPreferences, no Firestore
- **Limit Modal en DownloadScreen:** Acción "Iniciar Sesión" tiene TODO comment
- **userId en checkout:** Se toma de `req.body` en lugar de `req.user.uid`
- **Orientación forzada:** `portraitOnly` en main.dart bloquea tablet/desktop
- **Responsive tablet:** No existe layout tablet diferenciado
- **Video/Audio players post-descarga:** No integrados en preview screen
- **Repos de `sub_premium`:** El back aún no implementa reset mensual de requests

---

## 6. Convenciones de Código Establecidas

### Backend
- Cada módulo de ruta exporta un objeto default con la interfaz `RouteDefinition`
- Middlewares son singletons (instancias de clase con `new class X {}`)
- Los scrapers están en `Utils/scrapper/{plataforma}.ts`
- Respuestas siempre incluyen `{ status: boolean, msg?: string, data?: any }`
- 403 para límites, 401 para auth, 400 para validación, 500 para server error

### Frontend
- Screens en `screens/`, con sufijo `_screen.dart`
- Services en `services/`, con sufijo `_service.dart`
- Todos los servicios son clases estáticas (no instanciadas)
- Navegación siempre via `Navigator.push(MaterialPageRoute(...))`
- `ApiResponse` y `DownloadResponse` como tipos de retorno uniformes
- `shared_preferences` para persistencia local, Firestore para usuario en nube
- `AppConstants` como única fuente de verdad para configuración

---

## 7. Dependencias Clave

### Backend (selección)
| Paquete | Versión | Uso |
|---------|---------|-----|
| express | ^5.1.0 | Framework HTTP |
| firebase-admin | ^13.6.0 | Auth + Firestore Admin |
| mercadopago | ^2.12.0 | Pagos |
| helmet | ^8.1.0 | Security headers |
| express-rate-limit | ^8.2.1 | Rate limiting |
| socket.io | ^4.8.1 | WebSockets |
| mongoose | ^8.19.3 | MongoDB ORM |
| better-sqlite3 | ^12.4.1 | SQLite sync |
| winston | ^3.18.3 | Logging |
| pino | ^10.1.0 | Logging alternativo |
| axios | ^1.13.2 | HTTP client para scrapers |

### Frontend (selección)
| Paquete | Versión | Uso |
|---------|---------|-----|
| firebase_core | ^3.9.0 | Firebase base |
| firebase_auth | ^5.4.0 | Autenticación |
| cloud_firestore | ^5.6.0 | Base de datos |
| google_mobile_ads | ^5.1.0 | AdMob |
| flutter_downloader | ^1.11.8 | Descargas background |
| dio | ^5.4.0 | HTTP avanzado |
| video_player | ^2.9.2 | Reproductor video |
| video_player_win | ^3.0.0 | Reproductor video Windows |
| audioplayers | ^6.1.0 | Reproductor audio |
| receive_sharing_intent | ^1.8.1 | Share Extension |
| share_plus | ^10.1.4 | Compartir archivos |
| shared_preferences | ^2.2.2 | Persistencia local |
| google_fonts | ^6.3.2 | Outfit font |
| home_widget | ^0.6.0 | Widget pantalla inicio |
| quick_actions | ^1.1.0 | App shortcuts |

---

## 8. Plan de Implementación de Mejoras

Ver `implementation_plan.md` para el roadmap detallado con pasos específicos.

---

*Documento generado para evitar pérdida de progreso y garantizar que todas las mejoras se construyan sobre la arquitectura real sin romper lo que ya funciona.*
