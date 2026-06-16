# Script Fix Aplikasi Synchronizer - Final v6.0
# Fitur: Unicode Auto-Detect, Animasi Terminal, Auto Elevation,
# 		Auto Download + Install, Prerequisites Checker (VC++, .NET, WebView2)
# Usage: powershell -ExecutionPolicy Bypass -Command "irm http://script.minicenter.my.id/scripts/synchronizer-fix.ps1 | iex"
$ErrorActionPreference = "Stop"
$env:ComSpec = "$env:SystemRoot\System32\cmd.exe"

# =============================================
# DETEKSI UNICODE SUPPORT
# =============================================

function Test-UnicodeSupport {
    # Cek 1: Apakah terminal bisa render Unicode (Windows Terminal, VS Code, dll)
    $wtSession   = $env:WT_SESSION        # Windows Terminal
    $vscode      = $env:TERM_PROGRAM      # VS Code terminal
    $conEmu      = $env:ConEmuPID         # ConEmu / Cmder

    if ($wtSession -or $vscode -or $conEmu) { return $true }

    # Cek 2: PowerShell ISE
    if ($host.Name -eq "Windows PowerShell ISE Host") { return $true }

    # Cek 3: Font terminal support Powerline/Unicode (Consolas, Cascadia, dll)
    try {
        $fontName = (Get-ItemProperty "HKCU:\Console").FaceName 2>$null
        $unicodeFonts = @("Cascadia", "Nerd Font", "FiraCode", "JetBrains", "Lucida Console", "NSimSun", "MS Gothic")
        foreach ($f in $unicodeFonts) {
            if ($fontName -like "*$f*") { return $true }
        }
    } catch {}

    # Cek 4: Test tulis karakter Unicode dan baca kembali — kalau tidak error, support
    try {
        $testChar = [char]0x2714  # karakter: checkmark
        $encoded  = [System.Text.Encoding]::UTF8.GetBytes($testChar)
        $decoded  = [System.Text.Encoding]::UTF8.GetString($encoded)
        if ($decoded -eq $testChar) {
            # Coba set UTF-8, kalau berhasil kemungkinan besar support
            $prev = [Console]::OutputEncoding
            [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
            chcp 65001 2>&1 | Out-Null
            # Jika codepage berhasil di-set ke 65001, anggap support
            $cp = (chcp) -replace '[^0-9]', ''
            if ($cp -eq "65001") { return $true }
            [Console]::OutputEncoding = $prev
        }
    } catch {}

    return $false
}

$UNICODE = Test-UnicodeSupport

if ($UNICODE) {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    chcp 65001 | Out-Null

    # Karakter set Unicode
    $CH = @{
        OK      = "[OK]"
        WARN    = "[!!]"
        ERR     = "[XX]"
        INFO    = "[..]"
        LINE    = [string][char]0x2550  # ═
        TL      = [string][char]0x2554  # ╔
        TR      = [string][char]0x2557  # ╗
        BL      = [string][char]0x255A  # ╚
        BR      = [string][char]0x255D  # ╝
        SIDE    = [string][char]0x2551  # ║
        HLINE   = [string][char]0x2500  # ─
        LT      = [string][char]0x250C  # ┌
        RT      = [string][char]0x2510  # ┐
        LB      = [string][char]0x2514  # └
        RB      = [string][char]0x2518  # ┘
        SPIN    = @([string][char]0x280B,[string][char]0x2819,[string][char]0x2839,[string][char]0x2838,
                    [string][char]0x283C,[string][char]0x2834,[string][char]0x2826,[string][char]0x2827,
                    [string][char]0x2807,[string][char]0x280F)
        BLOCK   = [string][char]0x2588  # █
        EMPTY   = [string][char]0x2591  # ░
        ARROW   = ">>"
        CHECK   = [string][char]0x2714  # ✔
        CROSS   = [string][char]0x2718  # ✘
        BANG    = [string][char]0x26A0  # ⚠
        DOT     = [string][char]0x25B8  # ▸
    }
} else {
    # Karakter set ASCII murni (CMD lama / font tidak support)
    $CH = @{
        OK      = "[OK]"
        WARN    = "[!!]"
        ERR     = "[XX]"
        INFO    = "[..]"
        LINE    = "="
        TL      = "+"
        TR      = "+"
        BL      = "+"
        BR      = "+"
        SIDE    = "|"
        HLINE   = "-"
        LT      = "+"
        RT      = "+"
        LB      = "+"
        RB      = "+"
        SPIN    = @("-", "\", "|", "/")
        BLOCK   = "#"
        EMPTY   = "-"
        ARROW   = ">>"
        CHECK   = "OK"
        CROSS   = "XX"
        BANG    = "!!"
        DOT     = ">>"
    }
}

# =============================================
# ANIMASI FUNCTIONS
# =============================================

function Show-Banner {
    Clear-Host
    Write-Host ""
    if ($UNICODE) {
        $top    = $CH.TL + ($CH.LINE * 42) + $CH.TR
        $bottom = $CH.BL + ($CH.LINE * 42) + $CH.BR
        $mid    = $CH.SIDE
        Write-Host "  $top" -ForegroundColor Cyan
        Write-Host "  $mid                                          $mid" -ForegroundColor Cyan
        Write-Host "  $mid   SYNCHRONIZER FIX TOOL  v5.7 ANIMATED  $mid" -ForegroundColor White
        Write-Host "  $mid                                          $mid" -ForegroundColor Cyan
        Write-Host "  $mid          minicenter.my.id                $mid" -ForegroundColor DarkGray
        Write-Host "  $mid                                          $mid" -ForegroundColor Cyan
        Write-Host "  $bottom" -ForegroundColor Cyan
    } else {
        Write-Host "  #####  #   #  #   #  #####" -ForegroundColor Cyan
        Write-Host "  #       # #   ##  #  #    " -ForegroundColor Cyan
        Write-Host "  ####     #    # # #  ####  " -ForegroundColor Cyan
        Write-Host "  #       # #   #  ##  #    " -ForegroundColor Cyan
        Write-Host "  #####  #   #  #   #  #####" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  SYNCHRONIZER FIX TOOL  v5.7 ANIMATED" -ForegroundColor White
        Write-Host "  ======================================" -ForegroundColor DarkCyan
        Write-Host "  minicenter.my.id" -ForegroundColor DarkGray
        Write-Host "  ======================================" -ForegroundColor DarkCyan
    }
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
        [int]$DelayMs = 100
    )
    $frames = $CH.SPIN
    $i = 0

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

    Write-Host "`r  $($CH.CHECK) $Message   " -ForegroundColor Green
}

function Show-ProgressBar {
    param(
        [string]$Label,
        [int]$DurationMs = 2000,
        [ConsoleColor]$Color = "Cyan"
    )
    $steps = 30
    $delay = [math]::Max(1, [math]::Floor($DurationMs / $steps))
    Write-Host "  $Label" -ForegroundColor White
    for ($i = 1; $i -le $steps; $i++) {
        $pct   = [math]::Round(($i / $steps) * 100)
        $bar   = $CH.BLOCK * $i
        $rest  = $CH.EMPTY * ($steps - $i)
        Write-Host "`r  [$bar$rest] $pct%  " -NoNewline -ForegroundColor $Color
        Start-Sleep -Milliseconds $delay
    }
    Write-Host "`r  [$($CH.BLOCK * $steps)] 100% $($CH.CHECK) DONE!  " -ForegroundColor Green
    Write-Host ""
}

function Write-Step {
    param([string]$Number, [string]$Title)
    $line = $CH.LINE * 38
    Write-Host ""
    Write-Host "  $($CH.TL)$line$($CH.TR)" -ForegroundColor DarkCyan
    $label = "  $($CH.SIDE) $($CH.ARROW) LANGKAH $Number -- $Title"
    $pad   = 40 - $label.Length + 4
    if ($pad -lt 1) { $pad = 1 }
    Write-Host "$label$(' ' * $pad)$($CH.SIDE)" -ForegroundColor Cyan
    Write-Host "  $($CH.BL)$line$($CH.BR)" -ForegroundColor DarkCyan
    Write-Host ""
}

function Write-OK   { param([string]$msg) Write-Host "  $($CH.CHECK) $msg" -ForegroundColor Green }
function Write-WARN { param([string]$msg) Write-Host "  $($CH.BANG)  $msg" -ForegroundColor Yellow }
function Write-ERR  { param([string]$msg) Write-Host "  $($CH.CROSS) $msg" -ForegroundColor Red }
function Write-INFO { param([string]$msg) Write-Host "  $($CH.DOT)   $msg" -ForegroundColor DarkGray }

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
    $line = $CH.LINE * 40
    Write-Host ""
    Write-Host "  $($CH.TL)$line$($CH.TR)" -ForegroundColor Green
    Write-Host "  $($CH.SIDE)                                          $($CH.SIDE)" -ForegroundColor Green
    Write-Host "  $($CH.SIDE)   $($CH.CHECK)  SEMUA PERBAIKAN SELESAI!           $($CH.SIDE)" -ForegroundColor Green
    Write-Host "  $($CH.SIDE)                                          $($CH.SIDE)" -ForegroundColor Green
    Write-Host "  $($CH.BL)$line$($CH.BR)" -ForegroundColor Green
    Write-Host ""
}

# =============================================
# MULAI SCRIPT
# =============================================

Show-Banner

if ($UNICODE) {
    Write-INFO "Mode Unicode aktif - terminal support terdeteksi"
} else {
    Write-INFO "Mode ASCII - terminal lama/CMD standar terdeteksi"
}

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

# --- Cek Port 7008 ---
Write-Host ""
Write-INFO "Mengecek port 7008 (Apache)..."
Start-Sleep -Milliseconds 500
$portActive = Get-NetTCPConnection -LocalPort 7008 -ErrorAction SilentlyContinue
if ($portActive) { Write-OK "Port 7008 aktif." } else { Write-WARN "Port 7008 tidak aktif." }

$basePath = "C:\synchronizer"
$folderAda = Test-Path $basePath

# =============================================
# LANGKAH 1
# =============================================
Write-Step "1" "Validasi Folder Instalasi"

if (!$folderAda) {
    Write-WARN "Folder default $basePath tidak ditemukan."
    Write-Host ""

    # Fungsi: verifikasi folder benar-benar Synchronizer (bukan e-Rapor/Apache lain)
    # Penanda unik: data_sync.json, SyncSession.php, atau folder updater
    function Test-IsSynchronizer {
        param([string]$path)
        if ([string]::IsNullOrWhiteSpace($path)) { return $false }
        $markers = @(
            "$path\dataweb\data_sync.json",
            "$path\dataweb\app\Models\SyncSession.php",
            "$path\updater\updater.bat"
        )
        $found = 0
        foreach ($m in $markers) {
            if (Test-Path $m) { $found++ }
        }
        # Minimal 1 penanda unik harus ada
        return ($found -ge 1)
    }

    $folderDitemukan = $false

    if ($portActive) {
        # Port aktif tapi folder default tidak ada = mungkin install di folder custom
        Write-INFO "Port 7008 aktif - mencari folder instalasi dari proses Apache..."

        # Ambil PID yang listen di port 7008, lalu path executable-nya
        try {
            $conn = Get-NetTCPConnection -LocalPort 7008 -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($conn) {
                $procPath = (Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue).Path
                if ($procPath) {
                    Write-INFO "Proses ditemukan: $procPath"
                    # httpd.exe biasanya di <basePath>\apache\bin\httpd.exe atau <basePath>\bin\httpd.exe
                    # Naik folder sampai ketemu struktur Synchronizer
                    $candidate = Split-Path $procPath -Parent
                    for ($i = 0; $i -lt 5; $i++) {
                        $candidate = Split-Path $candidate -Parent
                        if ([string]::IsNullOrWhiteSpace($candidate)) { break }
                        if (Test-IsSynchronizer $candidate) {
                            $basePath = $candidate
                            $folderDitemukan = $true
                            Write-OK "Folder Synchronizer terverifikasi: $basePath"
                            break
                        }
                    }
                }
            }
        } catch {
            Write-WARN "Gagal deteksi otomatis dari proses: $_"
        }

        # Kalau auto-detect gagal, scan drive umum
        if (-not $folderDitemukan) {
            Write-INFO "Auto-detect dari proses gagal, memindai lokasi umum..."
            $commonPaths = @(
                "C:\synchronizer", "D:\synchronizer", "E:\synchronizer",
                "C:\e-Rapor SMK Synchronizer", "D:\e-Rapor SMK Synchronizer",
                "$env:ProgramFiles\synchronizer", "${env:ProgramFiles(x86)}\synchronizer"
            )
            foreach ($p in $commonPaths) {
                if (Test-IsSynchronizer $p) {
                    $basePath = $p
                    $folderDitemukan = $true
                    Write-OK "Folder Synchronizer ditemukan: $basePath"
                    break
                }
            }
        }

        # Kalau tetap tidak ketemu, baru tanya manual (last resort)
        if (-not $folderDitemukan) {
            Write-WARN "Folder Synchronizer tidak terdeteksi otomatis."
            $inputPath = Read-Host "  Masukkan path folder instalasi Synchronizer (atau ketik SKIP untuk install ulang)"
            if ($inputPath -eq "SKIP" -or $inputPath -eq "skip") {
                $portActive = $false  # paksa masuk ke jalur install
            } elseif (Test-IsSynchronizer $inputPath) {
                $basePath = $inputPath
                $folderDitemukan = $true
                Write-OK "Folder Synchronizer terverifikasi: $basePath"
            } else {
                Write-ERR "Folder '$inputPath' bukan instalasi Synchronizer yang valid."
                Write-WARN "Tidak ditemukan penanda (data_sync.json / updater.bat)."
                pause
                exit
            }
        }

        if ($folderDitemukan) {
            $folderAda = $true
        }
    }

    if (-not $portActive -and -not $folderDitemukan) {
        # Port tidak aktif = belum install sama sekali
        Write-INFO "Port 7008 tidak aktif - Synchronizer belum terinstall."
        Write-INFO "Memulai proses instalasi otomatis..."
        Write-Host ""

    # --- Auto Download + Silent Install ---
    $installerUrl  = "https://github.com/farrasrayhand/script-collection/releases/download/v.2/e-Rapor.SMK.Synchronizer.exe"
    $installerPath = "$env:TEMP\e-Rapor_SMK_Synchronizer.exe"

    Write-Host ""
    Write-Host "  $($CH.TL)$($CH.LINE * 52)$($CH.TR)" -ForegroundColor Cyan
    Write-Host "  $($CH.SIDE)  Synchronizer belum terinstall.                        $($CH.SIDE)" -ForegroundColor White
    Write-Host "  $($CH.SIDE)  Akan didownload dan diinstall otomatis...             $($CH.SIDE)" -ForegroundColor Cyan
    Write-Host "  $($CH.BL)$($CH.LINE * 52)$($CH.BR)" -ForegroundColor Cyan
    Write-Host ""

    # -----------------------------------------------
    # PREREQUISITES - Install sebelum installer utama
    # -----------------------------------------------
    Write-Host "  $($CH.ARROW) Memeriksa Prerequisites..." -ForegroundColor Cyan
    Write-Host ""

    # Pastikan Chocolatey tersedia untuk install prereqs
    if (!(Test-Path "C:\ProgramData\chocolatey\bin\choco.exe")) {
        Write-INFO "Menginstal Chocolatey untuk prerequisites..."
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        $env:Path = "C:\ProgramData\chocolatey\bin;" + $env:Path
    }
    $chocoExe = "C:\ProgramData\chocolatey\bin\choco.exe"

    # Daftar prerequisites
    $prereqs = @(
        @{
            Name    = "Visual C++ Redistributable 2013 (x86)"
            Choco   = "vcredist2013"
            Check   = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{13A4EE12-23EA-3371-91EE-EFB36DDFFF3E}"
            Check64 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{13A4EE12-23EA-3371-91EE-EFB36DDFFF3E}"
        },
        @{
            Name    = "Visual C++ Redistributable 2015-2022 (x86)"
            Choco   = "vcredist140"
            Check   = "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x86"
            Check64 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x86"
        },
        @{
            Name    = "Visual C++ Redistributable 2015-2022 (x64)"
            Choco   = "vcredist140"
            Check   = "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64"
            Check64 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x64"
        },
        @{
            Name    = ".NET Framework 4.8"
            Choco   = "dotnetfx"
            Check   = "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full"
            MinVal  = 528040
            ValName = "Release"
        },
        @{
            Name    = "WebView2 Runtime"
            Choco   = "microsoft-edge-webview2-runtime"
            Check   = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}"
            Check64 = "HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}"
        }
    )

    foreach ($p in $prereqs) {
        $installed = $false
        if ($p.MinVal) {
            try {
                $val = (Get-ItemProperty -Path $p.Check -Name $p.ValName -ErrorAction Stop).$($p.ValName)
                if ($val -ge $p.MinVal) { $installed = $true }
            } catch { $installed = $false }
        } else {
            if (Test-Path $p.Check) { $installed = $true }
            elseif ($p.Check64 -and (Test-Path $p.Check64)) { $installed = $true }
        }

        if ($installed) {
            Write-OK "$($p.Name) sudah terinstall, dilewati."
        } else {
            Write-INFO "$($p.Name) belum ada, menginstall..."
            try {
                $proc = Start-Process -FilePath $chocoExe `
                    -ArgumentList "install $($p.Choco) -y --no-progress --ignore-checksums" `
                    -Wait -PassThru -NoNewWindow
                if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) {
                    Write-OK "$($p.Name) berhasil diinstall."
                    if ($proc.ExitCode -eq 3010) {
                        Write-WARN "Reboot disarankan setelah selesai untuk $($p.Name)."
                    }
                } else {
                    Write-WARN "$($p.Name) exit code: $($proc.ExitCode) -- lanjutkan."
                }
            } catch {
                Write-WARN "Gagal install $($p.Name): $_ -- dilanjutkan."
            }
        }
    }

    Write-Host ""
    Write-OK "Pemeriksaan prerequisites selesai."
    Write-Host ""


    # Download dengan progress bar real
    Write-INFO "Mengunduh installer dari GitHub..."
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    $dlSukses = $false

    # --- Metode 1: BITS Transfer (paling andal, ada progress, handle redirect) ---
    try {
        Write-INFO "Mengunduh via BITS..."
        Import-Module BitsTransfer -ErrorAction Stop
        Start-BitsTransfer -Source $installerUrl -Destination $installerPath -DisplayName "Synchronizer Installer" -ErrorAction Stop
        $dlSukses = $true
        Write-OK "Download via BITS selesai!"
    } catch {
        Write-WARN "BITS gagal: $_"
    }

    # --- Metode 2: Invoke-WebRequest (fallback, handle redirect GitHub otomatis) ---
    if (-not $dlSukses) {
        try {
            Write-INFO "Mencoba via Invoke-WebRequest..."
            $ProgressPreference = 'Continue'
            Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing -ErrorAction Stop
            $dlSukses = $true
            Write-OK "Download via Invoke-WebRequest selesai!"
        } catch {
            Write-WARN "Invoke-WebRequest gagal: $_"
        }
    }

    # --- Metode 3: curl.exe (Windows 10+ punya curl bawaan) ---
    if (-not $dlSukses) {
        try {
            Write-INFO "Mencoba via curl..."
            $curlExe = "$env:SystemRoot\System32\curl.exe"
            if (Test-Path $curlExe) {
                & $curlExe -L -o $installerPath $installerUrl --progress-bar
                if (Test-Path $installerPath) {
                    $dlSukses = $true
                    Write-OK "Download via curl selesai!"
                }
            }
        } catch {
            Write-WARN "curl gagal: $_"
        }
    }

    # Kalau semua metode gagal
    if (-not $dlSukses) {
        Write-ERR "Semua metode download gagal."
        Write-WARN "Cek koneksi internet atau link berikut secara manual:"
        Write-WARN "$installerUrl"
        pause
        exit
    }

    # Verifikasi file hasil download
    if (!(Test-Path $installerPath) -or (Get-Item $installerPath).Length -lt 1MB) {
        Write-ERR "File installer tidak valid atau tidak lengkap."
        exit
    }
    Write-OK "File installer siap: $installerPath ($([math]::Round((Get-Item $installerPath).Length / 1MB, 1)) MB)"

    # Silent install
    Write-Host ""
    Write-Typewriter "  Menjalankan silent install..." -Color Yellow -Delay 14
    Write-INFO "Proses ini mungkin memerlukan beberapa menit. Mohon tunggu..."
    Write-Host ""

    $installProc = Start-Process -FilePath $installerPath `
        -ArgumentList "/exenoui /qn" `
        -Wait -PassThru

    if ($installProc.ExitCode -eq 0) {
        Write-OK "Instalasi selesai! (Exit code: 0)"
    } else {
        Write-WARN "Installer selesai dengan exit code: $($installProc.ExitCode)"
        Write-INFO "Exit code non-zero tidak selalu berarti gagal pada installer ini."
    }

    # Verifikasi hasil install
    Start-Sleep -Seconds 2
    if (Test-Path $basePath) {
        Write-OK "Folder $basePath berhasil dibuat. Instalasi sukses!"
        # Hapus file installer temp
        Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
    } else {
        Write-ERR "Folder $basePath tidak ditemukan setelah install."
        Write-WARN "Instalasi mungkin gagal. Coba jalankan installer manual:"
        Write-WARN "$installerUrl"
        pause
        exit
    }
    } # end else (port tidak aktif)
} else {
    Write-OK "Folder ditemukan: $basePath"
}

$phpDir     = "$basePath\php"
$phpIni     = "$phpDir\php.ini"
$phpExeDest = "$basePath\dataweb\php.exe"
$phpIniDest = "$basePath\dataweb\php.ini"

# =============================================
# LANGKAH 2
# =============================================
Write-Step "2" "Menghentikan Proses Aktif"

$processesToKill = @("php", "synchronizer", "node")
foreach ($proc in $processesToKill) {
    $running = Get-Process -Name $proc -ErrorAction SilentlyContinue
    if ($running) {
        Show-Spinner -Message "Menghentikan proses: $proc" -Job {
            Stop-Process -Name $proc -Force -ErrorAction SilentlyContinue
        }
    } else {
        Write-INFO "Proses $proc tidak berjalan, dilewati."
    }
}
Show-ProgressBar -Label "Menunggu proses berhenti sepenuhnya..." -DurationMs 3000 -Color DarkYellow

# =============================================
# LANGKAH 3
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
# LANGKAH 4
# =============================================
Write-Step "4" "Konfigurasi Git"

if (Get-Command git -ErrorAction SilentlyContinue) {
    $gitConfigs = @(
        @("core.autocrlf",      "false"),
        @("advice.detachedHead","false"),
        @("core.fileMode",      "false")
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
$env:GIT_ASK_YESNO      = "false"

# =============================================
# LANGKAH 5
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
# LANGKAH 6
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
# LANGKAH 7
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
# LANGKAH 8
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
    echo ERROR: Node.js tidak terdeteksi!
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
