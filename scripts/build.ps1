param(
    [string]$Version,
    [switch]$SkipFormat,
    [switch]$WhatIf
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$srcDir = Join-Path $projectRoot "src"
$releaseDir = Join-Path $projectRoot "release"
$binDir = Join-Path $releaseDir "bin"

$configFile = Join-Path $srcDir "config.ps1"
$mainScript = Join-Path $srcDir "main.ps1"
$outputName = "tweakr-win64"
$outputExe = Join-Path $binDir "$outputName.exe"

$modules = @(
    "config.ps1",
    "functions.ps1",
    "ui-controls.ps1",
    "apps.ps1",
    "tweaks.ps1"
)

$configContent = Get-Content $configFile -Raw

if ($Version) {
    $configContent = $configContent -replace '\$script:appVersion\s*=\s*"[^"]*"', "`$script:appVersion = `"$Version`""
    Set-Content $configFile $configContent -NoNewline -Encoding UTF8
}

if (-not $Version) {
    $Version = "0.0.0"
    if ($configContent -match '\$script:appVersion\s*=\s*"([^"]*)"') {
        $Version = $matches[1]
    }
}

$buildTimer = [System.Diagnostics.Stopwatch]::StartNew()

Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  Tweakr Build Script v$Version" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

Write-Host "[1/5] Checking dependencies.. " -ForegroundColor DarkCyan

if (-not (Get-Module -ListAvailable -Name ps2exe)) {
    Write-Host "  Installing ps2exe.. " -ForegroundColor Gray
    Install-Module -Name ps2exe -Scope CurrentUser -Force
}
Write-Host "  ps2exe: OK" -ForegroundColor Green

if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    Write-Host "  Installing PSScriptAnalyzer.. " -ForegroundColor Gray
    Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
}
Write-Host "  PSScriptAnalyzer: OK" -ForegroundColor Green

$allFiles = @($mainScript) + ($modules | ForEach-Object { Join-Path $srcDir $_ })
$missingFiles = $allFiles | Where-Object { -not (Test-Path $_) }

if ($missingFiles.Count -gt 0) {
    Write-Host "[ERROR] Missing files:" -ForegroundColor Red
    $missingFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}

Write-Host "  All source files found: $($allFiles.Count) files" -ForegroundColor Green

Write-Host ""

if ($SkipFormat) {
    Write-Host "[2/5] Skipping formatting (--SkipFormat)" -ForegroundColor DarkGray
}

if (-not $SkipFormat) {
    Write-Host "[2/5] Formatting source files.. " -ForegroundColor DarkCyan

    foreach ($file in $allFiles) {
        $fileName = Split-Path $file -Leaf
        $content = Get-Content $file -Raw
        $content = $content -replace "`r`n", "`n" -replace "`r", "`n"

        try {
            $formatted = Invoke-Formatter -ScriptDefinition $content -Settings @{
                IncludeRules = @('*')
                Rules        = @{
                    PSUseConsistentIndentation = @{
                        Enable          = $true
                        IndentationSize = 4
                        Kind            = 'space'
                    }
                    PSUseConsistentWhitespace  = @{
                        Enable         = $true
                        CheckOpenBrace = $true
                        CheckOpenParen = $true
                        CheckOperator  = $false
                        CheckSeparator = $true
                    }
                }
            }

            $formatted = ($formatted -split "`n" | ForEach-Object { $_.TrimEnd() }) -join "`n"
            $formatted = $formatted -replace "(`n){3,}", "`n`n"
            $formatted = $formatted.Trim() + "`n"

            if ($WhatIf) { continue }

            Set-Content $file $formatted -NoNewline -Encoding UTF8
            Write-Host "  Formatted: $fileName" -ForegroundColor Gray
        }
        catch {
            Write-Host "  [WARN] Could not format $fileName - $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "[3/5] Running syntax check.. " -ForegroundColor DarkCyan

$hasErrors = $false

foreach ($file in $allFiles) {
    $fileName = Split-Path $file -Leaf
    $issues = Invoke-ScriptAnalyzer -Path $file -Severity Error

    if ($issues.Count -gt 0) {
        $hasErrors = $true
        Write-Host "  [ERROR] $fileName has $($issues.Count) error(s):" -ForegroundColor Red
        foreach ($issue in $issues) {
            Write-Host "    Line $($issue.Line): $($issue.Message)" -ForegroundColor Red
        }
        continue
    }

    Write-Host "  $fileName`: OK" -ForegroundColor Gray
}

if ($hasErrors) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  BUILD FAILED - Syntax errors found!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    exit 1
}

Write-Host "  All files passed syntax check" -ForegroundColor Green

Write-Host ""
Write-Host "[4/5] Bundling modules into single script.. " -ForegroundColor DarkCyan

$bundledContent = @"

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as Administrator!"
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

"@

$mainContent = Get-Content $mainScript -Raw
$mainContent = $mainContent -replace 'if \(-NOT.*\n.*\n.*\n.*exit\n\}', ''
$mainContent = $mainContent -replace 'Add-Type -AssemblyName System\.Windows\.Forms', ''
$mainContent = $mainContent -replace 'Add-Type -AssemblyName System\.Drawing', ''
$mainContent = $mainContent -replace '\. "\$scriptDir\\config\.ps1"', ''
$mainContent = $mainContent -replace '\. "\$scriptDir\\functions\.ps1"', ''
$mainContent = $mainContent -replace '\. "\$scriptDir\\ui-controls\.ps1"', ''
$mainContent = $mainContent -replace '\. "\$scriptDir\\apps\.ps1"', ''
$mainContent = $mainContent -replace '\. "\$scriptDir\\tweaks\.ps1"', ''
$mainContent = $mainContent -replace '\$scriptDir = Split-Path -Parent \$MyInvocation\.MyCommand\.Path', ''

foreach ($module in $modules) {
    $modulePath = Join-Path $srcDir $module
    $moduleContent = Get-Content $modulePath -Raw
    $bundledContent += "`n# === $module ===`n"
    $bundledContent += $moduleContent
}

$bundledContent += "`n# === main.ps1 ===`n"
$bundledContent += $mainContent
$bundledScript = Join-Path $releaseDir "Tweakr-Bundled.ps1"

if (-not (Test-Path $releaseDir)) {
    New-Item -ItemType Directory -Path $releaseDir -Force | Out-Null
}

if (-not $WhatIf) {
    # Use UTF8 without BOM for compatibility with irm | iex
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($bundledScript, $bundledContent, $utf8NoBom)
}

Write-Host "  Created: release/Tweakr-Bundled.ps1" -ForegroundColor Green

Write-Host ""
Write-Host "[5/5] Compiling to executable.. " -ForegroundColor DarkCyan

if (-not (Test-Path $binDir)) {
    New-Item -ItemType Directory -Path $binDir -Force | Out-Null
    Write-Host "  Created release/bin directory" -ForegroundColor Gray
}

$ps2exeParams = @{
    InputFile    = $bundledScript
    OutputFile   = $outputExe
    NoConsole    = $false
    RequireAdmin = $true
    Title        = "Tweakr"
    Description  = "Windows Setup & Tweaks Tool"
    Company      = "Tweakr"
    Product      = "Tweakr"
    Version      = $Version
    Copyright    = "MIT License"
}

if ($WhatIf) {
    Write-Host "  [WhatIf] Would compile to: $outputExe" -ForegroundColor Magenta
    exit 0
}

if (Test-Path $outputExe) {
    try {
        $stream = [System.IO.File]::Open($outputExe, 'Open', 'Write')
        $stream.Close()
    }
    catch {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "  BUILD FAILED!" -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "  The exe is locked (probably running)." -ForegroundColor Yellow
        Write-Host "  Close tweakr-win64.exe and try again." -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }
}

try {
    Invoke-ps2exe @ps2exeParams -ErrorAction Stop
}
catch {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  BUILD FAILED!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    exit 1
}

$buildTimer.Stop()
$elapsed = $buildTimer.Elapsed

$timeStr = "{0:N0} ms" -f $elapsed.TotalMilliseconds
if ($elapsed.TotalSeconds -ge 1) {
    $timeStr = "{0:N2} s" -f $elapsed.TotalSeconds
}
if ($elapsed.TotalMinutes -ge 1) {
    $timeStr = "{0:N0} m {1:N0} s" -f [Math]::Floor($elapsed.TotalMinutes), $elapsed.Seconds
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  BUILD SUCCESSFUL!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Output: $outputExe" -ForegroundColor Gray
Write-Host "  Version: $Version" -ForegroundColor Gray
Write-Host "  Size: $([math]::Round((Get-Item $outputExe).Length / 1KB, 1)) KB" -ForegroundColor Gray
Write-Host ""
Write-Host "$timeStr" -ForegroundColor DarkGray
Write-Host ""
