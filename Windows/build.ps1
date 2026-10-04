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

Write-Host "🔧 Normalizing the C++ runtime..."
# PyQt6 bundles an older msvcp140.dll. If that copy ends up in the bundle, MediaPipe's
# native module fails with "DLL initialization routine failed" no matter the import
# order. Replace every bundled MSVC runtime DLL with the newer system copy (the
# runtime is backward compatible and redistributable).
$sys32 = Join-Path $env:WINDIR 'System32'
Get-ChildItem 'dist\TurtleNeck' -Recurse -Include 'msvcp140*.dll', 'vcruntime140*.dll', 'concrt140.dll' | ForEach-Object {
    $src = Join-Path $sys32 $_.Name
    $before = $_.VersionInfo.FileVersion
    if (Test-Path $src) {
        $after = (Get-Item $src).VersionInfo.FileVersion
        if ([version]$after -gt [version]$before) { Copy-Item $src $_.FullName -Force }
        Write-Host "   $($_.FullName.Substring((Resolve-Path 'dist').Path.Length + 1)): $before -> $((Get-Item $_.FullName).VersionInfo.FileVersion)"
    }
}

Write-Host "🧪 Smoke test..."
$log = Join-Path (Resolve-Path 'build').Path 'self-test.log'
Remove-Item $log -ErrorAction SilentlyContinue
$env:QT_QPA_PLATFORM = 'offscreen'
$proc = Start-Process -FilePath 'dist\TurtleNeck\TurtleNeck.exe' -ArgumentList '--self-test', "`"$log`"" -PassThru
Remove-Item Env:\QT_QPA_PLATFORM
# A --windowed build shows a modal dialog on unhandled errors, which would hang CI
if (-not $proc.WaitForExit(120000)) {
    $proc | Stop-Process -Force
    if (Test-Path $log) { Get-Content $log }
    throw "Self-test timed out after 2 minutes"
}
if (Test-Path $log) { Get-Content $log }
if ($proc.ExitCode -ne 0) { throw "Self-test failed with exit code $($proc.ExitCode)" }

Write-Host "🗜️ Packaging..."
$zip = 'dist\TurtleNeck-Windows-x64.zip'
Remove-Item $zip -ErrorAction SilentlyContinue
Compress-Archive -Path 'dist\TurtleNeck' -DestinationPath $zip
Write-Host "✅ $zip"
