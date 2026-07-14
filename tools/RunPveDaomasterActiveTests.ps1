param(
    [string]$GodotPath = "G:\Tools\godot\Godot_v4.7-stable_win64_console.exe"
)

$ErrorActionPreference = "Continue"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$LogDir = Join-Path $ProjectRoot ".godot_user"
$LogFile = Join-Path $LogDir "pve-daomaster-active-tests.log"
$ScenePath = "res://scenes/pve/TestPveDaomasterActives.tscn"

New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

$rawOutput = & $GodotPath --headless --path $ProjectRoot --log-file $LogFile $ScenePath 2>&1
$processExit = $LASTEXITCODE
$skipNextLocation = $false
$hasScriptError = $false
$hasTestError = $false
$filtered = New-Object System.Collections.Generic.List[string]

foreach ($lineObject in $rawOutput) {
    $line = [string]$lineObject

    if ($line -match "SCRIPT ERROR|Parse Error|Invalid call|Invalid access|Attempt to call") {
        $hasScriptError = $true
    }
    if ($line -match "\[TestPveDaomasterActives\] ERROR") {
        $hasTestError = $true
    }

    $isCleanupNoise = (
        $line -match "RID allocations .* were leaked at exit" -or
        $line -match "RIDs of type .* were leaked" -or
        $line -match "ObjectDB instances were leaked at exit" -or
        $line -match "resources still in use at exit"
    )

    if ($isCleanupNoise) {
        $skipNextLocation = $true
        continue
    }

    if ($skipNextLocation -and $line.TrimStart().StartsWith("at:")) {
        $skipNextLocation = $false
        continue
    }

    $skipNextLocation = $false
    $filtered.Add($line)
}

$filtered | ForEach-Object { Write-Output $_ }

if ($hasScriptError -or $hasTestError -or $processExit -ne 0) {
    exit 1
}

exit 0
