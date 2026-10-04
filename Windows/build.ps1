# Builds TurtleNeck.exe with PyInstaller and packages it as dist\TurtleNeck-Windows-x64.zip
# Usage (PowerShell, Python 3.10-3.12):  .\Windows\build.ps1
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

function Invoke-Checked {
    param([string]$File, [string[]]$Arguments)
    & $File @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$File $($Arguments -join ' ') failed with exit code $LASTEXITCODE" }
}

Write-Host "📦 Installing build dependencies..."
Invoke-Checked python @('-m', 'pip', 'install', '-q', '-r', 'requirements.txt', 'pyinstaller==6.11.1', 'pillow')

Write-Host "🎨 Generating icon..."
New-Item -ItemType Directory -Force build | Out-Null
Invoke-Checked python @('-c', @"
from PIL import Image
Image.open('../TurtleNeck/Resources/Assets.xcassets/AppIcon.appiconset/icon_256.png').save(
    'build/turtleneck.ico', sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
"@)

Write-Host "🔨 Building TurtleNeck.exe..."
# Absolute path: PyInstaller resolves relative --icon paths against --specpath
$icon = (Resolve-Path 'build\turtleneck.ico').Path
Invoke-Checked python @('-m', 'PyInstaller', '--noconfirm', '--clean', '--windowed',
    '--name', 'TurtleNeck',
    '--icon', $icon,
    # MediaPipe loads its .tflite / .binarypb model files at runtime
    '--collect-data', 'mediapipe',
    '--distpath', 'dist', '--workpath', 'build\pyinstaller', '--specpath', 'build',
    'main.py')

Write-Host "🧪 Smoke test..."
$env:QT_QPA_PLATFORM = 'offscreen'
$proc = Start-Process -FilePath 'dist\TurtleNeck\TurtleNeck.exe' -ArgumentList '--self-test' -Wait -PassThru
Remove-Item Env:\QT_QPA_PLATFORM
if ($proc.ExitCode -ne 0) { throw "Self-test failed with exit code $($proc.ExitCode)" }

Write-Host "🗜️ Packaging..."
$zip = 'dist\TurtleNeck-Windows-x64.zip'
Remove-Item $zip -ErrorAction SilentlyContinue
Compress-Archive -Path 'dist\TurtleNeck' -DestinationPath $zip
Write-Host "✅ $zip"
