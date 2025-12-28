<#
.SYNOPSIS
    Writes a timestamped log message to the console.
.DESCRIPTION
    Outputs a colored, timestamped message to the console and refreshes the UI form if available.
.PARAMETER Message
    The message to log.
.PARAMETER Level
    The log level: INFO, OK, WARN, or ERROR. Determines the output color.
.EXAMPLE
    Write-Log "Operation completed" "OK"
#>
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "HH:mm:ss"
    $consoleColor = switch ($Level) {
        "OK" { "Green" }
        "WARN" { "Yellow" }
        "ERROR" { "Red" }
        default { "Cyan" }
    }

    Write-Host "[$timestamp] $Message" -ForegroundColor $consoleColor

    if ($null -eq $script:form) { return }
    $script:form.Refresh()
}

<#
.SYNOPSIS
    Sets a Windows registry value, creating the path if necessary.
.DESCRIPTION
    Creates the registry path if it doesn't exist and sets the specified value.
    Handles errors gracefully and returns success/failure status.
.PARAMETER Path
    The full registry path (e.g., "HKLM:\SOFTWARE\MyApp").
.PARAMETER Name
    The name of the registry value to set.
.PARAMETER Value
    The value to assign.
.PARAMETER Type
    The registry value type: String, DWord, QWord, Binary, etc. Defaults to DWord.
.OUTPUTS
    Boolean indicating success or failure.
.EXAMPLE
    Set-RegistryValue "HKCU:\Software\MyApp" "Setting" 1 "DWord"
#>
function Set-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        $Value,
        [string]$Type = "DWord"
    )

    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }

        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction Stop
        Write-Host "Set $Path\$Name to $Value" -ForegroundColor DarkGray
        return $true
    }
    catch {
        Write-Host "[WARN] Could not set $Path\$Name" -ForegroundColor Yellow
        return $false
    }
}
