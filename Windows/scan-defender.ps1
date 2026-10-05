# Scans a folder or file with Microsoft Defender Antivirus using the latest signatures.
# Exits 2 if anything is detected, 0 if clean.
# Usage: .\Windows\scan-defender.ps1 <path>
# Keep this file ASCII-only.
param([Parameter(Mandatory = $true)][string]$Path)
$ErrorActionPreference = 'Stop'

$target = (Resolve-Path $Path).Path
$mp = Join-Path $env:ProgramFiles 'Windows Defender\MpCmdRun.exe'
if (-not (Test-Path $mp)) { throw "Microsoft Defender (MpCmdRun.exe) is not available on this machine" }

Write-Host "Updating Defender signatures..."
& $mp -SignatureUpdate | Out-Null
$status = Get-MpComputerStatus
Write-Host ("Defender engine {0}, antivirus signatures {1} ({2})" -f $status.AMEngineVersion, $status.AntivirusSignatureVersion, $status.AntivirusSignatureLastUpdated)

$started = Get-Date
Write-Host "Scanning $target ..."
& $mp -Scan -ScanType 3 -File $target -DisableRemediation
$code = $LASTEXITCODE

# MpCmdRun: 0 = no threats, 2 = threats found
$found = Get-MpThreatDetection -ErrorAction SilentlyContinue | Where-Object { $_.InitialDetectionTime -ge $started.AddMinutes(-1) }
foreach ($d in $found) {
    $threat = Get-MpThreat -ThreatID $d.ThreatID -ErrorAction SilentlyContinue
    Write-Host ("DETECTED: {0} in {1}" -f $threat.ThreatName, ($d.Resources -join ', '))
}

if ($code -eq 2 -or $found) {
    Write-Host "Defender flagged files in $target" -ForegroundColor Red
    exit 2
}
if ($code -ne 0) { throw "MpCmdRun exited with $code" }
Write-Host "Defender: no threats found" -ForegroundColor Green
exit 0
