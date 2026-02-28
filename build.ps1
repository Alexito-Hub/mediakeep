# ===========================================================================
# MediaKeep Build Tool - Script Unificado
# ===========================================================================
# Este script maneja versionamiento automatico y builds para todas las plataformas
#
# Uso:
#   .\build.ps1                    # Muestra menu interactivo
#   .\build.ps1 android            # Build Android
#   .\build.ps1 windows            # Build Windows
#   .\build.ps1 web                # Build Web
#   .\build.ps1 ios                # Build iOS (requiere macOS)
#   .\build.ps1 linux              # Build Linux
#   .\build.ps1 all                # Build todas las plataformas disponibles
#   .\build.ps1 version            # Solo incrementar version
#   .\build.ps1 version -Major     # Incrementar version major
#   .\build.ps1 version -Minor     # Incrementar version minor
#   .\build.ps1 version -Patch     # Incrementar version patch
# ===========================================================================

param(
    [Parameter(Position=0)]
    [ValidateSet('android', 'windows', 'ios', 'linux', 'web', 'all', 'version', '')]
    [string]$Command = '',
    
    [switch]$Major,
    [switch]$Minor,
    [switch]$Patch,
    [switch]$SkipVersion
)

# ===========================================================================
# CONFIGURACION
# ===========================================================================

$script:PubspecPath = "pubspec.yaml"

# ===========================================================================
# FUNCIONES DE UTILIDAD
# ===========================================================================

function Show-Banner {
    $banner = @"

==============================================
           MediaKeep Build Tool
        Versionamiento Automatico
==============================================

"@
    Write-Host $banner -ForegroundColor Cyan
}

function Show-Menu {
    Write-Host "Selecciona una opcion:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1] Build Android APK" -ForegroundColor Green
    Write-Host "  [2] Build Windows" -ForegroundColor Green
    Write-Host "  [3] Build Web" -ForegroundColor Green
    Write-Host "  [4] Build iOS (requiere macOS)" -ForegroundColor Green
    Write-Host "  [5] Build Linux" -ForegroundColor Green
    Write-Host "  [6] Solo incrementar version" -ForegroundColor Cyan
    Write-Host "  [7] Build TODAS las plataformas" -ForegroundColor Magenta
    Write-Host "  [0] Salir" -ForegroundColor Red
    Write-Host ""
    
    $choice = Read-Host "Opcion"
    
    switch ($choice) {
        "1" { return "android" }
        "2" { return "windows" }
        "3" { return "web" }
        "4" { return "ios" }
        "5" { return "linux" }
        "6" { return "version" }
        "7" { return "all" }
        "0" { exit 0 }
        default { 
            Write-Host "[ERROR] Opcion invalida" -ForegroundColor Red
            return $null
        }
    }
}

# ===========================================================================
# FUNCIONES DE VERSIONAMIENTO
# ===========================================================================

function Get-CurrentVersion {
    if (!(Test-Path $script:PubspecPath)) {
        Write-Host "[ERROR] No se encontro pubspec.yaml" -ForegroundColor Red
        exit 1
    }
    
    $content = Get-Content $script:PubspecPath -Raw
    
    if ($content -match 'version:\s+(\d+)\.(\d+)\.(\d+)\+(\d+)') {
        return @{
            Major = [int]$matches[1]
            Minor = [int]$matches[2]
            Patch = [int]$matches[3]
            Build = [int]$matches[4]
            Full = "$($matches[1]).$($matches[2]).$($matches[3])+$($matches[4])"
        }
    }
    
    Write-Host "[ERROR] No se encontro version en pubspec.yaml" -ForegroundColor Red
    exit 1
}

function Set-Version {
    param(
        [int]$Major,
        [int]$Minor,
        [int]$Patch,
        [int]$Build
    )
    
    $content = Get-Content $script:PubspecPath -Raw
    $newVersion = "$Major.$Minor.$Patch+$Build"
    $newContent = $content -replace "version:\s+\d+\.\d+\.\d+\+\d+", "version: $newVersion"
    $newContent | Set-Content $script:PubspecPath -NoNewline
    
    return $newVersion
}

function Invoke-IncrementVersion {
    param(
        [switch]$Major,
        [switch]$Minor,
        [switch]$Patch
    )
    
    $current = Get-CurrentVersion
    $oldVersion = $current.Full
    
    if ($Major) {
        $current.Major++
        $current.Minor = 0
        $current.Patch = 0
        $current.Build = 1
        $type = "MAJOR"
    }
    elseif ($Minor) {
        $current.Minor++
        $current.Patch = 0
        $current.Build = 1
        $type = "MINOR"
    }
    elseif ($Patch) {
        $current.Patch++
        $current.Build = 1
        $type = "PATCH"
    }
    else {
        $current.Build++
        $type = "BUILD"
    }
    
    $newVersion = Set-Version -Major $current.Major -Minor $current.Minor -Patch $current.Patch -Build $current.Build
    
    Write-Host "[VERSION] Incrementando version $type" -ForegroundColor Cyan
    Write-Host "          Anterior: $oldVersion" -ForegroundColor Yellow
    Write-Host "          Nueva:    $newVersion" -ForegroundColor Green
    
    return $newVersion
}

# ===========================================================================
# FUNCIONES DE BUILD
# ===========================================================================

function Invoke-BuildPreparation {
    Write-Host ""
    Write-Host "[PREP] Limpiando build anterior..." -ForegroundColor Cyan
    flutter clean 2>&1 | Out-Null
    
    Write-Host "[PREP] Obteniendo dependencias..." -ForegroundColor Cyan
    flutter pub get 2>&1 | Out-Null
    Write-Host ""
}

function Invoke-BuildAndroid {
    Write-Host "==============================================" -ForegroundColor Magenta
    Write-Host "           BUILD ANDROID APK" -ForegroundColor Magenta
    Write-Host "==============================================" -ForegroundColor Magenta
    
    if (-not $SkipVersion) {
        Write-Host ""
        Invoke-IncrementVersion
    }
    
    Invoke-BuildPreparation
    
    Write-Host "[BUILD] Compilando APK Release..." -ForegroundColor Cyan
    flutter build apk --release
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "==============================================" -ForegroundColor Green
        Write-Host " [OK] BUILD EXITOSO - Android APK" -ForegroundColor Green
        Write-Host "==============================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "[INFO] Ubicacion: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Yellow
        
        $apkPath = "build\app\outputs\flutter-apk\app-release.apk"
        if (Test-Path $apkPath) {
            $size = (Get-Item $apkPath).Length / 1MB
            $sizeRounded = [math]::Round($size, 2)
            Write-Host "[INFO] Tamaño: $sizeRounded MB" -ForegroundColor Cyan
        }
        return $true
    }
    
    Write-Host ""
    Write-Host "[ERROR] BUILD FALLO" -ForegroundColor Red
    return $false
}

function Invoke-BuildWindows {
    Write-Host "==============================================" -ForegroundColor Magenta
    Write-Host "           BUILD WINDOWS" -ForegroundColor Magenta
    Write-Host "==============================================" -ForegroundColor Magenta
    
    if (-not $SkipVersion) {
        Write-Host ""
        Invoke-IncrementVersion
    }
    
    Invoke-BuildPreparation
    
    Write-Host "[BUILD] Compilando aplicacion Windows..." -ForegroundColor Cyan
    flutter build windows --release
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "==============================================" -ForegroundColor Green
        Write-Host " [OK] BUILD EXITOSO - Windows" -ForegroundColor Green
        Write-Host "==============================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "[INFO] Ubicacion: build\windows\x64\runner\Release\" -ForegroundColor Yellow
        
        $buildPath = "build\windows\x64\runner\Release"
        if (Test-Path $buildPath) {
            $exeFile = Get-ChildItem "$buildPath\*.exe" | Select-Object -First 1
            if ($exeFile) {
                $size = $exeFile.Length / 1MB
                $sizeRounded = [math]::Round($size, 2)
                Write-Host "[INFO] Ejecutable: $($exeFile.Name) ($sizeRounded MB)" -ForegroundColor Cyan
            }
        }
        return $true
    }
    
    Write-Host ""
    Write-Host "[ERROR] BUILD FALLO" -ForegroundColor Red
    return $false
}

function Invoke-BuildWeb {
    Write-Host "==============================================" -ForegroundColor Magenta
    Write-Host "              BUILD WEB" -ForegroundColor Magenta
    Write-Host "==============================================" -ForegroundColor Magenta
    
    if (-not $SkipVersion) {
        Write-Host ""
        Invoke-IncrementVersion
    }
    
    Invoke-BuildPreparation
    
    Write-Host "[BUILD] Compilando aplicacion Web..." -ForegroundColor Cyan
    flutter build web --release
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "==============================================" -ForegroundColor Green
        Write-Host " [OK] BUILD EXITOSO - Web" -ForegroundColor Green
        Write-Host "==============================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "[INFO] Ubicacion: build\web\" -ForegroundColor Yellow
        
        $buildPath = "build\web"
        if (Test-Path $buildPath) {
            $totalSize = (Get-ChildItem $buildPath -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
            $totalSizeRounded = [math]::Round($totalSize, 2)
            Write-Host "[INFO] Tamaño total: $totalSizeRounded MB" -ForegroundColor Cyan
        }
        
        Write-Host ""
        Write-Host "[INFO] Para desplegar: Sube el contenido de build\web\ a tu servidor" -ForegroundColor Cyan
        return $true
    }
    
    Write-Host ""
    Write-Host "[ERROR] BUILD FALLO" -ForegroundColor Red
    return $false
}

function Invoke-BuildIOS {
    Write-Host "==============================================" -ForegroundColor Magenta
    Write-Host "              BUILD iOS" -ForegroundColor Magenta
    Write-Host "==============================================" -ForegroundColor Magenta
    
    if (-not $IsMacOS -and $IsWindows) {
        Write-Host ""
        Write-Host "[WARN] iOS solo puede compilarse en macOS con Xcode" -ForegroundColor Yellow
        Write-Host "       No puedes compilar iOS desde Windows" -ForegroundColor Yellow
        Write-Host ""
        return $false
    }
    
    if (-not $SkipVersion) {
        Write-Host ""
        Invoke-IncrementVersion
    }
    
    Invoke-BuildPreparation
    
    Write-Host "[PREP] Instalando CocoaPods..." -ForegroundColor Cyan
    Push-Location ios
    pod install | Out-Null
    Pop-Location
    
    Write-Host "[BUILD] Compilando aplicacion iOS (sin codesign)..." -ForegroundColor Cyan
    flutter build ios --release --no-codesign
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "==============================================" -ForegroundColor Green
        Write-Host " [OK] BUILD EXITOSO - iOS" -ForegroundColor Green
        Write-Host "==============================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "[INFO] Ubicacion: build/ios/iphoneos/Runner.app" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "[INFO] Para firmar: Abre ios/Runner.xcworkspace en Xcode" -ForegroundColor Cyan
        return $true
    }
    
    Write-Host ""
    Write-Host "[ERROR] BUILD FALLO" -ForegroundColor Red
    return $false
}

function Invoke-BuildLinux {
    Write-Host "==============================================" -ForegroundColor Magenta
    Write-Host "             BUILD LINUX" -ForegroundColor Magenta
    Write-Host "==============================================" -ForegroundColor Magenta
    
    if (-not $IsLinux -and $IsWindows) {
        Write-Host ""
        Write-Host "[WARN] Linux debe compilarse en Linux o WSL2" -ForegroundColor Yellow
        Write-Host "       No puedes compilar Linux directamente desde Windows" -ForegroundColor Yellow
        Write-Host ""
        return $false
    }
    
    if (-not $SkipVersion) {
        Write-Host ""
        Invoke-IncrementVersion
    }
    
    Invoke-BuildPreparation
    
    Write-Host "[BUILD] Compilando aplicacion Linux..." -ForegroundColor Cyan
    flutter build linux --release
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "==============================================" -ForegroundColor Green
        Write-Host " [OK] BUILD EXITOSO - Linux" -ForegroundColor Green
        Write-Host "==============================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "[INFO] Ubicacion: build/linux/x64/release/bundle/" -ForegroundColor Yellow
        return $true
    }
    
    Write-Host ""
    Write-Host "[ERROR] BUILD FALLO" -ForegroundColor Red
    return $false
}

function Invoke-BuildAll {
    Write-Host "==============================================" -ForegroundColor Magenta
    Write-Host "      BUILD TODAS LAS PLATAFORMAS" -ForegroundColor Magenta
    Write-Host "==============================================" -ForegroundColor Magenta
    Write-Host ""
    
    # Incrementar version una sola vez
    if (-not $SkipVersion) {
        Invoke-IncrementVersion
    }
    
    $platforms = @('android', 'windows', 'web')
    $results = @{}
    
    foreach ($platform in $platforms) {
        Write-Host ""
        Write-Host "----------------------------------------------" -ForegroundColor DarkGray
        
        $script:SkipVersion = $true  # Ya incrementamos la version
        
        switch ($platform) {
            'android' { $results[$platform] = Invoke-BuildAndroid }
            'windows' { $results[$platform] = Invoke-BuildWindows }
            'web'     { $results[$platform] = Invoke-BuildWeb }
        }
        
        Write-Host ""
    }
    
    # Resumen
    Write-Host "==============================================" -ForegroundColor Magenta
    Write-Host "         RESUMEN DE BUILDS" -ForegroundColor Magenta
    Write-Host "==============================================" -ForegroundColor Magenta
    foreach ($platform in $results.Keys | Sort-Object) {
        $status = if ($results[$platform]) { "[OK] EXITOSO" } else { "[X] FALLIDO" }
        $color = if ($results[$platform]) { "Green" } else { "Red" }
        Write-Host "  $($platform.ToUpper().PadRight(10)): $status" -ForegroundColor $color
    }
    Write-Host "==============================================" -ForegroundColor Magenta
}

# ===========================================================================
# PROGRAMA PRINCIPAL
# ===========================================================================

Show-Banner

# Si no se proporciono comando, mostrar menu
if ([string]::IsNullOrEmpty($Command)) {
    $Command = Show-Menu
    if ($null -eq $Command) {
        exit 1
    }
}

# Ejecutar comando
switch ($Command) {
    'version' {
        Write-Host "[VERSION] Incrementando version..." -ForegroundColor Cyan
        Write-Host ""
        Invoke-IncrementVersion -Major:$Major -Minor:$Minor -Patch:$Patch
        Write-Host ""
    }
    'android' { Invoke-BuildAndroid | Out-Null }
    'windows' { Invoke-BuildWindows | Out-Null }
    'web'     { Invoke-BuildWeb | Out-Null }
    'ios'     { Invoke-BuildIOS | Out-Null }
    'linux'   { Invoke-BuildLinux | Out-Null }
    'all'     { Invoke-BuildAll }
    default {
        Write-Host "[ERROR] Comando desconocido: $Command" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Hecho!" -ForegroundColor Green
