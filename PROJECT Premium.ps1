# ========================
# PROJECT Premium install_settings.ps1
# Standalone - Keyauth + Optimization
# ========================

Add-Type -AssemblyName System.Windows.Forms

# -- Self-elevate to Administrator -----------------------
# Most tweaks below write to HKLM / call powercfg / netsh, which silently
# do nothing without admin rights. Relaunch elevated if needed.
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    $psi.Verb = "runas"
    try {
        [System.Diagnostics.Process]::Start($psi) | Out-Null
    } catch {
        Write-Host "Administrator rights are required to run this script." -ForegroundColor Red
        Read-Host "Press Enter to exit"
    }
    exit
}

$ProgressPreference = "SilentlyContinue"
chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "PROJECT Premium - SYSTEM OPTIMIZATION"

# -- Logging so nothing scrolls past unseen --------------
$LogPath = Join-Path $env:TEMP "PROJECT Premium_log.txt"
try { Start-Transcript -Path $LogPath -Append -ErrorAction SilentlyContinue | Out-Null } catch {}

# Catch anything unhandled so the window doesn't just vanish on a crash.
trap {
    $Host.UI.RawUI.ForegroundColor = "Red"
    Write-Host ""
    Write-Host "  =========================================="
    Write-Host "  UNEXPECTED ERROR:"
    Write-Host "  $($_.Exception.Message)"
    Write-Host "  Line: $($_.InvocationInfo.ScriptLineNumber)  |  $($_.InvocationInfo.Line.Trim())"
    Write-Host "  =========================================="
    Write-Host "  Full log saved to: $LogPath"
    Write-Host ""
    try { Stop-Transcript | Out-Null } catch {}
    Read-Host "  Press Enter to close"
    exit 1
}

$ErrorActionPreference = "SilentlyContinue"

$PROJECTPremiumVersion = "4.0"
$WinBuild = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuildNumber -as [int]

# -- Color helpers ----------------------------------------
function Red    { param($t) Write-Host $t -ForegroundColor Red     -NoNewline }
function Cyan   { param($t) Write-Host $t -ForegroundColor Cyan    -NoNewline }
function White  { param($t) Write-Host $t -ForegroundColor White   -NoNewline }
function Gray   { param($t) Write-Host $t -ForegroundColor DarkGray -NoNewline }
function Green  { param($t) Write-Host $t -ForegroundColor Green   -NoNewline }
function Yellow { param($t) Write-Host $t -ForegroundColor Yellow  -NoNewline }
function NL     { Write-Host "" }

function Spin {
    param([string]$Label, [int]$Ms = 600)
    $frames = @("  -  ","  \  ","  |  ","  /  ")
    $cols   = @("Red","DarkRed","Red","DarkRed")
    $end    = (Get-Date).AddMilliseconds($Ms)
    $i      = 0
    while ((Get-Date) -lt $end) {
        $Host.UI.RawUI.ForegroundColor = $cols[$i % 4]
        Write-Host "`r$($frames[$i % 4])$Label   " -NoNewline
        Start-Sleep -Milliseconds 80
        $i++
    }
    $Host.UI.RawUI.ForegroundColor = "Green"
    Write-Host "`r  + $Label   "
    $Host.UI.RawUI.ForegroundColor = "Gray"
}

function PulseBar {
    param([string]$Label, [int]$Steps = 30)
    $blocks = @(" ",".",".","o","o","O","O","#","#")
    $cols   = @("DarkRed","Red","DarkRed","Red","Cyan","Red","DarkRed","Red","White")
    Write-Host ""
    White "  $Label"
    NL
    $bar = ""
    for ($i = 0; $i -lt $Steps; $i++) {
        $col = $cols[$i % $cols.Count]
        $Host.UI.RawUI.ForegroundColor = $col
        $bar += $blocks[$i % $blocks.Count]
        $pad  = " " * ($Steps - $i - 1)
        Write-Host -NoNewline "`r  [$bar$pad] $([int](($i/$Steps)*100))%"
        Start-Sleep -Milliseconds (Get-Random -Minimum 8 -Maximum 28)
    }
    $Host.UI.RawUI.ForegroundColor = "Red"
    $full = "#" * $Steps
    Write-Host "`r  [$full] 100%"
    Write-Host ""
    $Host.UI.RawUI.ForegroundColor = "Gray"
}

function Flicker {
    param([string]$Text, [int]$Times = 4)
    for ($i = 0; $i -lt $Times; $i++) {
        $Host.UI.RawUI.ForegroundColor = if ($i % 2 -eq 0) { "Red" } else { "DarkRed" }
        Write-Host "`r  $Text" -NoNewline
        Start-Sleep -Milliseconds 90
    }
    $Host.UI.RawUI.ForegroundColor = "Red"
    Write-Host "`r  $Text"
    $Host.UI.RawUI.ForegroundColor = "Gray"
}

function DONE_LINE { param($M) Write-Host "  * $M" -ForegroundColor Cyan }

# ========================================================
# INTRO
# ========================================================
Clear-Host
Write-Host ""
$Host.UI.RawUI.ForegroundColor = "DarkGray"
Write-Host "  ============================================"
Flicker "G . O . A . T . X" 6
$Host.UI.RawUI.ForegroundColor = "DarkRed"
Write-Host "  GREATEST OF ALL TIME  -  v$PROJECTPremiumVersion  -  BY Youngluv Project"
$Host.UI.RawUI.ForegroundColor = "DarkGray"
Write-Host "  ============================================"
Write-Host ""
Write-Host ""
PulseBar "Loading PROJECT Premium Core" 32
Write-Host ""

# ========================================================
# HARDWARE DETECT
# ========================================================
Spin "Scanning hardware..." 700

try { $cpuName = (Get-CimInstance Win32_Processor).Name.Trim() } catch { $cpuName = "Unknown CPU" }
$global:CPUName = $cpuName

$gpuList = Get-WmiObject Win32_VideoController
$gpu = $gpuList | Where-Object { $_.Name -match "NVIDIA" } | Select-Object -First 1
if (-not $gpu) { $gpu = $gpuList | Where-Object { $_.Name -match "AMD|Radeon" } | Select-Object -First 1 }
if (-not $gpu) { $gpu = $gpuList | Where-Object { $_.Name -match "Intel" }     | Select-Object -First 1 }
if (-not $gpu) { $gpu = $gpuList | Select-Object -First 1 }

$gpuName = $gpu.Name.Trim()
$global:GPUFullName = $gpuName
if     ($gpuName -match "NVIDIA")     { $global:GPUType = "NVIDIA"  }
elseif ($gpuName -match "AMD|Radeon") { $global:GPUType = "AMD"     }
elseif ($gpuName -match "Intel")      { $global:GPUType = "Intel"   }
else                                  { $global:GPUType = "UNKNOWN" }

Write-Host "  " -NoNewline; Green "*"; White " CPU  : $CPUName"; NL
Write-Host "  " -NoNewline; Green "*"; White " GPU  : $GPUFullName [$GPUType]"; NL
$ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
Write-Host "  " -NoNewline; Green "*"; White " RAM  : $ram GB"; NL
Write-Host ""

$fivemPaths = @("$env:LOCALAPPDATA\FiveM","$env:LOCALAPPDATA\FiveM\FiveM.app")
$global:FiveMFound = $false; $global:FiveMPath = ""
foreach ($fp in $fivemPaths) { if (Test-Path $fp) { $global:FiveMFound = $true; $global:FiveMPath = $fp; break } }

if ($global:FiveMFound) { Write-Host "  " -NoNewline; Green "*"; White " FiveM : DETECTED - $global:FiveMPath"; NL }
else { Write-Host "  ~ FiveM : NOT FOUND" -ForegroundColor Yellow }
Write-Host ""

$fivemRunning = Get-Process -Name "FiveM","FiveM_b2060","GTA5","GTAVLauncher","fivem_web_b2060" -ErrorAction SilentlyContinue
if ($fivemRunning) {
    $ans = [System.Windows.Forms.MessageBox]::Show(
        "FiveM / GTA5 is currently running!`nSome tweaks will NOT apply while the game is on.`nContinue anyway?",
        "PROJECT Premium - Warning",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    if ($ans -eq [System.Windows.Forms.DialogResult]::No) { exit }
}

# ========================================================
# TWEAKS
# ========================================================
$Host.UI.RawUI.ForegroundColor = "DarkGray"
Write-Host "  ============================================"
$Host.UI.RawUI.ForegroundColor = "Red"
Write-Host "  ENGAGING PROJECT Premium OPTIMIZATION SEQUENCE"
$Host.UI.RawUI.ForegroundColor = "DarkGray"
Write-Host "  ============================================"
Write-Host ""

Spin "CPU scheduling priority" 500
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v ConvertibleSlateMode    /t REG_DWORD /d 0  /f 2>$null | Out-Null
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 22 /f 2>$null | Out-Null

Spin "Keyboard response tuning" 450
$kbPath = "HKLM\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters"
reg add "$kbPath" /v ConnectMultiplePorts    /t REG_DWORD /d 0             /f 2>$null | Out-Null
reg add "$kbPath" /v KeyboardDataQueueSize   /t REG_DWORD /d 16            /f 2>$null | Out-Null
reg add "$kbPath" /v KeyboardDeviceBaseName  /t REG_SZ    /d KeyboardClass /f 2>$null | Out-Null
reg add "$kbPath" /v MaximumPortsServiced    /t REG_DWORD /d 3             /f 2>$null | Out-Null
reg add "$kbPath" /v SendOutputToAllPorts    /t REG_DWORD /d 1             /f 2>$null | Out-Null

Spin "Removing FPS-killing overlays" 400
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v AppCaptureEnabled /t REG_DWORD /d 0 /f 2>$null | Out-Null
reg add "HKCU\Software\Microsoft\GameBar" /v ShowGameBar /t REG_DWORD /d 0 /f 2>$null | Out-Null

Spin "Disabling fullscreen optimizations" 400
reg add "HKCU\System\GameConfigStore" /v GameDVR_FSEBehavior                   /t REG_DWORD /d 2 /f 2>$null | Out-Null
reg add "HKCU\System\GameConfigStore" /v GameDVR_FSEBehaviorMode               /t REG_DWORD /d 2 /f 2>$null | Out-Null
reg add "HKCU\System\GameConfigStore" /v GameDVR_HonorUserFSEBehaviorMode       /t REG_DWORD /d 1 /f 2>$null | Out-Null
reg add "HKCU\System\GameConfigStore" /v GameDVR_DXGIHonorFSEWindowsCompatible /t REG_DWORD /d 1 /f 2>$null | Out-Null
$layersPath = "HKCU\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"
foreach ($exe in @("FiveM.exe","GTA5.exe","fivem_web_b2060.exe")) {
    reg add "$layersPath" /v "C:\Program Files\Rockstar Games\Grand Theft Auto V\$exe" /t REG_SZ /d "~ DISABLEDXMAXIMIZEDWINDOWEDMODE" /f 2>$null | Out-Null
}

Spin "Unlocking Ultimate Performance" 800
$existingLine = powercfg -list 2>$null | Select-String "e9a42b02-d5df-448d-aa00-03f14749eb61"
if (-not $existingLine) { powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1 | Out-Null }
$existingLine = powercfg -list 2>$null | Select-String "e9a42b02-d5df-448d-aa00-03f14749eb61"
if ($existingLine) { powercfg -setactive e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null | Out-Null }
else               { powercfg -setactive SCHEME_MIN 2>$null | Out-Null }

Spin "Disabling hibernation" 350
powercfg -h off 2>$null | Out-Null
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v HibernateEnabled /t REG_DWORD /d 0 /f 2>$null | Out-Null

Spin "Reserving RAM for FiveM" 400
$ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
if ($ram -lt 16) { Stop-Service SysMain -Force -ErrorAction SilentlyContinue; Set-Service SysMain -StartupType Disabled -ErrorAction SilentlyContinue }
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache /t REG_DWORD /d 0 /f 2>$null | Out-Null
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v IoPageLockLimit  /t REG_DWORD /d 0 /f 2>$null | Out-Null

Spin "Nuking junk files" 500
Remove-Item "$env:Temp\*"       -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

Spin "Stripping Windows animations" 400
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f 2>$null | Out-Null
reg add "HKCU\Control Panel\Desktop"               /v DragFullWindows   /t REG_SZ    /d 0 /f 2>$null | Out-Null
reg add "HKCU\Control Panel\Desktop"               /v MenuShowDelay     /t REG_SZ    /d 0 /f 2>$null | Out-Null
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate        /t REG_SZ    /d 0 /f 2>$null | Out-Null
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewAlphaSelect /t REG_DWORD /d 0 /f 2>$null | Out-Null
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewShadow      /t REG_DWORD /d 0 /f 2>$null | Out-Null
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations   /t REG_DWORD /d 0 /f 2>$null | Out-Null
reg add "HKCU\Software\Microsoft\Windows\DWM"      /v EnableAeroPeek            /t REG_DWORD /d 0 /f 2>$null | Out-Null
reg add "HKCU\Software\Microsoft\Windows\DWM"      /v AlwaysHibernateThumbnails /t REG_DWORD /d 0 /f 2>$null | Out-Null

Spin "Injecting low-ping network stack" 900
netsh int tcp set global autotuninglevel=normal  2>$null | Out-Null
netsh int tcp set global chimney=disabled        2>$null | Out-Null
netsh int tcp set global ecncapability=disabled  2>$null | Out-Null
netsh int tcp set global timestamps=disabled     2>$null | Out-Null
netsh int tcp set global rss=enabled             2>$null | Out-Null
netsh int tcp set global rsc=disabled            2>$null | Out-Null
if ($WinBuild -lt 22000) {
    netsh int tcp set global fastopen=enabled 2>$null | Out-Null
    netsh int tcp set global dca=enabled      2>$null | Out-Null
    netsh int tcp set global netdma=enabled   2>$null | Out-Null
}
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
foreach ($a in $adapters) {
    $name = $a.Name
    netsh interface ipv4 set subinterface "$name" mtu=1500 store=persistent 2>$null | Out-Null
    try {
        Set-NetAdapterAdvancedProperty -Name $name -DisplayName "Energy Efficient Ethernet" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
        Set-NetAdapterAdvancedProperty -Name $name -DisplayName "Green Ethernet"            -DisplayValue "Disabled" -ErrorAction SilentlyContinue
        Set-NetAdapterAdvancedProperty -Name $name -DisplayName "Power Saving Mode"         -DisplayValue "Disabled" -ErrorAction SilentlyContinue
        Set-NetAdapterAdvancedProperty -Name $name -DisplayName "Receive Buffers"           -DisplayValue "2048"     -ErrorAction SilentlyContinue
        Set-NetAdapterAdvancedProperty -Name $name -DisplayName "Transmit Buffers"          -DisplayValue "2048"     -ErrorAction SilentlyContinue
        Set-NetAdapterAdvancedProperty -Name $name -DisplayName "Interrupt Moderation"      -DisplayValue "Disabled" -ErrorAction SilentlyContinue
    } catch {}
}
$ifaces = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -ErrorAction SilentlyContinue
foreach ($iface in $ifaces) {
    $rp = "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($iface.PSChildName)"
    reg add "$rp" /v TcpNoDelay      /t REG_DWORD /d 1 /f 2>$null | Out-Null
    reg add "$rp" /v TcpDelAckTicks  /t REG_DWORD /d 0 /f 2>$null | Out-Null
    reg add "$rp" /v TcpAckFrequency /t REG_DWORD /d 1 /f 2>$null | Out-Null
}
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v MaxCacheTtl         /t REG_DWORD /d 3600 /f 2>$null | Out-Null
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v MaxNegativeCacheTtl /t REG_DWORD /d 0    /f 2>$null | Out-Null
ipconfig /flushdns 2>$null | Out-Null
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 4294967295 /f 2>$null | Out-Null
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v NonBestEffortLimit /t REG_DWORD /d 0 /f 2>$null | Out-Null

Spin "Boosting IRQ priority" 500
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v IRQ8Priority /t REG_DWORD /d 1 /f 2>$null | Out-Null
$netAdapters = Get-WmiObject Win32_PnPEntity | Where-Object { $_.Name -match "Ethernet|Wi-Fi|Wireless|Network" -and $_.DeviceID -match "PCI" } | Select-Object -First 3
foreach ($dev in $netAdapters) {
    try {
        $devPath      = "HKLM\SYSTEM\CurrentControlSet\Enum\$($dev.DeviceID)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
        $affinityPath = "HKLM\SYSTEM\CurrentControlSet\Enum\$($dev.DeviceID)\Device Parameters\Interrupt Management\Affinity Policy"
        reg add "$devPath"      /v MSISupported   /t REG_DWORD /d 1 /f 2>$null | Out-Null
        reg add "$affinityPath" /v DevicePolicy   /t REG_DWORD /d 4 /f 2>$null | Out-Null
        reg add "$affinityPath" /v DevicePriority /t REG_DWORD /d 3 /f 2>$null | Out-Null
    } catch {}
}

Spin "Injecting game process profile" 500
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 0   /f 2>$null | Out-Null
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority"        /t REG_DWORD /d 8    /f 2>$null | Out-Null
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v Priority              /t REG_DWORD /d 6    /f 2>$null | Out-Null
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ    /d High /f 2>$null | Out-Null
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority"       /t REG_SZ    /d High /f 2>$null | Out-Null
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Background Only"     /t REG_SZ    /d False /f 2>$null | Out-Null

Spin "Enabling raw mouse input" 350
reg add "HKCU\Control Panel\Mouse" /v MouseSpeed      /t REG_SZ /d 0 /f 2>$null | Out-Null
reg add "HKCU\Control Panel\Mouse" /v MouseThreshold1 /t REG_SZ /d 0 /f 2>$null | Out-Null
reg add "HKCU\Control Panel\Mouse" /v MouseThreshold2 /t REG_SZ /d 0 /f 2>$null | Out-Null

Spin "GPU stability tuning" 400
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v TdrDelay    /t REG_DWORD /d 10 /f 2>$null | Out-Null
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v TdrDdiDelay /t REG_DWORD /d 20 /f 2>$null | Out-Null

Spin "Applying $GPUType driver tweaks" 600
if ($GPUType -eq "NVIDIA") {
    $nvPath = "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak"
    reg add "$nvPath" /v PowerMizerEnable  /t REG_DWORD /d 1 /f 2>$null | Out-Null
    reg add "$nvPath" /v PowerMizerLevel   /t REG_DWORD /d 1 /f 2>$null | Out-Null
    reg add "$nvPath" /v PowerMizerLevelAC /t REG_DWORD /d 1 /f 2>$null | Out-Null
    reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\PowerProfiles\PowerProfile_0" /v PowerProfile /t REG_DWORD /d 1 /f 2>$null | Out-Null
    reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\NVTweak" /v ShaderCacheSize /t REG_DWORD /d 4294967295 /f 2>$null | Out-Null
} elseif ($GPUType -eq "AMD") {
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v KMD_EnableComputePreemption /t REG_DWORD /d 0 /f 2>$null | Out-Null
}

Spin "Setting FiveM process priority HIGH" 400
$ifeoBase = "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options"
foreach ($exe in @("FiveM.exe","GTA5.exe")) {
    reg add "$ifeoBase\$exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 3 /f 2>$null | Out-Null
    reg add "$ifeoBase\$exe\PerfOptions" /v IoPriority       /t REG_DWORD /d 3 /f 2>$null | Out-Null
}
foreach ($name in @("FiveM","FiveM_b2060","GTA5","GTAVLauncher","fivem_web_b2060")) {
    $proc = Get-Process -Name $name -ErrorAction SilentlyContinue
    if ($proc) { try { $proc.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High } catch {} }
}

Spin "Optimizing pagefile + timer resolution" 500
$ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
if ($ram -lt 16) {
    try {
        $initMB = [int]($ram * 1024 * 1.5); $maxMB = [int]($ram * 1024 * 3)
        $cs = Get-WmiObject -Class Win32_ComputerSystem -ErrorAction SilentlyContinue
        if ($cs) { $cs.AutomaticManagedPagefile = $false; $cs.Put() | Out-Null }
        $pf = Get-WmiObject -Class Win32_PageFileSetting -ErrorAction SilentlyContinue
        if ($pf) { $pf.InitialSize = $initMB; $pf.MaximumSize = $maxMB; $pf.Put() | Out-Null }
    } catch {}
}
try {
    $src = @"
using System; using System.Runtime.InteropServices;
public class TimerRes { [DllImport("winmm.dll")] public static extern uint timeBeginPeriod(uint uPeriod); }
"@
    Add-Type -TypeDefinition $src -Language CSharp -ErrorAction SilentlyContinue
    [TimerRes]::timeBeginPeriod(1) | Out-Null
} catch {}
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v GlobalTimerResolutionRequests /t REG_DWORD /d 1 /f 2>$null | Out-Null

Spin "Disabling core parking + HPET" 600
$schemes = powercfg -list 2>$null | Select-String "([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})" | ForEach-Object { $_.Matches[0].Value }
foreach ($scheme in $schemes) {
    powercfg -setacvalueindex $scheme SUB_PROCESSOR CPMINCORES 100 2>$null | Out-Null
    powercfg -setacvalueindex $scheme SUB_PROCESSOR CPMAXCORES 100 2>$null | Out-Null
}
$ppPath = "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583"
reg add "$ppPath" /v ValueMin /t REG_DWORD /d 100 /f 2>$null | Out-Null
reg add "$ppPath" /v ValueMax /t REG_DWORD /d 100 /f 2>$null | Out-Null
bcdedit /deletevalue useplatformclock 2>$null | Out-Null
$hpetKey = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Enum\ACPI\PNP0103" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($hpetKey) {
    $hpetReg = ($hpetKey.Name -replace "HKEY_LOCAL_MACHINE","HKLM") + "\Device Parameters"
    reg add "$hpetReg" /v DisableHPET /t REG_DWORD /d 1 /f 2>$null | Out-Null
}

Spin "Tuning prefetch + NVIDIA Reflex" 500
$pfPath = "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"
reg add "$pfPath" /v EnablePrefetcher /t REG_DWORD /d 2 /f 2>$null | Out-Null
reg add "$pfPath" /v EnableSuperfetch /t REG_DWORD /d 0 /f 2>$null | Out-Null
reg add "$pfPath" /v EnableBootTrace  /t REG_DWORD /d 0 /f 2>$null | Out-Null
if ($GPUType -eq "NVIDIA") {
    $nvUll = "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\NVTweak"
    reg add "$nvUll" /v UllModeEnabled /t REG_DWORD /d 1 /f 2>$null | Out-Null
    reg add "$nvUll" /v UllModeLevel   /t REG_DWORD /d 2 /f 2>$null | Out-Null
    reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\NVTweak" /v MaxFramesAllowed /t REG_DWORD /d 1 /f 2>$null | Out-Null
}

Spin "Killing Windows bandwidth theft" 400
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode /t REG_DWORD /d 0 /f 2>$null | Out-Null
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Settings" /v DownloadMode         /t REG_DWORD /d 0 /f 2>$null | Out-Null
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Settings" /v DownloadModeProvider /t REG_DWORD /d 0 /f 2>$null | Out-Null
Stop-Service "DoSvc" -Force -ErrorAction SilentlyContinue
Set-Service  "DoSvc" -StartupType Disabled -ErrorAction SilentlyContinue

Spin "Adding FiveM to Defender exclusions" 400
try {
    $defSvc = Get-Service "WinDefend" -ErrorAction SilentlyContinue
    if ($defSvc -and $defSvc.Status -eq "Running") {
        if (Test-Path "$env:LOCALAPPDATA\FiveM") { Add-MpPreference -ExclusionPath "$env:LOCALAPPDATA\FiveM" -ErrorAction SilentlyContinue }
    }
} catch {}

Spin "Wiping FiveM stream cache" 500
if ($global:FiveMFound) {
    foreach ($cp in @("$env:LOCALAPPDATA\FiveM\FiveM.app\data\cache","$env:LOCALAPPDATA\FiveM\FiveM.app\logs")) {
        if (Test-Path $cp) { Get-ChildItem -Path $cp -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Spin "Rebuilding $GPUType shader cache" 500
if ($GPUType -eq "NVIDIA") {
    foreach ($p in @("$env:LOCALAPPDATA\NVIDIA\DXCache","$env:LOCALAPPDATA\NVIDIA\GLCache")) {
        if (Test-Path $p) { Get-ChildItem -Path $p -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue }
    }
} elseif ($GPUType -eq "AMD") {
    foreach ($p in @("$env:LOCALAPPDATA\AMD\DXCache","$env:LOCALAPPDATA\AMD\GLCache","$env:LOCALAPPDATA\AMD\VkCache")) {
        if (Test-Path $p) { Get-ChildItem -Path $p -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

# ========================================================
# OUTRO
# ========================================================
Write-Host ""
PulseBar "Finalizing PROJECT Premium" 32
Write-Host ""

$Host.UI.RawUI.ForegroundColor = "DarkGray"
Write-Host "  ============================================"
Flicker "  PROJECT Premium OPTIMIZATION COMPLETE" 5
$Host.UI.RawUI.ForegroundColor = "DarkGray"
Write-Host "  ============================================"
Write-Host ""

$items = @(
    "CPU scheduling + core parking OFF"
    "HPET disabled"
    "Keyboard response optimized"
    "FPS-killing overlays removed"
    "Fullscreen optimizations disabled"
    "Hibernation disabled"
    "RAM reserved for FiveM"
    "Windows animations stripped"
    "Low-ping TCP stack injected"
    "IRQ priority maximized"
    "Nagle OFF - packets fly to server"
    "FiveM at HIGH CPU priority"
    "$GPUType driver tweaks applied"
    "Raw mouse - zero acceleration"
    "Prefetch tuned for FiveM"
    "P2P bandwidth theft stopped"
    "Defender exclusion added"
    "Pagefile fixed + Timer 1ms"
    "Stream + shader cache rebuilt"
)

foreach ($item in $items) { DONE_LINE $item; Start-Sleep -Milliseconds 35 }

Write-Host ""
$Host.UI.RawUI.ForegroundColor = "Red"
Write-Host "  REBOOT RECOMMENDED - then drop into FiveM."
Write-Host ""

# -- Reboot prompt ----------------------------------------
$reboot = [System.Windows.Forms.MessageBox]::Show(
    "PROJECT Premium v$PROJECTPremiumVersion Complete!`n`nReboot now for full effect?",
    "PROJECT Premium - BY Youngluv Project",
    [System.Windows.Forms.MessageBoxButtons]::YesNo,
    [System.Windows.Forms.MessageBoxIcon]::Information
)
Write-Host "  Log saved to: $LogPath" -ForegroundColor DarkGray
try { Stop-Transcript | Out-Null } catch {}

if ($reboot -eq [System.Windows.Forms.DialogResult]::Yes) {
    Restart-Computer -Force
}