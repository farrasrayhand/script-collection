# Script Fix Aplikasi Synchronizer - Final v6.2
# Fitur: Unicode Auto-Detect, Animasi Terminal, Auto Elevation,
#        Auto Download + Install, Auto-click Git installer popup
# Usage: powershell -ExecutionPolicy Bypass -Command "irm http://script.minicenter.my.id/scripts/synchronizer-fix.ps1 | iex"

$ErrorActionPreference = "Continue"
$env:ComSpec = "$env:SystemRoot\System32\cmd.exe"

# =============================================
# DETEKSI UNICODE SUPPORT
# =============================================
function Test-UnicodeSupport {
    $wtSession = $env:WT_SESSION; $vscode = $env:TERM_PROGRAM; $conEmu = $env:ConEmuPID
    if ($wtSession -or $vscode -or $conEmu) { return $true }
    if ($host.Name -eq "Windows PowerShell ISE Host") { return $true }
    try {
        $fontName = (Get-ItemProperty "HKCU:\Console").FaceName 2>$null
        foreach ($f in @("Cascadia","Nerd Font","FiraCode","JetBrains","Lucida Console","NSimSun","MS Gothic")) {
            if ($fontName -like "*$f*") { return $true }
        }
    } catch {}
    try {
        $testChar = [char]0x2714
        $encoded  = [System.Text.Encoding]::UTF8.GetBytes($testChar)
        $decoded  = [System.Text.Encoding]::UTF8.GetString($encoded)
        if ($decoded -eq $testChar) {
            [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
            chcp 65001 2>&1 | Out-Null
            $cp = (chcp) -replace '[^0-9]', ''
            if ($cp -eq "65001") { return $true }
        }
    } catch {}
    return $false
}

$UNICODE = Test-UnicodeSupport
if ($UNICODE) {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
    chcp 65001 | Out-Null
    $CH = @{
        OK="[OK]";WARN="[!!]";ERR="[XX]";INFO="[..]"
        LINE=[string][char]0x2550;TL=[string][char]0x2554;TR=[string][char]0x2557
        BL=[string][char]0x255A;BR=[string][char]0x255D;SIDE=[string][char]0x2551
        SPIN=@([string][char]0x280B,[string][char]0x2819,[string][char]0x2839,[string][char]0x2838,
               [string][char]0x283C,[string][char]0x2834,[string][char]0x2826,[string][char]0x2827,
               [string][char]0x2807,[string][char]0x280F)
        BLOCK=[string][char]0x2588;EMPTY=[string][char]0x2591;ARROW=">>"
        CHECK=[string][char]0x2714;CROSS=[string][char]0x2718;BANG=[string][char]0x26A0;DOT=[string][char]0x25B8
    }
} else {
    $CH = @{
        OK="[OK]";WARN="[!!]";ERR="[XX]";INFO="[..]"
        LINE="=";TL="+";TR="+";BL="+";BR="+";SIDE="|"
        SPIN=@("-","\","|","/")
        BLOCK="#";EMPTY="-";ARROW=">>"
        CHECK="OK";CROSS="XX";BANG="!!";DOT=">>"
    }
}

# =============================================
# ANIMASI FUNCTIONS
# =============================================
function Show-Banner {
    Clear-Host; Write-Host ""
    if ($UNICODE) {
        $top = $CH.TL + ($CH.LINE * 42) + $CH.TR
        $bot = $CH.BL + ($CH.LINE * 42) + $CH.BR
        $mid = $CH.SIDE
        Write-Host "  $top" -ForegroundColor Cyan
        Write-Host "  $mid                                          $mid" -ForegroundColor Cyan
        Write-Host "  $mid   SYNCHRONIZER FIX TOOL  v6.2 ANIMATED   $mid" -ForegroundColor White
        Write-Host "  $mid                                          $mid" -ForegroundColor Cyan
        Write-Host "  $mid           minicenter.my.id                $mid" -ForegroundColor DarkGray
        Write-Host "  $mid                                          $mid" -ForegroundColor Cyan
        Write-Host "  $bot" -ForegroundColor Cyan
    } else {
        Write-Host "  SYNCHRONIZER FIX TOOL  v6.2 ANIMATED" -ForegroundColor White
        Write-Host "  ======================================" -ForegroundColor DarkCyan
        Write-Host "  minicenter.my.id" -ForegroundColor DarkGray
        Write-Host "  ======================================" -ForegroundColor DarkCyan
    }
    Write-Host ""
}
function Write-Typewriter {
    param([string]$Text,[ConsoleColor]$Color="White",[int]$Delay=18)
    foreach ($c in $Text.ToCharArray()) { Write-Host $c -NoNewline -ForegroundColor $Color; Start-Sleep -Milliseconds $Delay }
    Write-Host ""
}
function Show-Spinner {
    param([string]$Message,[ScriptBlock]$Job,[int]$DelayMs=100)
    $frames=$CH.SPIN; $i=0
    $rs=[runspacefactory]::CreateRunspace(); $rs.Open()
    $ps=[powershell]::Create(); $ps.Runspace=$rs; [void]$ps.AddScript($Job)
    $h=$ps.BeginInvoke()
    while (-not $h.IsCompleted) {
        Write-Host "`r  $($frames[$i%$frames.Length]) $Message   " -NoNewline -ForegroundColor Yellow
        Start-Sleep -Milliseconds $DelayMs; $i++
    }
    $ps.EndInvoke($h); $ps.Dispose(); $rs.Close()
    Write-Host "`r  $($CH.CHECK) $Message   " -ForegroundColor Green
}
function Show-ProgressBar {
    param([string]$Label,[int]$DurationMs=2000,[ConsoleColor]$Color="Cyan")
    $steps=30; $delay=[math]::Max(1,[math]::Floor($DurationMs/$steps))
    Write-Host "  $Label" -ForegroundColor White
    for ($i=1;$i-le$steps;$i++) {
        $pct=[math]::Round(($i/$steps)*100)
        Write-Host "`r  [$($CH.BLOCK*$i)$($CH.EMPTY*($steps-$i))] $pct%  " -NoNewline -ForegroundColor $Color
        Start-Sleep -Milliseconds $delay
    }
    Write-Host "`r  [$($CH.BLOCK*$steps)] 100% $($CH.CHECK) DONE!  " -ForegroundColor Green
    Write-Host ""
}
function Write-Step {
    param([string]$Number,[string]$Title)
    $line=$CH.LINE*38; $label="  $($CH.SIDE) $($CH.ARROW) LANGKAH $Number -- $Title"
    $pad=[math]::Max(1,44-$label.Length)
    Write-Host ""; Write-Host "  $($CH.TL)$line$($CH.TR)" -ForegroundColor DarkCyan
    Write-Host "$label$(' '*$pad)$($CH.SIDE)" -ForegroundColor Cyan
    Write-Host "  $($CH.BL)$line$($CH.BR)" -ForegroundColor DarkCyan; Write-Host ""
}
function Write-OK   { param([string]$msg) Write-Host "  $($CH.CHECK) $msg" -ForegroundColor Green }
function Write-WARN { param([string]$msg) Write-Host "  $($CH.BANG)  $msg" -ForegroundColor Yellow }
function Write-ERR  { param([string]$msg) Write-Host "  $($CH.CROSS) $msg" -ForegroundColor Red }
function Write-INFO { param([string]$msg) Write-Host "  $($CH.DOT)   $msg" -ForegroundColor DarkGray }
function Show-Countdown {
    param([int]$Seconds=3,[string]$Message="Membuka browser")
    Write-Host ""
    for ($i=$Seconds;$i-ge1;$i--) {
        Write-Host "`r  $Message dalam $i detik...  " -NoNewline -ForegroundColor DarkYellow
        Start-Sleep -Seconds 1
    }
    Write-Host "`r  $Message... GO!              " -ForegroundColor Green; Write-Host ""
}
function Show-Done {
    $line=$CH.LINE*40; Write-Host ""
    Write-Host "  $($CH.TL)$line$($CH.TR)" -ForegroundColor Green
    Write-Host "  $($CH.SIDE)                                          $($CH.SIDE)" -ForegroundColor Green
    Write-Host "  $($CH.SIDE)   $($CH.CHECK)  SEMUA PERBAIKAN SELESAI!           $($CH.SIDE)" -ForegroundColor Green
    Write-Host "  $($CH.SIDE)                                          $($CH.SIDE)" -ForegroundColor Green
    Write-Host "  $($CH.BL)$line$($CH.BR)" -ForegroundColor Green; Write-Host ""
}

# =============================================
# AUTO-CLICKER: Handle popup Git installer otomatis
# Dijalankan sebagai background job sebelum installer .exe dipanggil.
# Menggunakan Win32 API SendMessage untuk klik tombol Next/Finish/OK
# tanpa perlu user intervensi sama sekali.
# =============================================
function Start-GitPopupWatcher {
    Write-INFO "Memulai watcher untuk auto-handle popup Git installer..."

    $watcherScript = {
        Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class WinAPI {
    [DllImport("user32.dll")] public static extern IntPtr FindWindow(string cls, string title);
    [DllImport("user32.dll")] public static extern IntPtr FindWindowEx(IntPtr parent, IntPtr after, string cls, string title);
    [DllImport("user32.dll")] public static extern int SendMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, StringBuilder sb, int max);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int cmd);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern IntPtr GetWindow(IntPtr hWnd, uint cmd);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc lp, IntPtr param);
    [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr hWnd, EnumWindowsProc lp, IntPtr param);
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    public const uint WM_COMMAND = 0x0111;
    public const uint BM_CLICK   = 0x00F5;
    public const int  SW_HIDE    = 0;
}
"@
        # Judul window yang mungkin muncul dari Git installer (Inno Setup)
        $gitTitles = @(
            "Git*Setup*",
            "*Git*Setup*",
            "*Setup - Git*",
            "Git [0-9]*",
            "Information",
            "Select Components",
            "Select Destination*",
            "Ready to Install",
            "Installing",
            "Completing*Git*"
        )

        $deadline = (Get-Date).AddMinutes(10)
        $clicked  = 0

        while ((Get-Date) -lt $deadline) {
            Start-Sleep -Milliseconds 500

            # Cari semua window yang judul atau classnya terkait Git/Inno Setup
            $allWindows = @()
            [WinAPI]::EnumWindows({
                param($hWnd, $lParam)
                $sb = New-Object System.Text.StringBuilder 256
                [WinAPI]::GetWindowText($hWnd, $sb, 256) | Out-Null
                $title = $sb.ToString()
                if ($title -match "Git.*Setup|Setup.*Git|Setup Wizard|Information|Completing the|Select.*Location|Select.*Components|Ready to Install") {
                    $script:allWindows += [PSCustomObject]@{ hWnd=$hWnd; Title=$title }
                }
                return $true
            }, [IntPtr]::Zero) | Out-Null

            foreach ($win in $allWindows) {
                if (-not [WinAPI]::IsWindowVisible($win.hWnd)) { continue }

                # Sembunyikan window agar tidak mengganggu (opsional -- bisa diaktifkan)
                # [WinAPI]::ShowWindow($win.hWnd, [WinAPI]::SW_HIDE)

                # Cari dan klik tombol yang tepat
                # Prioritas: Next > Install > Finish > OK > Yes
                $buttonLabels = @("&Next >", "Next >", "&Next", "Install", "&Install", "&Finish", "Finish", "OK", "&Yes", "Yes")

                foreach ($label in $buttonLabels) {
                    $btn = [WinAPI]::FindWindowEx($win.hWnd, [IntPtr]::Zero, "Button", $label)
                    if ($btn -ne [IntPtr]::Zero -and [WinAPI]::IsWindowVisible($btn)) {
                        [WinAPI]::SendMessage($btn, [WinAPI]::BM_CLICK, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null
                        $script:clicked++
                        Start-Sleep -Milliseconds 300
                        break
                    }
                }

                # Juga cari child button tanpa label spesifik (kadang Inno pakai ID numerik)
                $allBtns = New-Object System.Collections.ArrayList
                [WinAPI]::EnumChildWindows($win.hWnd, {
                    param($hBtn, $lParam)
                    $sb = New-Object System.Text.StringBuilder 64
                    [WinAPI]::GetWindowText($hBtn, $sb, 64) | Out-Null
                    $t = $sb.ToString()
                    if ($t -match "Next|Install|Finish|OK|Yes" -and [WinAPI]::IsWindowVisible($hBtn)) {
                        [WinAPI]::SendMessage($hBtn, [WinAPI]::BM_CLICK, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null
                        $script:clicked++
                        Start-Sleep -Milliseconds 300
                    }
                    return $true
                }, [IntPtr]::Zero) | Out-Null
            }
        }
    }

    # Jalankan watcher di runspace terpisah (background)
    $rs = [runspacefactory]::CreateRunspace()
    $rs.Open()
    $ps = [powershell]::Create()
    $ps.Runspace = $rs
    [void]$ps.AddScript($watcherScript)
    $handle = $ps.BeginInvoke()

    # Simpan referensi agar bisa di-stop nanti
    $Global:_gitWatcherPS     = $ps
    $Global:_gitWatcherRS     = $rs
    $Global:_gitWatcherHandle = $handle

    Write-OK "Watcher berjalan di background — popup Git akan di-handle otomatis."
}

function Stop-GitPopupWatcher {
    if ($Global:_gitWatcherPS) {
        try { $Global:_gitWatcherPS.Stop() } catch {}
        try { $Global:_gitWatcherPS.Dispose() } catch {}
        try { $Global:_gitWatcherRS.Close() } catch {}
        $Global:_gitWatcherPS = $null
        $Global:_gitWatcherRS = $null
        Write-INFO "Watcher dihentikan."
    }
}

# =============================================
# MULAI SCRIPT
# =============================================
Show-Banner

if ($UNICODE) { Write-INFO "Mode Unicode aktif" } else { Write-INFO "Mode ASCII" }
Start-Sleep -Milliseconds 400
Write-Typewriter "  Mempersiapkan perbaikan sistem..." -Color DarkCyan -Delay 20
Start-Sleep -Milliseconds 300

# Auto elevation
$currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host ""; Write-Typewriter "  Bukan Administrator. Melakukan elevasi otomatis..." -Color Yellow -Delay 15
    if (-not $MyInvocation.MyCommand.Path) {
        $tempScript = "$env:TEMP\synchronizer-fix-temp.ps1"
        $MyInvocation.MyCommand.ScriptBlock | Out-File -FilePath $tempScript -Encoding UTF8
        $scriptPath = $tempScript
    } else { $scriptPath = $MyInvocation.MyCommand.Path }
    Start-Process PowerShell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`"" -Wait
    exit
}
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
Write-OK "Berjalan sebagai Administrator"
Start-Sleep -Milliseconds 300

# Cek port
Write-Host ""; Write-INFO "Mengecek port 7008 (Apache)..."
Start-Sleep -Milliseconds 500
$portActive = Get-NetTCPConnection -LocalPort 7008 -ErrorAction SilentlyContinue
if ($portActive) { Write-OK "Port 7008 aktif." } else { Write-WARN "Port 7008 tidak aktif." }

$basePath  = "C:\synchronizer"
$folderAda = Test-Path $basePath

# =============================================
# LANGKAH 1
# =============================================
Write-Step "1" "Validasi Folder Instalasi"

if (!$folderAda) {
    Write-WARN "Folder default $basePath tidak ditemukan."; Write-Host ""

    function Test-IsSynchronizer {
        param([string]$path)
        if ([string]::IsNullOrWhiteSpace($path)) { return $false }
        $found = 0
        foreach ($m in @("$path\dataweb\data_sync.json","$path\dataweb\app\Models\SyncSession.php","$path\updater\updater.bat")) {
            if (Test-Path $m) { $found++ }
        }
        return ($found -ge 1)
    }

    $folderDitemukan = $false

    if ($portActive) {
        Write-INFO "Port 7008 aktif - mencari folder instalasi dari proses Apache..."
        try {
            $conn = Get-NetTCPConnection -LocalPort 7008 -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($conn) {
                $procPath = (Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue).Path
                if ($procPath) {
                    $candidate = Split-Path $procPath -Parent
                    for ($i=0;$i-lt5;$i++) {
                        $candidate = Split-Path $candidate -Parent
                        if ([string]::IsNullOrWhiteSpace($candidate)) { break }
                        if (Test-IsSynchronizer $candidate) {
                            $basePath=$candidate; $folderDitemukan=$true
                            Write-OK "Folder Synchronizer terverifikasi: $basePath"; break
                        }
                    }
                }
            }
        } catch { Write-WARN "Gagal deteksi otomatis dari proses: $_" }

        if (-not $folderDitemukan) {
            Write-INFO "Memindai lokasi umum..."
            foreach ($p in @("C:\synchronizer","D:\synchronizer","E:\synchronizer","C:\e-Rapor SMK Synchronizer","D:\e-Rapor SMK Synchronizer","$env:ProgramFiles\synchronizer","${env:ProgramFiles(x86)}\synchronizer")) {
                if (Test-IsSynchronizer $p) { $basePath=$p; $folderDitemukan=$true; Write-OK "Ditemukan: $basePath"; break }
            }
        }

        if (-not $folderDitemukan) {
            Write-WARN "Folder Synchronizer tidak terdeteksi otomatis."
            $inputPath = Read-Host "  Masukkan path folder (atau SKIP untuk install ulang)"
            if ($inputPath -eq "SKIP" -or $inputPath -eq "skip") {
                $portActive = $false
            } elseif (Test-IsSynchronizer $inputPath) {
                $basePath=$inputPath; $folderDitemukan=$true; Write-OK "Terverifikasi: $basePath"
            } else {
                Write-ERR "Folder '$inputPath' bukan instalasi Synchronizer yang valid."
                pause; exit
            }
        }
        if ($folderDitemukan) { $folderAda = $true }
    }

    if (-not $portActive -and -not $folderDitemukan) {
        Write-INFO "Synchronizer belum terinstall. Memulai instalasi otomatis..."
        Write-Host ""

        $installerUrl  = "https://github.com/farrasrayhand/script-collection/releases/download/v.2/e-Rapor.SMK.Synchronizer.exe"
        $installerPath = "$env:TEMP\e-Rapor_SMK_Synchronizer.exe"

        Write-Host "  $($CH.TL)$($CH.LINE * 52)$($CH.TR)" -ForegroundColor Cyan
        Write-Host "  $($CH.SIDE)  Synchronizer belum terinstall.                        $($CH.SIDE)" -ForegroundColor White
        Write-Host "  $($CH.SIDE)  Akan didownload dan diinstall otomatis...             $($CH.SIDE)" -ForegroundColor Cyan
        Write-Host "  $($CH.BL)$($CH.LINE * 52)$($CH.BR)" -ForegroundColor Cyan
        Write-Host ""

        # Install Chocolatey
        if (!(Test-Path "C:\ProgramData\chocolatey\bin\choco.exe")) {
            Write-INFO "Menginstal Chocolatey..."
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            $env:Path = "C:\ProgramData\chocolatey\bin;" + $env:Path
        }
        $chocoExe = "C:\ProgramData\chocolatey\bin\choco.exe"

        # Prereqs via Chocolatey (VC++, .NET, WebView2)
        Write-Host "  $($CH.ARROW) Memeriksa Prerequisites..." -ForegroundColor Cyan; Write-Host ""
        $prereqs = @(
            @{ Name="Visual C++ Redistributable 2013 (x86)"; Choco="vcredist2013"
               Check="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{13A4EE12-23EA-3371-91EE-EFB36DDFFF3E}"
               Check64="HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{13A4EE12-23EA-3371-91EE-EFB36DDFFF3E}" },
            @{ Name="Visual C++ Redistributable 2015-2022 (x86)"; Choco="vcredist140"
               Check="HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x86"
               Check64="HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x86" },
            @{ Name="Visual C++ Redistributable 2015-2022 (x64)"; Choco="vcredist140"
               Check="HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64"
               Check64="HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" },
            @{ Name=".NET Framework 4.8"; Choco="dotnetfx"
               Check="HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full"; MinVal=528040; ValName="Release" },
            @{ Name="WebView2 Runtime"; Choco="microsoft-edge-webview2-runtime"
               Check="HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}"
               Check64="HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" }
        )

        foreach ($p in $prereqs) {
            $installed = $false
            if ($p.MinVal) {
                try { $val=(Get-ItemProperty -Path $p.Check -Name $p.ValName -ErrorAction Stop).$($p.ValName); if ($val-ge$p.MinVal){$installed=$true} } catch {}
            } else {
                if (Test-Path $p.Check){$installed=$true} elseif ($p.Check64 -and (Test-Path $p.Check64)){$installed=$true}
            }
            if ($installed) { Write-OK "$($p.Name) sudah terinstall, dilewati." }
            else {
                Write-INFO "$($p.Name) belum ada, menginstall..."
                try {
                    $proc = Start-Process -FilePath $chocoExe -ArgumentList "install $($p.Choco) -y --no-progress --ignore-checksums" -Wait -PassThru -NoNewWindow
                    if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) { Write-OK "$($p.Name) berhasil diinstall." }
                    else { Write-WARN "$($p.Name) exit code: $($proc.ExitCode) -- dilanjutkan." }
                } catch { Write-WARN "Gagal install $($p.Name): $_ -- dilanjutkan." }
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            }
        }

        Write-Host ""; Write-OK "Pemeriksaan prerequisites selesai."; Write-Host ""

        # Download installer
        Write-INFO "Mengunduh installer dari GitHub..."
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        $dlSukses = $false

        try {
            Write-INFO "Mengunduh via BITS..."
            Import-Module BitsTransfer -ErrorAction Stop
            Start-BitsTransfer -Source $installerUrl -Destination $installerPath -DisplayName "Synchronizer Installer" -ErrorAction Stop
            $dlSukses = $true; Write-OK "Download via BITS selesai!"
        } catch { Write-WARN "BITS gagal: $_" }

        if (-not $dlSukses) {
            try {
                Write-INFO "Mencoba via Invoke-WebRequest..."
                $ProgressPreference='Continue'
                Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing -ErrorAction Stop
                $dlSukses=$true; Write-OK "Download via Invoke-WebRequest selesai!"
            } catch { Write-WARN "Invoke-WebRequest gagal: $_" }
        }

        if (-not $dlSukses) {
            try {
                $curlExe="$env:SystemRoot\System32\curl.exe"
                if (Test-Path $curlExe) {
                    & $curlExe -L -o $installerPath $installerUrl --progress-bar
                    if (Test-Path $installerPath) { $dlSukses=$true; Write-OK "Download via curl selesai!" }
                }
            } catch { Write-WARN "curl gagal: $_" }
        }

        if (-not $dlSukses) { Write-ERR "Semua metode download gagal."; Write-WARN $installerUrl; pause; exit }
        if (!(Test-Path $installerPath) -or (Get-Item $installerPath).Length -lt 1MB) { Write-ERR "File installer tidak valid."; exit }
        Write-OK "File installer siap: $installerPath ($([math]::Round((Get-Item $installerPath).Length/1MB,1)) MB)"

        Write-Host ""
        Write-Typewriter "  Menjalankan silent install..." -Color Yellow -Delay 14
        Write-INFO "Popup Git installer akan di-handle otomatis oleh watcher."
        Write-Host ""

        # Mulai watcher SEBELUM installer dijalankan
        Start-GitPopupWatcher

        $installProc = Start-Process -FilePath $installerPath `
            -ArgumentList "/exenoui /qn /norestart REBOOT=ReallySuppress" `
            -Wait -PassThru -WindowStyle Hidden

        # Hentikan watcher setelah installer selesai
        Stop-GitPopupWatcher

        if ($installProc.ExitCode -eq 0) { Write-OK "Instalasi selesai! (Exit code: 0)" }
        else { Write-WARN "Installer selesai dengan exit code: $($installProc.ExitCode)" }

        Start-Sleep -Seconds 2
        if (Test-Path $basePath) {
            Write-OK "Folder $basePath berhasil dibuat. Instalasi sukses!"
            Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
        } else {
            Write-ERR "Folder $basePath tidak ditemukan setelah install."
            Write-WARN $installerUrl; pause; exit
        }
    }
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
foreach ($proc in @("php","synchronizer","node")) {
    if (Get-Process -Name $proc -ErrorAction SilentlyContinue) {
        Show-Spinner -Message "Menghentikan proses: $proc" -Job { Stop-Process -Name $proc -Force -ErrorAction SilentlyContinue }
    } else { Write-INFO "Proses $proc tidak berjalan, dilewati." }
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
} else { Write-OK "Chocolatey sudah terinstall." }

$env:Path = "C:\ProgramData\chocolatey\bin;C:\Program Files\Git\cmd;C:\Program Files\Git\bin;" + `
    [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + `
    [System.Environment]::GetEnvironmentVariable("Path","User")
Write-OK "Environment Path diperbarui."

if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    Show-Spinner -Message "Menginstal Git via Chocolatey..." -Job {
        & "C:\ProgramData\chocolatey\bin\choco.exe" install git -y | Out-Null
    }
    $env:Path = "C:\ProgramData\chocolatey\bin;C:\Program Files\Git\cmd;C:\Program Files\Git\bin;" + `
        [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + `
        [System.Environment]::GetEnvironmentVariable("Path","User")
} else { Write-OK "Git sudah terinstall." }

# =============================================
# LANGKAH 4
# =============================================
Write-Step "4" "Konfigurasi Git"
if (Get-Command git -ErrorAction SilentlyContinue) {
    foreach ($cfg in @(@("core.autocrlf","false"),@("advice.detachedHead","false"),@("core.fileMode","false"))) {
        & git config --global $cfg[0] $cfg[1]; Write-OK "git config $($cfg[0]) = $($cfg[1])"; Start-Sleep -Milliseconds 120
    }
    & git config --global --add safe.directory "$basePath/dataweb"; Write-OK "safe.directory ditambahkan."
} else { Write-WARN "Git tidak ditemukan, langkah konfigurasi dilewati." }
$env:GIT_TERMINAL_PROMPT="0"; $env:GIT_ASK_YESNO="false"

# =============================================
# LANGKAH 5
# =============================================
Write-Step "5" "Perbaikan PHP"
if (Test-Path $phpExeDest) { Remove-Item $phpExeDest -Force -ErrorAction SilentlyContinue; Write-OK "php.exe lama dihapus." }
Show-ProgressBar -Label "Menyalin php.exe ke dataweb..." -DurationMs 1200 -Color Cyan
if (Test-Path "$phpDir\php.exe") { Copy-Item "$phpDir\php.exe" -Destination $phpExeDest -Force; Write-OK "php.exe disalin." } else { Write-WARN "php.exe tidak ditemukan di $phpDir" }
if (Test-Path $phpIni) { Copy-Item $phpIni -Destination $phpIniDest -Force; Write-OK "php.ini disalin." } else { Write-WARN "php.ini tidak ditemukan di $phpDir" }
Start-Sleep -Milliseconds 400
if (Test-Path $phpExeDest) {
    try { $phpModules = & $phpExeDest -m 2>$null } catch { $phpModules="" }
    if ($phpModules -match "pdo_sqlite") { Write-OK "Ekstensi pdo_sqlite aktif." } else { Write-WARN "pdo_sqlite belum terdeteksi." }
    if ($phpModules -match "openssl")    { Write-OK "Ekstensi openssl aktif."    } else { Write-WARN "openssl belum terdeteksi."    }
}

# =============================================
# LANGKAH 6
# =============================================
Write-Step "6" "Fix Composer & Laravel Update"
$datawebPath="$basePath\dataweb"; $phpExe="$basePath\php\php.exe"
$composerPhar="$datawebPath\composer.phar"; $composerCmd=$null
if (Test-Path $composerPhar) { $composerCmd="phar" } elseif (Get-Command composer -ErrorAction SilentlyContinue) { $composerCmd="global" }

if (Test-Path "$datawebPath\vendor") {
    Show-Spinner -Message "Menghapus folder vendor lama..." -Job { Remove-Item "$datawebPath\vendor" -Recurse -Force -ErrorAction SilentlyContinue }
}

if (Test-Path $datawebPath) {
    Set-Location $datawebPath
    if ($composerCmd) {
        Write-Typewriter "  Menjalankan composer install..." -Color Yellow -Delay 14
        Write-INFO "Proses ini bisa memakan beberapa menit, mohon tunggu..."
        $env:PATH = "$basePath\php;" + $env:PATH
        try {
            $cmdLine = if ($composerCmd -eq "phar") { "/c `"`"$phpExe`" `"$composerPhar`" clear-cache && `"$phpExe`" `"$composerPhar`" install --no-interaction --optimize-autoloader --no-progress`"" }
                       else { "/c composer clear-cache && composer install --no-interaction --optimize-autoloader --no-progress" }
            $cp = Start-Process -FilePath "$env:ComSpec" -ArgumentList $cmdLine -WorkingDirectory $datawebPath -Wait -NoNewWindow -PassThru
            Write-INFO "Composer selesai (exit code: $($cp.ExitCode))"
        } catch { Write-WARN "Composer install bermasalah: $_" }

        $vendorCheck = "$datawebPath\vendor\laravel\framework\src\Illuminate\Support\functions.php"
        if (Test-Path $vendorCheck) { Write-OK "Vendor lengkap." }
        else {
            Write-WARN "Vendor belum lengkap, menjalankan composer update..."
            try {
                $cmdFb = if ($composerCmd -eq "phar") { "/c `"`"$phpExe`" `"$composerPhar`" update --no-interaction --optimize-autoloader --no-progress`"" }
                         else { "/c composer update --no-interaction --optimize-autoloader --no-progress" }
                Start-Process -FilePath "$env:ComSpec" -ArgumentList $cmdFb -WorkingDirectory $datawebPath -Wait -NoNewWindow | Out-Null
            } catch {}
            if (Test-Path $vendorCheck) { Write-OK "Vendor lengkap (via update)." } else { Write-WARN "Vendor masih belum lengkap. Cek koneksi internet." }
        }
    } else { Write-WARN "Composer tidak terdeteksi." }
}

if (Test-Path "$basePath\updater\updater.bat") {
    Set-Location "$basePath\updater"
    Write-Typewriter "  Menjalankan updater.bat (Git pull)..." -Color Yellow -Delay 14
    Start-Process -FilePath "$env:ComSpec" -ArgumentList "/c updater.bat" -Wait -NoNewWindow
    Write-OK "Langkah 6 selesai."
}

# =============================================
# LANGKAH 7
# =============================================
Write-Step "7" "Re-sinkronisasi PHP Pasca Git Pull"
Show-ProgressBar -Label "Menyinkronisasi ulang php.exe & php.ini..." -DurationMs 1500 -Color Magenta
if (Test-Path "$phpDir\php.exe") { Copy-Item "$phpDir\php.exe" -Destination $phpExeDest -Force; Write-OK "php.exe di-refresh." }
if (Test-Path $phpIni) { Copy-Item $phpIni -Destination $phpIniDest -Force; Write-OK "php.ini di-refresh." }

# =============================================
# LANGKAH 8
# =============================================
Write-Step "8" "Fix Node.js & NPM Build"
Write-Typewriter "  Menginstal Node.js v24.15.0 via Chocolatey..." -Color Yellow -Delay 12
& "C:\ProgramData\chocolatey\bin\choco.exe" install nodejs --version="24.15.0" -y --force --force-dependencies | Out-Null
Write-OK "Node.js terinstall."
$env:Path = "$env:ProgramFiles\nodejs;" + [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

$npmContent = @"
@echo off
set "PATH=%PATH%;%ProgramFiles%\nodejs;C:\ProgramData\chocolatey\bin;%ProgramFiles%\Git\cmd"
cd /d "$basePath\dataweb"
echo Mengecek versi Node:
node -v
if errorlevel 1 ( echo ERROR: Node.js tidak terdeteksi! & pause & exit /b 1 )
echo Membersihkan cache...
call npm cache clean --force
echo Memulai npm install...
call npm install --legacy-peer-deps
echo Memulai npm run build...
call npm run build
echo. & echo Proses Build Selesai!
timeout /t 3 & exit
"@
$npmContent | Out-File "$basePath\run_npm.bat" -Encoding ASCII
Write-Typewriter "  Menjalankan npm install & build..." -Color Yellow -Delay 14
Start-Process -FilePath "$env:ComSpec" -ArgumentList "/c $basePath\run_npm.bat" -Wait
Write-OK "NPM build selesai."

# =============================================
# LANGKAH 9
# =============================================
Write-Step "9" "Menjalankan Apache (Web Server)"
$apacheJalan = $false

function Test-PortListening { param([int]$port=7008)
    try { $c=Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue; return ($null -ne $c) } catch { return $false }
}

if (Test-PortListening 7008) { Write-OK "Apache sudah berjalan di port 7008."; $apacheJalan=$true }

if (-not $apacheJalan) {
    $svc = Get-Service -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -match "Apache|httpd|synchronizer|erapor" -or $_.DisplayName -match "Apache|Synchronizer|e-Rapor"
    } | Select-Object -First 1
    if ($svc) {
        try {
            if ($svc.Status -ne "Running") { Start-Service -Name $svc.Name -ErrorAction Stop; Start-Sleep -Seconds 3 }
            if (Test-PortListening 7008) { Write-OK "Apache service berhasil dijalankan."; $apacheJalan=$true }
        } catch { Write-WARN "Gagal start service: $_" }
    }
}

if (-not $apacheJalan -and (Test-Path "$basePath\httpd.bat")) {
    Start-Process -FilePath "$env:ComSpec" -ArgumentList "/c `"$basePath\httpd.bat`"" -WorkingDirectory $basePath -WindowStyle Hidden
    Start-Sleep -Seconds 4
    if (Test-PortListening 7008) { Write-OK "Apache berhasil dijalankan via httpd.bat."; $apacheJalan=$true }
}

if (-not $apacheJalan) {
    foreach ($sb in @("$basePath\apache_start.bat","$basePath\apache\bin\apache_start.bat","$basePath\bin\apache_start.bat")) {
        if (Test-Path $sb) {
            Start-Process -FilePath "$env:ComSpec" -ArgumentList "/c `"$sb`"" -WindowStyle Hidden
            Start-Sleep -Seconds 4
            if (Test-PortListening 7008) { Write-OK "Apache berhasil dijalankan."; $apacheJalan=$true; break }
        }
    }
}

if (-not $apacheJalan) {
    $httpdExe = Get-ChildItem -Path $basePath -Filter "httpd.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($httpdExe) {
        Start-Process -FilePath $httpdExe.FullName -ArgumentList "-k install" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
        Start-Process -FilePath $httpdExe.FullName -ArgumentList "-k start" -WindowStyle Hidden -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 4
        if (Test-PortListening 7008) { Write-OK "Apache berhasil dijalankan via httpd.exe."; $apacheJalan=$true }
    }
}

if ($apacheJalan) { Write-OK "Web server aktif. Aplikasi siap diakses di http://localhost:7008" }
else {
    Write-WARN "Apache belum bisa dipastikan jalan otomatis."
    Write-INFO "Coba buka 'e-Rapor SMK Synchronizer' dari Start Menu untuk jalankan web server."
}

Show-Done
Show-Countdown -Seconds 3 -Message "Membuka aplikasi di browser"
Start-Process "http://localhost:7008"
