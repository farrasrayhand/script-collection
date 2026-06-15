# Script Fix Aplikasi Synchronizer - Final v5.7 (Animated Edition)
# Usage: powershell -ExecutionPolicy Bypass -Command "irm http://script.minicenter.my.id/synchronizer-fix.ps1 | iex"

$ErrorActionPreference = "Stop"
$env:ComSpec = "$env:SystemRoot\System32\cmd.exe"

# =============================================
# ANIMASI FUNCTIONS
# =============================================

function Show-Banner {
    Clear-Host
    $banner = @"

  ███████╗██╗   ██╗███╗   ██╗ ██████╗
  ██╔════╝╚██╗ ██╔╝████╗  ██║██╔════╝
  ███████╗ ╚████╔╝ ██╔██╗ ██║██║
  ╚════██║  ╚██╔╝  ██║╚██╗██║██║
  ███████║   ██║   ██║ ╚████║╚██████╗
  ╚══════╝   ╚═╝   ╚═╝  ╚═══╝ ╚═════╝
   SYNCHRONIZER FIX TOOL  v5.7 ANIMATED
"@
    Write-Host $banner -ForegroundColor Cyan
    Write-Host "  ════════════════════════════════════════" -ForegroundColor DarkCyan
    Write-Host "  minicenter.my.id" -ForegroundColor DarkGray
    Write-Host "  ════════════════════════════════════════" -ForegroundColor DarkCyan
    Write-Host ""
}

function Write-Typewriter {
    param(
        [string]$Text,
        [ConsoleColor]$Color = "White",
        [int]$Delay = 18
    )
    foreach ($char in $Text.ToCharArray()) {
        Write-Host $char -NoNewline -ForegroundColor $Color
        Start-Sleep -Milliseconds $Delay
    }
    Write-Host ""
}

function Show-Spinner {
    param(
        [string]$Message,
        [ScriptBlock]$Job,
        [int]$DelayMs = 80
    )
    $frames = @("⠋","⠙","⠹","⠸","⠼","⠴","⠦","⠧","⠇","⠏")
    $i = 0
    $done = $false

    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    $ps = [powershell]::Create()
    $ps.Runspace = $runspace
    [void]$ps.AddScript($Job)
    $handle = $ps.BeginInvoke()

    while (-not $handle.IsCompleted) {
        $frame = $frames[$i % $frames.Length]
        Write-Host "`r  $frame $Message   " -NoNewline -ForegroundColor Yellow
        Start-Sleep -Milliseconds $DelayMs
        $i++
    }

    $ps.EndInvoke($handle)
    $ps.Dispose()
    $runspace.Close()

    Write-Host "`r  ✔ $Message   " -ForegroundColor Green
}

function Show-ProgressBar {
    param(
        [string]$Label,
        [int]$DurationMs = 2000,
        [ConsoleColor]$Color = "Cyan"
    )
    $steps = 30
    $delay = [math]::Floor($DurationMs / $steps)
    Write-Host "  $Label" -ForegroundColor White
    Write-Host -NoNewline "  ["
    for ($i = 1; $i -le $steps; $i++) {
        $pct = [math]::Round(($i / $steps) * 100)
        Write-Host -NoNewline "█" -ForegroundColor $Color
        Write-Host "`r  [$("█" * $i)$("░" * ($steps - $i))] $pct%" -NoNewline -ForegroundColor $Color
        Start-Sleep -Milliseconds $delay
    }
    Write-Host "`r  [$("█" * $steps)] 100% ✔" -ForegroundColor Green
    Write-Host ""
}

function Write-Step {
    param([string]$Number, [string]$Title)
    Write-Host ""
    Write-Host "  ┌─────────────────────────────────────┐" -ForegroundColor DarkCyan
    Write-Host "  │  LANGKAH $Number — $Title" -ForegroundColor Cyan -NoNewline
    $pad = 38 - $Title.Length - $Number.Length - 12
    if ($pad -gt 0) { Write-Host (" " * $pad + "│") -ForegroundColor DarkCyan } else { Write-Host "  │" -ForegroundColor DarkCyan }
    Write-Host "  └─────────────────────────────────────┘" -ForegroundColor DarkCyan
    Write-Host ""
}

function Write-OK    { param([string]$msg) Write-Host "    ✔  $msg" -ForegroundColor Green }
function Write-WARN  { param([string]$msg) Write-Host "    ⚠  $msg" -ForegroundColor Yellow }
function Write-ERR   { param([string]$msg) Write-Host "    ✖  $msg" -ForegroundColor Red }
function Write-INFO  { param([string]$msg) Write-Host "    ▸  $msg" -ForegroundColor DarkGray }

function Show-Countdown {
    param([int]$Seconds = 3, [string]$Message = "Membuka browser")
    Write-Host ""
    for ($i = $Seconds; $i -ge 1; $i--) {
        Write-Host "`r  $Message dalam $i detik...  " -NoNewline -ForegroundColor DarkYellow
        Start-Sleep -Seconds 1
    }
    Write-Host "`r  $Message... GO!              " -ForegroundColor Green
    Write-Host ""
}

function Show-Done {
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "  ║                                      ║" -ForegroundColor Green
    Write-Host "  ║     ✔  SEMUA PERBAIKAN SELESAI!      ║" -ForegroundColor Green
    Write-Host "  ║                                      ║" -ForegroundColor Green
    Write-Host "  ╚══════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
}

# =============================================
# MULAI SCRIPT
# =============================================

Show-Banner
Start-Sleep -Milliseconds 400
Write-Typewriter "  Mempersiapkan perbaikan sistem..." -Color DarkCyan -Delay 20
Start-Sleep -Milliseconds 300

# --- Auto Self-Elevation ke Administrator ---
$currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host ""
    Write-Typewriter "  Bukan Administrator. Melakukan elevasi otomatis..." -Color Yellow -Delay 15

    if (-not $MyInvocation.MyCommand.Path) {
        $tempScript = "$env:TEMP\synchronizer-fix-temp.ps1"
        $MyInvocation.MyCommand.ScriptBlock | Out-File -FilePath $tempScript -Encoding UTF8
        $scriptPath = $tempScript
    } else {
        $scriptPath = $MyInvocation.MyCommand.Path
    }

    Start-Process PowerShell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`"" -Wait
    exit
}

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

Write-OK "Berjalan sebagai Administrator"
Start-Sleep -Milliseconds 300

# --- Langkah Awal: Cek Port 7008 ---
$basePath = "C:\synchronizer"
$folderAda = Test-Path $basePath

Write-Host ""
Write-INFO "Mengecek port 7008 (Apache)..."
Start-Sleep -Milliseconds 500
$portActive = Get-NetTCPConnection -LocalPort 7008 -ErrorAction SilentlyContinue
if ($portActive) { Write-OK "Port 7008 aktif." } else { Write-WARN "Port 7008 tidak aktif." }

# =============================================
# LANGKAH 1: Validasi Folder
# =============================================
Write-Step "1" "Validasi Folder Instalasi"

if (!$folderAda) {
    Write-WARN "Folder $basePath tidak ditemukan."
    Write-Host ""
    $sudahInstall = Read-Host "  Apakah Synchronizer sudah terinstall? (Y/N)"

    if ($sudahInstall -eq "Y" -or $sudahInstall -eq "y") {
        $basePath = Read-Host "  Masukkan path folder instalasi"
        if (!(Test-Path $basePath)) {
            Write-ERR "Folder '$basePath' tidak ditemukan. Script dihentikan."
            exit
        }
        Write-OK "Menggunakan folder: $basePath"
    } else {
        Write-Host ""
        Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "  ║  Silakan install Synchronizer terlebih dahulu.           ║" -ForegroundColor White
        Write-Host "  ║  Download: https://drive.google.com/file/d/1jeMvOj...    ║" -ForegroundColor Cyan
        Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host ""
        Write-WARN "Setelah install, jalankan kembali script ini."
        Start-Process "https://drive.google.com/file/d/1jeMvOjcylFcYJBHux57Fz8S4lhZf849Y/view"
        exit
    }
} else {
    Write-OK "Folder ditemukan: $basePath"
}

$phpDir     = "$basePath\php"
$phpIni     = "$phpDir\php.ini"
$phpExeDest = "$basePath\dataweb\php.exe"
$phpIniDest = "$basePath\dataweb\php.ini"

# =============================================
# LANGKAH 2: Hentikan Proses
# =============================================
Write-Step "2" "Menghentikan Proses Aktif"

$processesToKill = @("php", "synchronizer", "node")
foreach ($proc in $processesToKill) {
    $running = Get-Process -Name $proc -ErrorAction SilentlyContinue
    if ($running) {
        Show-Spinner -Message "Menghentikan proses: $proc" -Job { Stop-Process -Name $proc -Force -ErrorAction SilentlyContinue }
    } else {
        Write-INFO "Proses $proc tidak berjalan, dilewati."
    }
}

Show-ProgressBar -Label "Menunggu proses berhenti sepenuhnya..." -DurationMs 3000 -Color DarkYellow

# =============================================
# LANGKAH 3: Chocolatey & Git
# =============================================
Write-Step "3" "Persiapan Package Manager"

if (!(Test-Path "C:\ProgramData\chocolatey\bin\choco.exe")) {
    Write-Typewriter "  Menginstal Chocolatey..." -Color Yellow -Delay 12
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
} else {
    Write-OK "Chocolatey sudah terinstall."
}

$env:Path = "C:\ProgramData\chocolatey\bin;" + $env:Path
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
Write-OK "Environment Path diperbarui."

if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    Show-Spinner -Message "Menginstal Git..." -Job {
        & "C:\ProgramData\chocolatey\bin\choco.exe" install git -y | Out-Null
    }
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
} else {
    Write-OK "Git sudah terinstall."
}

# =============================================
# LANGKAH 4: Konfigurasi Git
# =============================================
Write-Step "4" "Konfigurasi Git"

if (Get-Command git -ErrorAction SilentlyContinue) {
    $gitConfigs = @(
        @("core.autocrlf", "false"),
        @("advice.detachedHead", "false"),
        @("core.fileMode", "false")
    )
    foreach ($cfg in $gitConfigs) {
        & git config --global $cfg[0] $cfg[1]
        Write-OK "git config $($cfg[0]) = $($cfg[1])"
        Start-Sleep -Milliseconds 120
    }
    & git config --global --add safe.directory "$basePath/dataweb"
    Write-OK "safe.directory ditambahkan."
}
$env:GIT_TERMINAL_PROMPT = "0"
$env:GIT_ASK_YESNO = "false"

# =============================================
# LANGKAH 5: Fix PHP
# =============================================
Write-Step "5" "Perbaikan PHP"

Write-INFO "Menghapus php.exe lama dari dataweb..."
if (Test-Path $phpExeDest) {
    Remove-Item $phpExeDest -Force -ErrorAction SilentlyContinue
    Write-OK "php.exe lama dihapus."
}

Show-ProgressBar -Label "Menyalin php.exe ke dataweb..." -DurationMs 1200 -Color Cyan
if (Test-Path "$phpDir\php.exe") {
    Copy-Item "$phpDir\php.exe" -Destination $phpExeDest -Force
    Write-OK "php.exe disalin."
} else {
    Write-WARN "php.exe tidak ditemukan di $phpDir"
}

if (Test-Path $phpIni) {
    Copy-Item $phpIni -Destination $phpIniDest -Force
    Write-OK "php.ini disalin."
} else {
    Write-WARN "php.ini tidak ditemukan di $phpDir"
}

Write-INFO "Memverifikasi ekstensi PHP..."
Start-Sleep -Milliseconds 400
if (Test-Path $phpExeDest) {
    $phpModules = & $phpExeDest -m 2>&1
    if ($phpModules -match "pdo_sqlite") { Write-OK "Ekstensi pdo_sqlite aktif." } else { Write-WARN "pdo_sqlite belum terdeteksi." }
    if ($phpModules -match "openssl")    { Write-OK "Ekstensi openssl aktif."    } else { Write-WARN "openssl belum terdeteksi."    }
}

# =============================================
# LANGKAH 6: Composer & Laravel Update
# =============================================
Write-Step "6" "Fix Composer & Laravel Update"

if (Test-Path "$basePath\dataweb\vendor") {
    Show-Spinner -Message "Menghapus folder vendor lama..." -Job {
        Remove-Item "$basePath\dataweb\vendor" -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if (Test-Path "$basePath\updater") {
    Set-Location "$basePath\updater"

    Write-Typewriter "  Menjalankan composer.bat..." -Color Yellow -Delay 14
    Start-Process -FilePath "$env:ComSpec" -ArgumentList "/c composer.bat" -Wait -NoNewWindow

    Write-Typewriter "  Menjalankan updater.bat (Git pull)..." -Color Yellow -Delay 14
    Start-Process -FilePath "$env:ComSpec" -ArgumentList "/c updater.bat" -Wait -NoNewWindow

    Write-OK "Langkah 6 selesai."
}

# =============================================
# LANGKAH 7: Re-copy PHP setelah Git pull
# =============================================
Write-Step "7" "Re-sinkronisasi PHP Pasca Git Pull"

Show-ProgressBar -Label "Menyinkronisasi ulang php.exe & php.ini..." -DurationMs 1500 -Color Magenta

if (Test-Path "$phpDir\php.exe") {
    Copy-Item "$phpDir\php.exe" -Destination $phpExeDest -Force
    Write-OK "php.exe di-refresh."
}
if (Test-Path $phpIni) {
    Copy-Item $phpIni -Destination $phpIniDest -Force
    Write-OK "php.ini di-refresh."
}

# =============================================
# LANGKAH 8: Node.js & NPM Build
# =============================================
Write-Step "8" "Fix Node.js & NPM Build"

Write-Typewriter "  Menginstal Node.js v24.15.0 via Chocolatey..." -Color Yellow -Delay 12
& "C:\ProgramData\chocolatey\bin\choco.exe" install nodejs --version="24.15.0" -y --force --force-dependencies | Out-Null
Write-OK "Node.js terinstall."

$env:Path = "$env:ProgramFiles\nodejs;" + [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

$npmScriptPath = "$basePath\run_npm.bat"
$npmContent = @"
@echo off
set "PATH=%PATH%;%ProgramFiles%\nodejs;C:\ProgramData\chocolatey\bin;%ProgramFiles%\Git\cmd"
cd /d "$basePath\dataweb"
echo Mengecek versi Node:
node -v
if errorlevel 1 (
    echo ERROR: Node.js tidak terdeteksi! Pastikan Node.js sudah terinstall.
    pause
    exit /b 1
)
echo Membersihkan cache...
call npm cache clean --force
echo Memulai npm install...
call npm install --legacy-peer-deps
echo Memulai npm run build...
call npm run build
echo.
echo Proses Build Selesai!
timeout /t 3
exit
"@
$npmContent | Out-File $npmScriptPath -Encoding ASCII

Write-Typewriter "  Menjalankan npm install & build..." -Color Yellow -Delay 14
Start-Process -FilePath "$env:ComSpec" -ArgumentList "/c $npmScriptPath" -Wait

Write-OK "NPM build selesai."

# =============================================
# SELESAI
# =============================================
Show-Done
Show-Countdown -Seconds 3 -Message "Membuka aplikasi di browser"
Start-Process "http://localhost:7008"
