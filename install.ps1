# TurtleNeck Windows Installer
# irm https://raw.githubusercontent.com/kpryu6/turtleneck/main/install.ps1 | iex
$ErrorActionPreference = 'Stop'
# Keep this file ASCII-only: Windows PowerShell 5.1 reads BOM-less scripts as
# Windows-1252, and mis-decoded UTF-8 bytes can turn into quote characters.
$ProgressPreference = 'SilentlyContinue'  # Invoke-WebRequest is very slow with the progress bar
Write-Host "Installing TurtleNeck..." -ForegroundColor Green

$repo = "kpryu6/turtleneck"
$installDir = "$env:LOCALAPPDATA\TurtleNeck"
$setupName = "TurtleNeck-Setup.exe"
$zipName = "TurtleNeck-Windows-x64.zip"
$shortcutsCreated = $false

function New-Shortcut([string]$Path, [string]$Target, [string]$Arguments = "") {
    $ws = New-Object -ComObject WScript.Shell
    $sc = $ws.CreateShortcut($Path)
    $sc.TargetPath = $Target
    $sc.Arguments = $Arguments
    $sc.WorkingDirectory = $installDir
    $sc.Description = "TurtleNeck - Posture Guardian"
    $sc.Save()
}

# Stop a running copy so its files can be replaced
Get-Process TurtleNeck -ErrorAction SilentlyContinue | Stop-Process -Force

# 1) Prefer the prebuilt app from GitHub Releases (no Python needed)
$setup = $null
$asset = $null
try {
    $release = Invoke-RestMethod "https://api.github.com/repos/$repo/releases/latest"
    $setup = $release.assets | Where-Object { $_.name -eq $setupName } | Select-Object -First 1
    $asset = $release.assets | Where-Object { $_.name -eq $zipName } | Select-Object -First 1
} catch { }

if ($setup) {
    # Same installer as the website download: per-user, adds Start menu/desktop
    # shortcuts and an entry in Settings > Apps for uninstalling
    Write-Host "Downloading TurtleNeck $($release.tag_name)..."
    $exe = Join-Path $env:TEMP $setupName
    Invoke-WebRequest -Uri $setup.browser_download_url -OutFile $exe
    $p = Start-Process -FilePath $exe -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART' -PassThru -Wait
    Remove-Item $exe -ErrorAction SilentlyContinue
    if ($p.ExitCode -ne 0) {
        Write-Host "Error: the installer exited with code $($p.ExitCode)." -ForegroundColor Red
        exit 1
    }
    $target = "$installDir\TurtleNeck.exe"
    $arguments = ""
    $shortcutsCreated = $true
}
elseif ($asset) {
    # Older releases only have the zip
    Write-Host "Downloading TurtleNeck $($release.tag_name)..."
    $zip = Join-Path $env:TEMP $zipName
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zip
    if (Test-Path $installDir) { Remove-Item -Recurse -Force $installDir }
    Expand-Archive -Path $zip -DestinationPath $env:LOCALAPPDATA -Force  # zip contains a TurtleNeck\ folder
    Remove-Item $zip
    $target = "$installDir\TurtleNeck.exe"
    $arguments = ""
}
else {
    # 2) No prebuilt build yet: install from source with Python 3.10-3.12
    Write-Host "No prebuilt Windows release found, installing from source..." -ForegroundColor Yellow

    # mediapipe only supports Python 3.9-3.12. Prefer the py launcher, which can pick a
    # compatible version even when a newer Python is the default.
    function Find-Python([string]$Command, [string[]]$Arguments) {
        # Windows PowerShell 5.1 turns redirected stderr from native commands into
        # terminating errors under 'Stop', so probe with 'Continue' and swallow failures.
        $ErrorActionPreference = 'Continue'
        try {
            $out = & $Command @Arguments 2>$null
            if ($LASTEXITCODE -eq 0 -and $out) { return ("$out").Trim() }
        } catch { }
        return $null
    }
    $python = $null
    if (Get-Command py -ErrorAction SilentlyContinue) {
        foreach ($v in '3.12', '3.11', '3.10') {
            $python = Find-Python py @("-$v", '-c', 'import sys; print(sys.executable)')
            if ($python) { break }
        }
    }
    if (-not $python -and (Get-Command python -ErrorAction SilentlyContinue)) {
        # 'python' may be the Microsoft Store alias stub, so check it actually runs and its version
        $python = Find-Python python @('-c', 'import sys; print(sys.executable if (3,10) <= sys.version_info[:2] <= (3,12) else "")')
    }
    if (-not $python) {
        Write-Host "Error: Python 3.10, 3.11 or 3.12 is required (mediapipe does not support newer versions yet)." -ForegroundColor Red
        Write-Host "   Install Python 3.12 from https://www.python.org/downloads/ and run this installer again."
        exit 1
    }
    Write-Host "Using $python"

    Write-Host "Downloading source..."
    $zip = Join-Path $env:TEMP "turtleneck-src.zip"
    $extracted = Join-Path $env:TEMP "turtleneck-main"
    Invoke-WebRequest -Uri "https://github.com/$repo/archive/refs/heads/main.zip" -OutFile $zip
    if (Test-Path $extracted) { Remove-Item -Recurse -Force $extracted }
    Expand-Archive -Path $zip -DestinationPath $env:TEMP -Force
    if (Test-Path $installDir) { Remove-Item -Recurse -Force $installDir }
    Move-Item "$extracted\Windows" $installDir
    Remove-Item -Recurse -Force $extracted, $zip

    Write-Host "Installing dependencies (this can take a few minutes)..."
    & $python -m pip install -q -r "$installDir\requirements.txt"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: installing dependencies failed. See the pip output above." -ForegroundColor Red
        exit 1
    }

    # pythonw runs without a console window
    $pythonw = Join-Path (Split-Path $python) "pythonw.exe"
    $target = if (Test-Path $pythonw) { $pythonw } else { $python }
    $arguments = "`"$installDir\main.py`""
}

# Desktop + Start menu shortcuts (the installer makes its own)
if (-not $shortcutsCreated) {
    New-Shortcut "$([Environment]::GetFolderPath('Desktop'))\TurtleNeck.lnk" $target $arguments
    New-Shortcut "$([Environment]::GetFolderPath('Programs'))\TurtleNeck.lnk" $target $arguments
}

Write-Host ""
Write-Host "TurtleNeck installed!" -ForegroundColor Green
Write-Host "Launching... look for the turtle in the system tray (^ near the clock)."
if ($arguments) {
    Start-Process -FilePath $target -ArgumentList $arguments -WorkingDirectory $installDir
} else {
    Start-Process -FilePath $target -WorkingDirectory $installDir
}
Write-Host ""
Write-Host "Support: https://ko-fi.com/kpryu" -ForegroundColor Cyan
