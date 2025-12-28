$script:tweakCategories = [ordered]@{
    "Essential Tweaks"          = @{
        Color  = $colors.Success
        Tweaks = @(
            @{Name = "Disable Telemetry"; ID = "DisableTelemetry"; Desc = "Disables Windows telemetry and data collection" },
            @{Name = "Disable Activity History"; ID = "DisableActivityHistory"; Desc = "Stops Windows from tracking your activity" },
            @{Name = "Disable GameDVR"; ID = "DisableGameDVR"; Desc = "Disables Xbox Game Bar DVR feature" },
            @{Name = "Disable Location Tracking"; ID = "DisableLocation"; Desc = "Disables location services and tracking" },
            @{Name = "Disable Wi-Fi Sense"; ID = "DisableWiFiSense"; Desc = "Disables Wi-Fi Sense hotspot sharing" },
            @{Name = "Enable End Task With Right Click"; ID = "EnableEndTask"; Desc = "Adds End Task option to taskbar right-click" },
            @{Name = "Run Disk Cleanup"; ID = "DiskCleanup"; Desc = "Runs Windows Disk Cleanup utility" },
            @{Name = "Disable PowerShell 7 Telemetry"; ID = "DisablePS7Tele"; Desc = "Disables PowerShell 7 telemetry" },
            @{Name = "Set Services to Manual"; ID = "SetServicesManual"; Desc = "Sets non-essential services to manual start" }
        )
    }
    "Advanced Tweaks - CAUTION" = @{
        Color  = $colors.Warning
        Tweaks = @(
            @{Name = "Disable Hibernation"; ID = "DisableHibernation"; Desc = "Disables hibernation (saves disk space)" },
            @{Name = "Disable IPv6"; ID = "DisableIPv6"; Desc = "Disables IPv6 on all network adapters" },
            @{Name = "Prefer IPv4 over IPv6"; ID = "PreferIPv4"; Desc = "Prioritizes IPv4 connections over IPv6" },
            @{Name = "Disable Teredo"; ID = "DisableTeredo"; Desc = "Disables Teredo tunneling" },
            @{Name = "Disable Recall"; ID = "DisableRecall"; Desc = "Disables Windows Recall AI feature" },
            @{Name = "Disable Microsoft Copilot"; ID = "DisableCopilot"; Desc = "Disables Microsoft Copilot" },
            @{Name = "Set Classic Right-Click Menu"; ID = "ClassicRightClick"; Desc = "Restores Windows 10 context menu" },
            @{Name = "Set Time to UTC (Dual Boot)"; ID = "SetUTC"; Desc = "Sets hardware clock to UTC for dual boot" },
            @{Name = "Remove Home from Explorer"; ID = "RemoveHome"; Desc = "Removes Home from File Explorer navigation" },
            @{Name = "Remove Gallery from Explorer"; ID = "RemoveGallery"; Desc = "Removes Gallery from File Explorer" },
            @{Name = "Remove OneDrive"; ID = "RemoveOneDrive"; Desc = "Uninstalls OneDrive completely" },
            @{Name = "Disable Background Apps"; ID = "DisableBackgroundApps"; Desc = "Prevents apps from running in background" },
            @{Name = "Disable Fullscreen Optimizations"; ID = "DisableFSO"; Desc = "Disables fullscreen optimizations globally" }
        )
    }
    "Customize Preferences"     = @{
        Color  = $colors.Accent
        Tweaks = @(
            @{Name = "Dark Theme for Windows"; ID = "DarkTheme"; Desc = "Enables system-wide dark theme" },
            @{Name = "Disable Bing Search in Start Menu"; ID = "DisableBingSearch"; Desc = "Removes Bing web search from Start" },
            @{Name = "NumLock on Startup"; ID = "NumLockStartup"; Desc = "Enables NumLock on login" },
            @{Name = "Show Hidden Files"; ID = "ShowHiddenFiles"; Desc = "Shows hidden files in Explorer" },
            @{Name = "Show File Extensions"; ID = "ShowFileExtensions"; Desc = "Shows file extensions in Explorer" },
            @{Name = "Disable Search Button in Taskbar"; ID = "DisableSearchButton"; Desc = "Hides Search from taskbar" },
            @{Name = "Disable Task View Button"; ID = "DisableTaskView"; Desc = "Hides Task View button from taskbar" },
            @{Name = "Center Taskbar Items"; ID = "CenterTaskbar"; Desc = "Centers taskbar icons (Windows 11)" },
            @{Name = "Disable Widgets Button"; ID = "DisableWidgets"; Desc = "Hides Widgets button from taskbar" },
            @{Name = "Detailed BSoD"; ID = "DetailedBSoD"; Desc = "Shows detailed info on Blue Screen" },
            @{Name = "Disable Mouse Acceleration"; ID = "DisableMouseAccel"; Desc = "Disables enhanced pointer precision" },
            @{Name = "Disable Sticky Keys"; ID = "DisableStickyKeys"; Desc = "Prevents Sticky Keys popup" }
        )
    }
}

$script:tweakFunctions = @{
    "RestorePoint"           = {
        Write-Log "Creating System Restore Point.. "
        try {
            Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
            Checkpoint-Computer -Description "Before Tweakr Changes" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
            Write-Log "[OK] Restore point created!" "OK"
        }
        catch {
            Write-Log "[WARN] Could not create restore point (may already exist today)" "WARN"
        }
    }

    "DisableTelemetry"       = {
        Write-Log "Disabling Telemetry.. "
        Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" 0
        Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0
        Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "DoNotShowFeedbackNotifications" 1
        Set-RegistryValue "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableTailoredExperiencesWithDiagnosticData" 1
        Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" "DisabledByGroupPolicy" 1

        $tasks = @(
            "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
            "Microsoft\Windows\Application Experience\ProgramDataUpdater",
            "Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
            "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
            "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
        )
        foreach ($task in $tasks) {
            Disable-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue | Out-Null
        }

        Stop-Service "DiagTrack" -Force -ErrorAction SilentlyContinue
        Set-Service "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue

        Write-Log "[OK] Telemetry disabled!" "OK"
    }

    "DisableActivityHistory" = {
        Write-Log "Disabling Activity History.. "
        Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "EnableActivityFeed" 0
        Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" 0
        Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "UploadUserActivities" 0
        Write-Log "[OK] Activity History disabled!" "OK"
    }

    "DisableGameDVR"         = {
        Write-Log "Disabling GameDVR.. "
        Set-RegistryValue "HKCU:\System\GameConfigStore" "GameDVR_FSEBehavior" 2
        Set-RegistryValue "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0
        Set-RegistryValue "HKCU:\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode" 1
        Set-RegistryValue "HKCU:\System\GameConfigStore" "GameDVR_EFSEFeatureFlags" 0
        Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 0
        Write-Log "[OK] GameDVR disabled!" "OK"
    }

    "DisableLocation"        = {
        Write-Log "Disabling Location Tracking.. "
        Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" "Value" "Deny" "String"
        Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" "SensorPermissionState" 0
        Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" "Status" 0
        Set-RegistryValue "HKLM:\SYSTEM\Maps" "AutoUpdateEnabled" 0
        Write-Log "[OK] Location tracking disabled!" "OK"
    }

    "DisableWiFiSense"       = {
        Write-Log "Disabling Wi-Fi Sense.. "
        Set-RegistryValue "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" "Value" 0
        Set-RegistryValue "HKLM:\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" "Value" 0
        Write-Log "[OK] Wi-Fi Sense disabled!" "OK"
    }

    "EnableEndTask"          = {
        Write-Log "Enabling End Task with Right Click.. "
        Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" "TaskbarEndTask" 1
        Write-Log "[OK] End Task enabled!" "OK"
    }

    "DiskCleanup"            = {
        Write-Log "Running Disk Cleanup.. "
        Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait -ErrorAction SilentlyContinue
        Write-Log "[OK] Disk Cleanup completed!" "OK"
    }

    "DisablePS7Tele"         = {
        Write-Log "Disabling PowerShell 7 Telemetry.. "
        [Environment]::SetEnvironmentVariable("POWERSHELL_TELEMETRY_OPTOUT", "1", "Machine")
        Write-Log "[OK] PowerShell 7 Telemetry disabled!" "OK"
    }

    "SetServicesManual"      = {
        Write-Log "Setting services to manual.. "
        $services = @("DiagTrack", "dmwappushservice", "MapsBroker", "RemoteRegistry", "RemoteAccess", "TrkWks")
        foreach ($svc in $services) {
            Set-Service -Name $svc -StartupType Manual -ErrorAction SilentlyContinue
        }
        Write-Log "[OK] Services set to manual!" "OK"
    }

    "DisableHibernation"     = {
        Write-Log "Disabling Hibernation.. "
        powercfg /h off
        Write-Log "[OK] Hibernation disabled!" "OK"
    }

    "DisableIPv6"            = {
        Write-Log "Disabling IPv6.. "
        Get-NetAdapterBinding -ComponentID ms_tcpip6 | Disable-NetAdapterBinding -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
        Write-Log "[OK] IPv6 disabled!" "OK"
    }

    "PreferIPv4"             = {
        Write-Log "Preferring IPv4 over IPv6.. "
        Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" "DisabledComponents" 32
        Write-Log "[OK] IPv4 preferred!" "OK"
    }

    "DisableTeredo"          = {
        Write-Log "Disabling Teredo.. "
        netsh interface teredo set state disabled | Out-Null
        Write-Log "[OK] Teredo disabled!" "OK"
    }

    "DisableRecall"          = {
        Write-Log "Disabling Windows Recall.. "
        Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" 1
        Set-RegistryValue "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" 1
        Write-Log "[OK] Recall disabled!" "OK"
    }

    "DisableCopilot"         = {
        Write-Log "Disabling Microsoft Copilot.. "
        Set-RegistryValue "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1
        Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1
        Write-Log "[OK] Copilot disabled!" "OK"
    }

    "ClassicRightClick"      = {
        Write-Log "Enabling Classic Right-Click Menu.. "
        $regPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
        New-Item -Path $regPath -Force | Out-Null
        Set-ItemProperty -Path $regPath -Name "(Default)" -Value "" -Force
        Write-Log "[OK] Classic menu enabled!" "OK"
    }

    "SetUTC"                 = {
        Write-Log "Setting hardware clock to UTC.. "
        Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" "RealTimeIsUniversal" 1
        Write-Log "[OK] UTC time set!" "OK"
    }

    "RemoveHome"             = {
        Write-Log "Removing Home from Explorer.. "
        Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" "HubMode" 1
        Write-Log "[OK] Home removed!" "OK"
    }

    "RemoveGallery"          = {
        Write-Log "Removing Gallery from Explorer.. "
        Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}" -Force -ErrorAction SilentlyContinue
        Write-Log "[OK] Gallery removed!" "OK"
    }

    "RemoveOneDrive"         = {
        Write-Log "Removing OneDrive.. "
        taskkill /f /im OneDrive.exe 2>$null
        Start-Sleep -Seconds 2

        $paths = @(
            "$env:SystemRoot\System32\OneDriveSetup.exe",
            "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
        )
        foreach ($path in $paths) {
            if (Test-Path $path) {
                Start-Process $path -ArgumentList "/uninstall" -Wait -ErrorAction SilentlyContinue
            }
        }
        Write-Log "[OK] OneDrive removed!" "OK"
    }

    "DisableBackgroundApps"  = {
        Write-Log "Disabling Background Apps.. "
        Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 1
        Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "BackgroundAppGlobalToggle" 0
        Write-Log "[OK] Background apps disabled!" "OK"
    }

    "DisableFSO"             = {
        Write-Log "Disabling Fullscreen Optimizations.. "
        Set-RegistryValue "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode" 2
        Set-RegistryValue "HKCU:\System\GameConfigStore" "GameDVR_DXGIHonorFSEWindowsCompatible" 1
        Write-Log "[OK] Fullscreen optimizations disabled!" "OK"
    }

    "DarkTheme"              = {
        Write-Log "Enabling Dark Theme.. "
        Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme" 0
        Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" "SystemUsesLightTheme" 0
        Write-Log "[OK] Dark theme enabled!" "OK"
    }

    "DisableBingSearch"      = {
        Write-Log "Disabling Bing Search in Start Menu.. "
        Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" 0
        Set-RegistryValue "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" "DisableSearchBoxSuggestions" 1
        Write-Log "[OK] Bing search disabled!" "OK"
    }

    "NumLockStartup"         = {
        Write-Log "Enabling NumLock on Startup.. "
        Set-RegistryValue "Registry::HKEY_USERS\.DEFAULT\Control Panel\Keyboard" "InitialKeyboardIndicators" "2" "String"
        Write-Log "[OK] NumLock enabled!" "OK"
    }

    "ShowHiddenFiles"        = {
        Write-Log "Showing Hidden Files.. "
        Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Hidden" 1
        Write-Log "[OK] Hidden files shown!" "OK"
    }

    "ShowFileExtensions"     = {
        Write-Log "Showing File Extensions.. "
        Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt" 0
        Write-Log "[OK] File extensions shown!" "OK"
    }

    "DisableSearchButton"    = {
        Write-Log "Disabling Search Button in Taskbar.. "
        Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" "SearchboxTaskbarMode" 0
        Write-Log "[OK] Search button hidden!" "OK"
    }

    "DisableTaskView"        = {
        Write-Log "Disabling Task View Button.. "
        Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowTaskViewButton" 0
        Write-Log "[OK] Task View hidden!" "OK"
    }

    "CenterTaskbar"          = {
        Write-Log "Centering Taskbar Items.. "
        Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAl" 1
        Write-Log "[OK] Taskbar centered!" "OK"
    }

    "DisableWidgets"         = {
        Write-Log "Disabling Widgets Button.. "
        Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarDa" 0
        Write-Log "[OK] Widgets hidden!" "OK"
    }

    "DetailedBSoD"           = {
        Write-Log "Enabling Detailed BSoD.. "
        Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" "DisplayParameters" 1
        Write-Log "[OK] Detailed BSoD enabled!" "OK"
    }

    "DisableMouseAccel"      = {
        Write-Log "Disabling Mouse Acceleration.. "
        Set-RegistryValue "HKCU:\Control Panel\Mouse" "MouseSpeed" "0" "String"
        Set-RegistryValue "HKCU:\Control Panel\Mouse" "MouseThreshold1" "0" "String"
        Set-RegistryValue "HKCU:\Control Panel\Mouse" "MouseThreshold2" "0" "String"
        Write-Log "[OK] Mouse acceleration disabled!" "OK"
    }

    "DisableStickyKeys"      = {
        Write-Log "Disabling Sticky Keys.. "
        Set-RegistryValue "HKCU:\Control Panel\Accessibility\StickyKeys" "Flags" "506" "String"
        Set-RegistryValue "HKCU:\Control Panel\Accessibility\Keyboard Response" "Flags" "122" "String"
        Set-RegistryValue "HKCU:\Control Panel\Accessibility\ToggleKeys" "Flags" "58" "String"
        Write-Log "[OK] Sticky Keys disabled!" "OK"
    }
}
