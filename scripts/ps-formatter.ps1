param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Path,

    [int]$IndentSize = 4,

    [switch]$WhatIf
)
if (-not (Test-Path $Path)) {
    Write-Host "[ERROR] File not found: $Path" -ForegroundColor Red
    exit 1
}

$resolvedPath = Resolve-Path $Path
$module = Get-Module -ListAvailable -Name PSScriptAnalyzer

if (-not $module) {
    Write-Host "[INFO] PSScriptAnalyzer not found. Installing.. " -ForegroundColor Yellow

    try {
        Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser -ErrorAction Stop
        Write-Host "[OK] PSScriptAnalyzer installed successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "[ERROR] Failed to install PSScriptAnalyzer: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

Import-Module PSScriptAnalyzer -ErrorAction SilentlyContinue
Write-Host "[INFO] Reading: $resolvedPath" -ForegroundColor Cyan
$content = Get-Content $resolvedPath -Raw
$settings = @{
    IncludeRules = @(
        'PSPlaceOpenBrace'
        'PSPlaceCloseBrace'
        'PSUseConsistentWhitespace'
        'PSUseConsistentIndentation'
        'PSAlignAssignmentStatement'
    )
    Rules        = @{
        PSUseConsistentIndentation = @{
            Enable              = $true
            IndentationSize     = $IndentSize
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            Kind                = 'space'
        }
        PSUseConsistentWhitespace  = @{
            Enable                          = $true
            CheckOpenBrace                  = $true
            CheckOpenParen                  = $true
            CheckOperator                   = $true
            CheckSeparator                  = $true
            CheckInnerBrace                 = $true
            CheckPipe                       = $true
            CheckPipeForRedundantWhitespace = $true
        }
        PSPlaceOpenBrace           = @{
            Enable             = $true
            OnSameLine         = $true
            NewLineAfter       = $true
            IgnoreOneLineBlock = $true
        }
        PSPlaceCloseBrace          = @{
            Enable             = $true
            NewLineAfter       = $true
            IgnoreOneLineBlock = $true
        }
        PSAlignAssignmentStatement = @{
            Enable         = $true
            CheckHashtable = $true
        }
    }
}
Write-Host "[INFO] Formatting with $IndentSize-space indentation.. " -ForegroundColor Cyan

try {
    $formatted = Invoke-Formatter -ScriptDefinition $content -Settings $settings
}
catch {
    Write-Host "[ERROR] Formatting failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Write-Host "[INFO] Cleaning excessive whitespace.. " -ForegroundColor Cyan
$cleaned = $formatted -replace '(\r?\n){3,}', "`n`n"
$lines = $cleaned -split "`n"
$trimmed = ($lines | ForEach-Object { $_.TrimEnd() }) -join "`n"
$final = $trimmed.TrimEnd() + "`n"

if ($WhatIf) {
    Write-Host "[WHATIF] Would write formatted content to: $resolvedPath" -ForegroundColor Yellow
    Write-Host "[WHATIF] Original: $($content.Length) chars -> Formatted: $($final.Length) chars" -ForegroundColor Yellow
    exit 0
}
$final | Set-Content $resolvedPath -Encoding UTF8 -NoNewline

Write-Host "[OK] Formatted successfully: $resolvedPath" -ForegroundColor Green
Write-Host "Original: $($content.Length) chars -> Formatted: $($final.Length) chars" -ForegroundColor Gray
