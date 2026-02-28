Write-Host "=== Generando Sistema de Branding para Media Keep ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/5] Asegúrate de que Flutter no esté corriendo (presiona 'q' en la terminal actual si está activo)" -ForegroundColor Yellow
Read-Host "Presiona Enter cuando estés listo para continuar"

Write-Host "[2/5] Obteniendo dependencias..." -ForegroundColor Green
flutter pub get

Write-Host "[3/5] Generando íconos de la aplicación..." -ForegroundColor Green
flutter pub run flutter_launcher_icons

Write-Host "[4/5] Generando pantalla de carga (splash screen)..." -ForegroundColor Green
flutter pub run flutter_native_splash:create

Write-Host "[5/5] Limpiando proyecto..." -ForegroundColor Green
flutter clean

Write-Host ""
Write-Host "=== ¡Configuración completada! ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ahora ejecuta: flutter run" -ForegroundColor Yellow
Write-Host ""
Write-Host "Verifica:" -ForegroundColor White
Write-Host "  1. Ícono de la app en el launcher" -ForegroundColor White
Write-Host "  2. Pantalla de carga al abrir la app" -ForegroundColor White
Write-Host "  3. Quick Settings Tile con el logo correcto" -ForegroundColor White
