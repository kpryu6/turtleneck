# TurtleNeck Windows Installer
Write-Host "🐢 Installing TurtleNeck..." -ForegroundColor Green

$installDir = "$env:LOCALAPPDATA\TurtleNeck"
$repo = "https://github.com/kpryu6/TurtleNeck/archive/refs/heads/main.zip"
$zip = "$env:TEMP\turtleneck.zip"
$extracted = "$env:TEMP\TurtleNeck-main"

# Download
Write-Host "📥 Downloading..."
Invoke-WebRequest -Uri $repo -OutFile $zip

# Extract
Write-Host "📦 Extracting..."
Remove-Item -Recurse -Force $installDir -ErrorAction SilentlyContinue
Expand-Archive -Path $zip -DestinationPath $env:TEMP -Force
if (Test-Path $installDir) { Remove-Item -Recurse -Force $installDir }
Move-Item "$extracted\Windows" $installDir
Remove-Item -Recurse -Force $extracted -ErrorAction SilentlyContinue
Remove-Item $zip -ErrorAction SilentlyContinue

# Check Python
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    Write-Host "❌ Python not found. Install Python 3.10+ from https://python.org" -ForegroundColor Red
    Start-Process "https://python.org/downloads"
    exit 1
}

# Install dependencies
Write-Host "📦 Installing dependencies..."
python -m pip install --upgrade pip -q
python -m pip install -r "$installDir\requirements.txt" -q

# Create start script
$launcher = "$installDir\TurtleNeck.bat"
Set-Content $launcher "@echo off`npython `"$installDir\main.py`""

# Desktop shortcut
$desktop = [Environment]::GetFolderPath("Desktop")
$shortcut = "$desktop\TurtleNeck.lnk"
$ws = New-Object -ComObject WScript.Shell
$sc = $ws.CreateShortcut($shortcut)
$sc.TargetPath = $launcher
$sc.WorkingDirectory = $installDir
$sc.Description = "TurtleNeck - Posture Guardian"
$sc.Save()

Write-Host ""
Write-Host "✅ TurtleNeck installed!" -ForegroundColor Green
Write-Host "🐢 Launching..."
Start-Process python -ArgumentList "$installDir\main.py" -WorkingDirectory $installDir
Write-Host ""
Write-Host "☕ Support: https://ko-fi.com/kpryu" -ForegroundColor Cyan
