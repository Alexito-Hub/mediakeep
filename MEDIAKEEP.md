# MediaKeep - Documentación del Proyecto y Arquitectura

## Estado Actual del Proyecto (Finalización de Overhaul)
La aplicación consta de dos partes principales que operan en conjunto:
1. **Frontend (MediaKeep)**: Aplicación Flutter multiplataforma (Mobile, Web, Desktop) con soporte offline-first y descargas nativas en background.
2. **Backend (Auralix API)**: Servidor Node.js con Express y TypeScript, orientado a la extracción de medios, administración y facturación, asegurado de forma granular.

## Arquitectura y Estructura de Carpetas

### Frontend (`/mediakeep`)
- **`lib/`**: Código fuente principal.
  - `main.dart`: Punto de entrada, inicialización de Firebase Core y Auth, `flutter_downloader` y dependencias globales.
  - `screens/`: Vistas principales. Descargas (`download_screen`), Dashboard (`active_downloads_screen`), Reproductores Nativos (`media_preview_screen`), Autenticación (`auth_screen`).
  - `services/`: Capa lógica. `ApiService` maneja huellas digitales y tokens, `DownloadService` enlaza con SO nativos para persistir descargas.
  - `widgets/`: Componentes modulares y `viewers/` especializados para Zoom (imágenes), Controles de Video y Audio.

### Backend (`/backend/src`)
- `server.ts`: Configuración principal. Aplica Rate Limiting global, Helmet.js (Security Headers) y directivas de CORS estrictas limitadas a dominios de producción.
- `Utils/handler.ts`: Cargador automático y dinámico de rutas. **Esta arquitectura core se ha preservado sin modificaciones invasivas**, inyectando los middlewares directamente desde los archivos de rutas usando validadores High Order, permitiendo usar la misma estructura original.
- `Routes/mediakeep/`: Directorio central.
  - `public/`: (8 archivos) Rutas de extracción (TikTok, FB, IG, Spotify...). Envueltas nativamente de forma individual.
  - `auth/`: Rutas exclusivas para usuarios autenticados.
  - `admin/`: Funciones administrativas elevadas.
  - `payment/`: `checkout.ts` y `webhook.ts`. Emisión de URLs MercadoPago y escuchas asíncronas de facturación.
  - `middlewareCentral.ts`: Proveedor de envolturas de middlewares (`withPublicMiddlewares`, `withPaymentMiddlewares`) para inyectar flujos de límite y caché sobre los `execution` originales de cada ruta.

## Middlewares de Seguridad Implementados
- **`appToken.ts`**: Verifica el header `x-app-token` para bloquear peticiones que no provengan de los binarios oficiales compilados.
- **`usageLimit.ts`**: Verifica y descuenta interacciones. Aplica límite de 5 peticiones por IP/Fingerprint (Unauth) persistidos sobre una base in-memory y 10 por cuenta validada (Auth) leyendo desde Firestore de manera estricta. Ningún límite puede ser evadido actualizando memoria web.
- **`firebaseAuth.ts`**: Decodifica el token Bearer usando Admin SDK (`firebase-admin`) para comprobar la identidad e impedir suplantación de headers.
- **`CacheSystem (middlewareCentral)`**: Capa de caché in-memory integrada nativamente sobre el wrapper público, respondiendo de inmediato peticiones duplicadas a los scrapers (URL caching x 600 segundos) para no saturar al proxy.

## Base de Datos y Colecciones Firestore
Todo el almacenamiento se ha migrado a Google Cloud Firestore.
- **Colección `users/{uid}`**: Contiene esquema: `email` (string), `plan` (string, ej: free, premium), `totalLimit` (int), `lastPaymentId` (string), `updatedAt` (timestamp).
- **Colección `history/{id}`**: Contiene registro validado con `userId` (string, referenciado a `users`), `url` (string), `type` (string).
- **Colección `payments/{id}`**: Log de transacciones webhook con `userId` (string), `amount` (number), `status` (string), `type` (string).

**Reglas de Seguridad (`firestore.rules`)**:
El archivo de reglas oficial (raíz del proyecto) bloquea por completo la escritura cliente a perfiles de usuarios. Las recargas de saldo y planes SOLO pueden ser modificadas por el Backend Admin SDK a través del listener de MercadoPago (*webhook.ts*). El usuario solo puede leer sus límites correspondientes.

## Modelo de Monetización, Anti-Fraude, Planes y Anuncios
- **Gateway Seleccionada**: MercadoPago (amplia cobertura regional LatAm).
- **Publicidad (AdMob)**: Se integra `google_mobile_ads`. Los usuarios Unauth y Auth Gratis experimentan *Banner Ads* (en la pantalla principal/historial) y *Interstitial Ads* (cada X descargas o al revelar players).

**Configuración de Google Sign-In**

Para que el inicio de sesión con Google funcione correctamente:

1. El `web client ID` usado en `auth_screen.dart` y `web/index.html` debe
   coincidir con el que aparece en la consola de Firebase.
2. El archivo `android/app/google-services.json` se genera desde Firebase y **debe**:
   * contener el mismo `web client ID` si también se usa la versión web.
   * incluir un `SHA-1` válido de tu keystore de *debug* y/o *release* según
     donde ejecutes la aplicación. Si ejecutas en modo debug, añade el SHA-1
     que se obtiene con el `keytool` de Android.
   * si cambias alguno de los valores anteriores, vuelve a descargar el archivo
     desde la consola y reemplace el existente.

Sin esta configuración el plugin falla con un error `developer_error`.

**Credenciales necesarias de Firebase**

Al configurar el proyecto en la consola de Firebase necesitas copiar/pegar
los siguientes valores según plataforma:

- **Android** (`google-services.json`):
  * `project_id`, `project_number`
  * `api_key.current_key`
  * `oauth_client` para Android (package + SHA) y opcionalmente uno tipo 3
    (web client).
  * `mobilesdk_app_id` (identificador único generado).
- **iOS/macOS** (`GoogleService-Info.plist`):
  * `GOOGLE_APP_ID` (appId), `API_KEY`, `BUNDLE_ID`, `PROJECT_ID`.
- **Web** (firebaseConfig objet en `firebase_options.dart` o JS):
  * `apiKey`, `authDomain`, `projectId`, `storageBucket`, `messagingSenderId`,
    `appId`, `measurementId`.
- **Service account** (opcional) para el Admin SDK:
  * descargable desde "Configuración del proyecto → Cuentas de servicio".
  * contiene `type`, `project_id`, `private_key`, `client_email`, etc.

Guarda cualquier archivo de credenciales (JSON, plist) fuera de repositorios
públicos y trata las claves como secretos. En CI puedes inyectar valores con
variables de entorno. Si necesitas regenerar la API key o el client ID, hazlo
desde la consola y vuelve a distribuir los archivos.

- **Control Anti-Fraude (BINing/Spoofing)**: El webhook `/payment` valida criptográficamente la petición usando el header `x-signature` (HMAC SHA256) firmado por MercadoPago con el `WEBHOOK_SECRET`. Rechaza peticiones mutadas, repetidas (control de idempotencia en Firestore) o donde el `transaction_amount` no coincide estrictamente con el mapa de precios definido en el backend. Los items no pueden ser inyectados desde el frontend.
- **Estructura de Beneficios Exclusivos y Costos**:
  1. *Unauth Gratis*: 5 Requests totales por huella/IP.
  2. *Auth Gratis (Registro)*: 10 Requests totales vinculados a la cuenta.
  3. *Pack Básico (Pago Único)*: **$15 MXN** = +50 Requests.
  4. *Pack Pro (Pago Único)*: **$25 MXN** = +100 Requests.
  5. *Auralix Premium (Suscripción)*: **$49 MXN / mes** = Requests ilimitados, insignias exclusivas, velocidad máxima, **aplicación 100% libre de anuncios**. Valida el claim `plan: premium` en DB.

## Cumplimiento General de Refactorización
Todos los bloqueos, controles, descargas adaptables de background y límites se aplican como fue ordenado en estricto cumplimiento de reestructuración nativa conservando las validaciones base del proyecto.
