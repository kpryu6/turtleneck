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
Invoke-Checked python @('-m', 'pip', 'install', '-q', '-r', 'requirements.txt', 'pillow', 'wheel')

# PyInstaller's prebuilt bootloader (the small launcher inside every PyInstaller .exe) is
# shared with a lot of malware, so antivirus engines often flag unsigned apps that use it
# (Windows Defender blocked TurtleNeck.exe with "CreateProcess failed; code 225").
# Compiling the bootloader ourselves gives the .exe its own launcher. Needs MSVC.
Write-Host "🔧 Building PyInstaller with a locally compiled bootloader..."
$env:PYINSTALLER_COMPILE_BOOTLOADER = '1'
Invoke-Checked python @('-m', 'pip', 'install', '-q', '--force-reinstall', '--no-cache-dir',
    '--no-binary', 'pyinstaller', 'pyinstaller==6.11.1')
Remove-Item Env:\PYINSTALLER_COMPILE_BOOTLOADER
$runw = python -c "import os, PyInstaller; print(os.path.join(os.path.dirname(PyInstaller.__file__), 'bootloader', 'Windows-64bit-intel', 'runw.exe'))"
Write-Host "   bootloader: $runw ($((Get-Item $runw).LastWriteTime), sha256 $((Get-FileHash $runw).Hash.Substring(0, 16))...)"

Write-Host "🎨 Generating icon..."
New-Item -ItemType Directory -Force build | Out-Null
Invoke-Checked python @('-c', @"
from PIL import Image
Image.open('../TurtleNeck/Resources/Assets.xcassets/AppIcon.appiconset/icon_256.png').save(
    'build/turtleneck.ico', sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
"@)

# Version comes from project.yml, the single source of truth for both platforms
$version = (Select-String -Path '..\project.yml' -Pattern '^\s*MARKETING_VERSION:\s*"([^"]+)"').Matches[0].Groups[1].Value
$v = ($version.Split('.') + @('0', '0', '0'))[0..3] -join ', '

# Windows version resource: company, product and description show up in the file's
# Properties and help antivirus heuristics (an .exe with no metadata looks suspicious)
@"
VSVersionInfo(
  ffi=FixedFileInfo(filevers=($v), prodvers=($v), mask=0x3f, flags=0x0, OS=0x40004,
                    fileType=0x1, subtype=0x0, date=(0, 0)),
  kids=[
    StringFileInfo([StringTable('040904B0', [
      StringStruct('CompanyName', 'kpryu6'),
      StringStruct('FileDescription', 'TurtleNeck - posture reminder'),
      StringStruct('FileVersion', '$version'),
      StringStruct('InternalName', 'TurtleNeck'),
      StringStruct('LegalCopyright', 'Copyright (c) kpryu6. MIT License.'),
      StringStruct('OriginalFilename', 'TurtleNeck.exe'),
      StringStruct('ProductName', 'TurtleNeck'),
      StringStruct('ProductVersion', '$version')])]),
    VarFileInfo([VarStruct('Translation', [1033, 1200])])
  ]
)
"@ | Set-Content -Encoding ascii 'build\version_info.txt'

Write-Host "🔨 Building TurtleNeck.exe v$version..."
# Absolute paths: PyInstaller resolves relative paths against --specpath
$icon = (Resolve-Path 'build\turtleneck.ico').Path
$versionFile = (Resolve-Path 'build\version_info.txt').Path
Invoke-Checked python @('-m', 'PyInstaller', '--noconfirm', '--clean', '--windowed',
    '--name', 'TurtleNeck',
    '--icon', $icon,
    '--version-file', $versionFile,
    '--noupx',
    # MediaPipe loads its .tflite / .binarypb model files at runtime
    '--collect-data', 'mediapipe',
    '--add-data', "$(Resolve-Path 'turtleneck\resources\icon.png');turtleneck\resources",
    '--distpath', 'dist', '--workpath', 'build\pyinstaller', '--specpath', 'build',
    'main.py')

Write-Host "🔧 Normalizing the C++ runtime..."
# PyQt6 bundles an older msvcp140.dll. If that copy ends up in the bundle, MediaPipe's
# native module fails with "DLL initialization routine failed" no matter the import
# order. Replace every bundled MSVC runtime DLL with the newer system copy (the
# runtime is backward compatible and redistributable).
function Get-FileVersion([System.IO.FileInfo]$File) {
    # FileVersion strings can carry suffixes ("14.26.28720.3 built by: vcwrkspc"); use the numeric parts
    $v = $File.VersionInfo
    [version]::new($v.FileMajorPart, $v.FileMinorPart, $v.FileBuildPart, $v.FilePrivatePart)
}
$sys32 = Join-Path $env:WINDIR 'System32'
$distRoot = (Resolve-Path 'dist').Path
Get-ChildItem 'dist\TurtleNeck' -Recurse -Include 'msvcp140*.dll', 'vcruntime140*.dll', 'concrt140.dll' | ForEach-Object {
    $src = Join-Path $sys32 $_.Name
    if (Test-Path $src) {
        $before = Get-FileVersion $_
        $newer = Get-FileVersion (Get-Item $src)
        if ($newer -gt $before) { Copy-Item $src $_.FullName -Force }
        $after = Get-FileVersion (Get-Item $_.FullName)
        Write-Host "   $($_.FullName.Substring($distRoot.Length + 1)): $before -> $after"
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

Write-Host "Building installer..."
$iscc = @(
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "$env:ProgramFiles\Inno Setup 6\ISCC.exe",
    "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iscc) { $iscc = (Get-Command iscc -ErrorAction SilentlyContinue).Source }
if (-not $iscc) { throw "Inno Setup 6 not found. Install it with: winget install JRSoftware.InnoSetup" }
Invoke-Checked $iscc @('/Qp', "/DAppVersion=$version", 'installer.iss')
Write-Host "Done: dist\TurtleNeck-Setup.exe (v$version)"
