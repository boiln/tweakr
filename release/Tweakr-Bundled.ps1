
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as Administrator!"
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File "D:\my-shit\a-tweakr\scripts\build.ps1"" -Verb RunAs
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# === config.ps1 ===
$script:appVersion = "1.0.0"

$script:colors = @{
    # Base colors - Softer dark theme, easier on the eyes
    Background      = [System.Drawing.Color]::FromArgb(24, 28, 33)       # Soft dark
    Surface         = [System.Drawing.Color]::FromArgb(32, 36, 42)       # Slightly lighter
    SurfaceLight    = [System.Drawing.Color]::FromArgb(42, 47, 55)       # Card backgrounds
    SurfaceBorder   = [System.Drawing.Color]::FromArgb(52, 58, 68)       # Subtle borders

    # Brand colors - Muted teal/cyan, gentle on eyes
    Primary         = [System.Drawing.Color]::FromArgb(86, 182, 170)     # Soft muted teal
    PrimaryDark     = [System.Drawing.Color]::FromArgb(72, 158, 148)     # Darker muted teal
    PrimaryMuted    = [System.Drawing.Color]::FromArgb(45, 65, 62)       # Very subtle teal bg
    Accent          = [System.Drawing.Color]::FromArgb(130, 170, 210)    # Soft muted blue

    # Text colors - Softer contrast
    Text            = [System.Drawing.Color]::FromArgb(210, 215, 220)    # Soft off-white
    TextSecondary   = [System.Drawing.Color]::FromArgb(140, 150, 165)    # Muted gray
    TextMuted       = [System.Drawing.Color]::FromArgb(95, 105, 120)     # Very muted

    # Status colors - Gentler, desaturated
    Success         = [System.Drawing.Color]::FromArgb(98, 178, 140)     # Soft sage green
    SuccessMuted    = [System.Drawing.Color]::FromArgb(38, 52, 46)       # Muted green bg
    Warning         = [System.Drawing.Color]::FromArgb(210, 170, 100)    # Soft amber
    WarningMuted    = [System.Drawing.Color]::FromArgb(55, 48, 38)       # Muted amber bg
    Danger          = [System.Drawing.Color]::FromArgb(200, 120, 120)    # Soft rose
    DangerMuted     = [System.Drawing.Color]::FromArgb(55, 40, 42)       # Muted red bg

    # Category colors - Softer, pastel-like
    CategoryBrowser = [System.Drawing.Color]::FromArgb(120, 160, 200)    # Soft blue
    CategoryDev     = [System.Drawing.Color]::FromArgb(165, 140, 190)    # Soft lavender
    CategoryComm    = [System.Drawing.Color]::FromArgb(100, 170, 165)    # Soft teal
    CategoryUtil    = [System.Drawing.Color]::FromArgb(195, 165, 110)    # Soft gold
    CategoryRuntime = [System.Drawing.Color]::FromArgb(110, 170, 135)    # Soft mint

    # UI component colors
    ToggleOff       = [System.Drawing.Color]::FromArgb(50, 56, 65)       # Soft toggle track
    ToggleKnob      = [System.Drawing.Color]::FromArgb(120, 130, 145)    # Muted knob
    ToggleKnobHover = [System.Drawing.Color]::FromArgb(140, 150, 165)
    ToggleKnobActive= [System.Drawing.Color]::FromArgb(160, 170, 185)
    ScrollTrack     = [System.Drawing.Color]::FromArgb(32, 36, 42)
    ScrollThumb     = [System.Drawing.Color]::FromArgb(55, 62, 72)
    ScrollThumbHover= [System.Drawing.Color]::FromArgb(70, 78, 90)

    # Button colors
    ButtonPrimary   = [System.Drawing.Color]::FromArgb(86, 182, 170)
    ButtonSecondary = [System.Drawing.Color]::FromArgb(42, 47, 55)
    ButtonHover     = [System.Drawing.Color]::FromArgb(52, 58, 68)
}

$script:fonts = @{
    Title    = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
    Header   = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
    Category = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    Normal   = New-Object System.Drawing.Font("Segoe UI", 9)
    Small    = New-Object System.Drawing.Font("Segoe UI", 8)
    Button   = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
}

# === functions.ps1 ===
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

# === ui-controls.ps1 ===
function Add-DarkScrollbar {
    param(
        [System.Windows.Forms.Panel]$Panel,
        [int]$ContentHeight
    )

    $visibleHeight = if ($Panel.Parent) { $Panel.Parent.Height } else { $Panel.Height }
    $visibleRatio = [Math]::Min(1.0, $visibleHeight / [Math]::Max(1, $ContentHeight))
    $thumbHeight = [Math]::Max(40, [int](($visibleHeight - 10) * $visibleRatio))

    $scrollTrack = New-Object System.Windows.Forms.Panel
    $scrollTrack.Size = New-Object System.Drawing.Size(8, ($visibleHeight - 10))
    $scrollTrack.Location = New-Object System.Drawing.Point(795, 5)
    $scrollTrack.BackColor = $colors.ScrollTrack
    $scrollTrack.Anchor = 'Top, Right, Bottom'

    $scrollThumb = New-Object System.Windows.Forms.Panel
    $scrollThumb.Size = New-Object System.Drawing.Size(6, $thumbHeight)
    $scrollThumb.Location = New-Object System.Drawing.Point(1, 0)
    $scrollThumb.BackColor = $colors.ScrollThumb
    $scrollThumb.Cursor = 'Hand'
    $scrollTrack.Controls.Add($scrollThumb)

    $scrollState = @{
        IsDragging    = $false
        DragStartY    = 0
        ThumbStartY   = 0
        ContentHeight = $ContentHeight
        VisibleHeight = $visibleHeight
        Panel         = $Panel
        Track         = $scrollTrack
        Thumb         = $scrollThumb
    }

    $scrollThumb.Tag = $scrollState
    $scrollTrack.Tag = $scrollState
    $Panel.Tag = $scrollState

    $scrollThumb.Add_MouseDown({
            param($sender, $e)
            $state = $sender.Tag
            $state.IsDragging = $true
            $state.DragStartY = [System.Windows.Forms.Cursor]::Position.Y
            $state.ThumbStartY = $sender.Location.Y
            $sender.BackColor = $colors.ToggleKnobActive
        })

    $scrollThumb.Add_MouseUp({
            param($sender, $e)
            $sender.Tag.IsDragging = $false
            $sender.BackColor = $colors.ScrollThumbHover
        })

    $scrollThumb.Add_MouseMove({
            param($sender, $e)
            $state = $sender.Tag
            if (-not $state.IsDragging) { return }

            $currentY = [System.Windows.Forms.Cursor]::Position.Y
            $deltaY = $currentY - $state.DragStartY
            $newThumbY = [Math]::Max(0, [Math]::Min($state.Track.Height - $sender.Height, $state.ThumbStartY + $deltaY))
            $sender.Location = New-Object System.Drawing.Point(1, $newThumbY)

            $scrollRatio = $newThumbY / [Math]::Max(1, ($state.Track.Height - $sender.Height))
            $maxScroll = [Math]::Max(0, $state.ContentHeight - $state.VisibleHeight)
            $scrollPos = [int]($scrollRatio * $maxScroll)
            $state.Panel.AutoScrollPosition = New-Object System.Drawing.Point(0, $scrollPos)
        })

    $scrollTrack.Add_MouseDown({
            param($sender, $e)
            $state = $sender.Tag
            $thumb = $state.Thumb
            $clickY = $e.Location.Y

            $newThumbY = [Math]::Max(0, [Math]::Min($sender.Height - $thumb.Height, $clickY - ($thumb.Height / 2)))
            $thumb.Location = New-Object System.Drawing.Point(1, $newThumbY)

            $scrollRatio = $newThumbY / [Math]::Max(1, ($sender.Height - $thumb.Height))
            $maxScroll = [Math]::Max(0, $state.ContentHeight - $state.VisibleHeight)
            $scrollPos = [int]($scrollRatio * $maxScroll)
            $state.Panel.AutoScrollPosition = New-Object System.Drawing.Point(0, $scrollPos)
        })

    $scrollThumb.Add_MouseEnter({
            param($sender, $e)
            $sender.BackColor = $colors.ScrollThumbHover
        })

    $scrollThumb.Add_MouseLeave({
            param($sender, $e)
            if ($sender.Tag.IsDragging) { return }
            $sender.BackColor = $colors.ScrollThumb
        })

    $syncTimer = New-Object System.Windows.Forms.Timer
    $syncTimer.Interval = 16
    $syncTimer.Tag = $scrollState

    $syncTimer.Add_Tick({
            param($sender, $e)
            $state = $sender.Tag

            if ($null -eq $state -or $state.IsDragging) { return }

            $scrollPos = - $state.Panel.AutoScrollPosition.Y
            $maxScroll = [Math]::Max(1, $state.ContentHeight - $state.VisibleHeight)
            $scrollRatio = [Math]::Min(1.0, $scrollPos / $maxScroll)
            $maxThumbY = $state.Track.Height - $state.Thumb.Height
            $newThumbY = [int]($scrollRatio * $maxThumbY)
            $currentY = $state.Thumb.Location.Y

            if ([Math]::Abs($currentY - $newThumbY) -le 1) { return }

            $state.Thumb.Location = New-Object System.Drawing.Point(1, [Math]::Max(0, [Math]::Min($maxThumbY, $newThumbY)))
        })

    $syncTimer.Start()
    $scrollState.Timer = $syncTimer

    $Panel.Controls.Add($scrollTrack)
    $scrollTrack.BringToFront()

    return $scrollState
}

function New-ToggleSwitch {
    param(
        [string]$Text,
        [object]$Tag,
        [int]$X = 0,
        [int]$Y = 0,
        [int]$Width = 350,
        [scriptblock]$OnChange
    )

    $container = New-Object System.Windows.Forms.Panel
    $container.Location = New-Object System.Drawing.Point($X, $Y)
    $container.Size = New-Object System.Drawing.Size($Width, 22)
    $container.BackColor = [System.Drawing.Color]::Transparent

    $track = New-Object System.Windows.Forms.Panel
    $track.Size = New-Object System.Drawing.Size(36, 18)
    $track.Location = New-Object System.Drawing.Point(0, 2)
    $track.BackColor = $colors.ToggleOff
    $track.Cursor = 'Hand'

    $knob = New-Object System.Windows.Forms.Panel
    $knob.Size = New-Object System.Drawing.Size(14, 14)
    $knob.Location = New-Object System.Drawing.Point(2, 2)
    $knob.BackColor = $colors.ToggleKnob
    $knob.Cursor = 'Hand'
    $track.Controls.Add($knob)
    $container.Controls.Add($track)

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Text
    $label.Font = $fonts.Normal
    $label.ForeColor = $colors.Text
    $label.Location = New-Object System.Drawing.Point(44, 3)
    $label.Size = New-Object System.Drawing.Size(($Width - 50), 16)
    $label.Cursor = 'Hand'
    $container.Controls.Add($label)

    $stateData = @{
        Checked     = $false
        OriginalTag = $Tag
        OnChange    = $OnChange
        Track       = $track
        Knob        = $knob
        Container   = $container
        Label       = $label
    }

    $container.Tag = $stateData
    $track.Tag = $stateData
    $knob.Tag = $stateData
    $label.Tag = $stateData

    $clickHandler = {
        param($sender, $e)
        $state = $sender.Tag

        if ($null -eq $state -or $null -eq $state.Track) { return }

        $state.Checked = -not $state.Checked
        $trk = $state.Track
        $knb = $state.Knob
        $lbl = $state.Label

        if (-not $state.Checked) {
            $trk.BackColor = $colors.ToggleOff
            $knb.BackColor = $colors.ToggleKnob
            $knb.Location = New-Object System.Drawing.Point(2, 2)
            $lbl.ForeColor = $colors.Text
            if ($null -ne $state.OnChange) { try { & $state.OnChange } catch {} }
            return
        }

        $trk.BackColor = $colors.Primary
        $knb.BackColor = $colors.Text
        $knb.Location = New-Object System.Drawing.Point(20, 2)
        $lbl.ForeColor = $colors.Primary
        if ($null -ne $state.OnChange) { try { & $state.OnChange } catch {} }
    }

    $track.Add_Click($clickHandler)
    $knob.Add_Click($clickHandler)
    $label.Add_Click($clickHandler)

    $container | Add-Member -MemberType ScriptProperty -Name "Checked" -Value {
        $this.Tag.Checked
    } -SecondValue {
        param($value)
        $this.Tag.Checked = $value
        $trk = $this.Tag.Track
        $knb = $this.Tag.Knob
        $lbl = $this.Tag.Label

        if (-not $value) {
            $trk.BackColor = $colors.ToggleOff
            $knb.BackColor = $colors.ToggleKnob
            $knb.Location = New-Object System.Drawing.Point(2, 2)
            $lbl.ForeColor = $colors.Text
            return
        }

        $trk.BackColor = $colors.Primary
        $knb.BackColor = $colors.Text
        $knb.Location = New-Object System.Drawing.Point(20, 2)
        $lbl.ForeColor = $colors.Primary
    }

    $container | Add-Member -MemberType ScriptProperty -Name "OriginalTag" -Value {
        $this.Tag.OriginalTag
    }

    return $container
}

function New-ModernProgressBar {
    param(
        [int]$X = 0,
        [int]$Y = 0,
        [int]$Width = 640,
        [int]$Height = 4
    )

    $container = New-Object System.Windows.Forms.Panel
    $container.Location = New-Object System.Drawing.Point($X, $Y)
    $container.Size = New-Object System.Drawing.Size($Width, $Height)
    $container.BackColor = $colors.SurfaceLight
    $container.Visible = $false

    $fill = New-Object System.Windows.Forms.Panel
    $fill.Location = New-Object System.Drawing.Point(0, 0)
    $fill.Size = New-Object System.Drawing.Size(0, $Height)
    $fill.BackColor = $colors.Primary
    $fill.Name = "ProgressFill"
    $container.Controls.Add($fill)

    $container.Tag = @{
        Value   = 0
        Maximum = 100
        Width   = $Width
        Height  = $Height
    }

    return $container
}

function Set-ProgressBarValue {
    param(
        [System.Windows.Forms.Panel]$ProgressBar,
        [int]$Value
    )

    if ($null -eq $ProgressBar -or $null -eq $ProgressBar.Tag) { return }

    $ProgressBar.Tag.Value = $Value
    $ratio = $Value / [Math]::Max(1, $ProgressBar.Tag.Maximum)
    $newWidth = [int]($ProgressBar.Tag.Width * $ratio)

    $fill = $ProgressBar.Controls["ProgressFill"]
    if ($null -eq $fill) { return }

    $fill.Size = New-Object System.Drawing.Size($newWidth, $ProgressBar.Tag.Height)
}

function Set-ProgressBarMaximum {
    param(
        [System.Windows.Forms.Panel]$ProgressBar,
        [int]$Maximum
    )

    if ($null -eq $ProgressBar -or $null -eq $ProgressBar.Tag) { return }

    $ProgressBar.Tag.Maximum = $Maximum
}

# === apps.ps1 ===
$script:categories = [ordered]@{
    "Browsers"             = @{
        Color = $colors.CategoryBrowser
        Apps  = @(
            @{Name = "Brave Browser"; ID = "Brave.Brave"; Type = "winget"; Desc = "Privacy-focused browser" },
            @{Name = "Mozilla Firefox"; ID = "Mozilla.Firefox"; Type = "winget"; Desc = "Open-source browser" }
        )
    }
    "Communication"        = @{
        Color = $colors.CategoryComm
        Apps  = @(
            @{Name = "Discord"; ID = "Discord.Discord"; Type = "winget"; Desc = "Voice & text chat" },
            @{Name = "Discord Canary"; ID = "Discord.Discord.Canary"; Type = "winget"; Desc = "Discord beta version" }
        )
    }
    "Development Tools"    = @{
        Color = $colors.CategoryDev
        Apps  = @(
            @{Name = "Git"; ID = "Git.Git"; Type = "winget"; Desc = "Version control system" },
            @{Name = "Visual Studio Code"; ID = "Microsoft.VisualStudioCode"; Type = "winget"; Desc = "Code editor" },
            @{Name = "GitHub Desktop"; ID = "GitHub.GitHubDesktop"; Type = "winget"; Desc = "Git GUI client" },
            @{Name = "VS 2022 Build Tools"; ID = "Microsoft.VisualStudio.2022.BuildTools"; Type = "winget"; Desc = "C++ build tools" },
            @{Name = "VS Installer"; ID = "Microsoft.VisualStudio.Installer"; Type = "winget"; Desc = "Visual Studio installer" }
        )
    }
    "Languages & Runtimes" = @{
        Color = $colors.CategoryRuntime
        Apps  = @(
            @{Name = "Python 3.12.9"; ID = "Python.Python.3.12"; Type = "custom"; URL = "https://www.python.org/ftp/python/3.12.9/python-3.12.9-amd64.exe"; Desc = "Python interpreter" },
            @{Name = "Node.js"; ID = "OpenJS.NodeJS"; Type = "winget"; Desc = "JavaScript runtime" },
            @{Name = "Go"; ID = "GoLang.Go"; Type = "winget"; Desc = "Go programming language" },
            @{Name = "Rust (rustup)"; ID = "Rustlang.Rustup"; Type = "winget"; Desc = "Rust toolchain" },
            @{Name = "pnpm"; ID = "pnpm.pnpm"; Type = "winget"; Desc = "Fast package manager" },
            @{Name = "VC++ Redist 2015-2022"; ID = "Microsoft.VCRedist.2015+.x64"; Type = "winget"; Desc = "Runtime libraries" }
        )
    }
    "Utilities"            = @{
        Color = $colors.CategoryUtil
        Apps  = @(
            @{Name = "FileZilla"; ID = "TimKosse.FileZilla.Client"; Type = "winget"; Desc = "FTP client" },
            @{Name = "Wireshark"; ID = "WiresharkFoundation.Wireshark"; Type = "winget"; Desc = "Network analyzer" }
        )
    }
}

# === tweaks.ps1 ===
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

# === main.ps1 ===













$form = New-Object System.Windows.Forms.Form
$form.Text = "  Tweakr v$appVersion"
$form.Size = New-Object System.Drawing.Size(850, 720)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false
$form.BackColor = $colors.Background
$form.ForeColor = $colors.Text

$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Location = New-Object System.Drawing.Point(0, 0)
$headerPanel.Size = New-Object System.Drawing.Size(850, 70)
$headerPanel.BackColor = $colors.Background

$logoLabel = New-Object System.Windows.Forms.Label
$logoLabel.Text = "T"
$logoLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$logoLabel.ForeColor = $colors.Primary
$logoLabel.BackColor = $colors.SurfaceLight
$logoLabel.Size = New-Object System.Drawing.Size(36, 36)
$logoLabel.Location = New-Object System.Drawing.Point(20, 17)
$logoLabel.TextAlign = 'MiddleCenter'
$headerPanel.Controls.Add($logoLabel)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Tweakr"
$titleLabel.Font = $fonts.Title
$titleLabel.ForeColor = $colors.Text
$titleLabel.Location = New-Object System.Drawing.Point(65, 10)
$titleLabel.AutoSize = $true
$headerPanel.Controls.Add($titleLabel)

$subtitleLabel = New-Object System.Windows.Forms.Label
$subtitleLabel.Text = "System Configuration Tool"
$subtitleLabel.Font = $fonts.Small
$subtitleLabel.ForeColor = $colors.TextMuted
$subtitleLabel.Location = New-Object System.Drawing.Point(67, 46)
$subtitleLabel.Size = New-Object System.Drawing.Size(200, 20)
$subtitleLabel.AutoSize = $false
$subtitleLabel.BringToFront()
$headerPanel.Controls.Add($subtitleLabel)

$form.Controls.Add($headerPanel)

$tabButtonPanel = New-Object System.Windows.Forms.Panel
$tabButtonPanel.Location = New-Object System.Drawing.Point(20, 70)
$tabButtonPanel.Size = New-Object System.Drawing.Size(795, 42)
$tabButtonPanel.BackColor = $colors.Background

$tabIndicator = New-Object System.Windows.Forms.Panel
$tabIndicator.Size = New-Object System.Drawing.Size(110, 2)
$tabIndicator.Location = New-Object System.Drawing.Point(0, 38)
$tabIndicator.BackColor = $colors.Primary

$tabBtnApps = New-Object System.Windows.Forms.Button
$tabBtnApps.Location = New-Object System.Drawing.Point(0, 5)
$tabBtnApps.Size = New-Object System.Drawing.Size(110, 32)
$tabBtnApps.Text = "Applications"
$tabBtnApps.Font = $fonts.Header
$tabBtnApps.FlatStyle = 'Flat'
$tabBtnApps.BackColor = $colors.Background
$tabBtnApps.ForeColor = $colors.Text
$tabBtnApps.FlatAppearance.BorderSize = 0
$tabBtnApps.FlatAppearance.MouseOverBackColor = $colors.Background
$tabBtnApps.FlatAppearance.MouseDownBackColor = $colors.Background
$tabBtnApps.Cursor = 'Hand'
$tabBtnApps.TextAlign = 'MiddleCenter'

$tabBtnTweaks = New-Object System.Windows.Forms.Button
$tabBtnTweaks.Location = New-Object System.Drawing.Point(120, 5)
$tabBtnTweaks.Size = New-Object System.Drawing.Size(110, 32)
$tabBtnTweaks.Text = "Tweaks"
$tabBtnTweaks.Font = $fonts.Header
$tabBtnTweaks.FlatStyle = 'Flat'
$tabBtnTweaks.BackColor = $colors.Background
$tabBtnTweaks.ForeColor = $colors.TextMuted
$tabBtnTweaks.FlatAppearance.BorderSize = 0
$tabBtnTweaks.FlatAppearance.MouseOverBackColor = $colors.Background
$tabBtnTweaks.FlatAppearance.MouseDownBackColor = $colors.Background
$tabBtnTweaks.Cursor = 'Hand'
$tabBtnTweaks.TextAlign = 'MiddleCenter'

$tabButtonPanel.Controls.Add($tabIndicator)
$tabButtonPanel.Controls.Add($tabBtnApps)
$tabButtonPanel.Controls.Add($tabBtnTweaks)
$form.Controls.Add($tabButtonPanel)

$tabAppsWrapper = New-Object System.Windows.Forms.Panel
$tabAppsWrapper.Location = New-Object System.Drawing.Point(20, 115)
$tabAppsWrapper.Size = New-Object System.Drawing.Size(795, 440)
$tabAppsWrapper.BackColor = $colors.Background

$tabApps = New-Object System.Windows.Forms.Panel
$tabApps.Location = New-Object System.Drawing.Point(0, 0)
$tabApps.Size = New-Object System.Drawing.Size(812, 440)
$tabApps.BackColor = $colors.Background
$tabApps.AutoScroll = $true
$tabApps.Padding = New-Object System.Windows.Forms.Padding(0)
$tabAppsWrapper.Controls.Add($tabApps)

$tabTweaksWrapper = New-Object System.Windows.Forms.Panel
$tabTweaksWrapper.Location = New-Object System.Drawing.Point(20, 115)
$tabTweaksWrapper.Size = New-Object System.Drawing.Size(795, 440)
$tabTweaksWrapper.BackColor = $colors.Background
$tabTweaksWrapper.Visible = $false

$tabTweaks = New-Object System.Windows.Forms.Panel
$tabTweaks.Location = New-Object System.Drawing.Point(0, 0)
$tabTweaks.Size = New-Object System.Drawing.Size(812, 440)
$tabTweaks.BackColor = $colors.Background
$tabTweaks.AutoScroll = $true

$tabTweaksWrapper.Controls.Add($tabTweaks)

$form.Controls.Add($tabAppsWrapper)
$form.Controls.Add($tabTweaksWrapper)

$tabBtnApps.Add_Click({
        $tabAppsWrapper.Visible = $true
        $tabTweaksWrapper.Visible = $false
        $tabBtnApps.ForeColor = $colors.Text
        $tabBtnTweaks.ForeColor = $colors.TextMuted
        $tabIndicator.Location = New-Object System.Drawing.Point(0, 38)
        $script:installButton.Text = "Install"
    })

$tabBtnTweaks.Add_Click({
        $tabAppsWrapper.Visible = $false
        $tabTweaksWrapper.Visible = $true
        $tabBtnApps.ForeColor = $colors.TextMuted
        $tabBtnTweaks.ForeColor = $colors.Text
        $tabIndicator.Location = New-Object System.Drawing.Point(120, 38)
        $script:installButton.Text = "Apply"
    })

$checkboxes = @{}
$yPos = 10

$actionPanel = New-Object System.Windows.Forms.Panel
$actionPanel.Location = New-Object System.Drawing.Point(0, $yPos)
$actionPanel.Size = New-Object System.Drawing.Size(770, 36)
$actionPanel.BackColor = $colors.Surface

$selectAllBtn = New-Object System.Windows.Forms.Button
$selectAllBtn.Location = New-Object System.Drawing.Point(12, 6)
$selectAllBtn.Size = New-Object System.Drawing.Size(90, 24)
$selectAllBtn.Text = 'Select All'
$selectAllBtn.FlatStyle = 'Flat'
$selectAllBtn.BackColor = $colors.SurfaceLight
$selectAllBtn.ForeColor = $colors.Text
$selectAllBtn.Font = $fonts.Small
$selectAllBtn.FlatAppearance.BorderSize = 0
$selectAllBtn.Cursor = 'Hand'
$selectAllBtn.Add_Click({
        foreach ($cb in $checkboxes.Values) { $cb.Checked = $true }
    })
$actionPanel.Controls.Add($selectAllBtn)

$deselectAllBtn = New-Object System.Windows.Forms.Button
$deselectAllBtn.Location = New-Object System.Drawing.Point(108, 6)
$deselectAllBtn.Size = New-Object System.Drawing.Size(90, 24)
$deselectAllBtn.Text = 'Deselect All'
$deselectAllBtn.FlatStyle = 'Flat'
$deselectAllBtn.BackColor = $colors.SurfaceLight
$deselectAllBtn.ForeColor = $colors.TextSecondary
$deselectAllBtn.Font = $fonts.Small
$deselectAllBtn.FlatAppearance.BorderSize = 0
$deselectAllBtn.Cursor = 'Hand'
$deselectAllBtn.Add_Click({
        foreach ($cb in $checkboxes.Values) { $cb.Checked = $false }
    })
$actionPanel.Controls.Add($deselectAllBtn)

$countLabel = New-Object System.Windows.Forms.Label
$countLabel.Location = New-Object System.Drawing.Point(560, 10)
$countLabel.Size = New-Object System.Drawing.Size(200, 18)
$countLabel.Text = "0 selected"
$countLabel.Font = $fonts.Small
$countLabel.ForeColor = $colors.TextMuted
$countLabel.TextAlign = 'MiddleRight'
$actionPanel.Controls.Add($countLabel)

$tabApps.Controls.Add($actionPanel)
$yPos += 46

foreach ($category in $categories.Keys) {
    $catData = $categories[$category]

    $catPanel = New-Object System.Windows.Forms.Panel
    $catPanel.Location = New-Object System.Drawing.Point(0, $yPos)
    $catPanel.Size = New-Object System.Drawing.Size(770, 26)
    $catPanel.BackColor = $colors.Background

    $colorBar = New-Object System.Windows.Forms.Panel
    $colorBar.Location = New-Object System.Drawing.Point(0, 8)
    $colorBar.Size = New-Object System.Drawing.Size(3, 10)
    $colorBar.BackColor = $catData.Color
    $catPanel.Controls.Add($colorBar)

    $catLabel = New-Object System.Windows.Forms.Label
    $catLabel.Text = $category.ToUpper()
    $catLabel.Font = $fonts.Category
    $catLabel.ForeColor = $colors.TextSecondary
    $catLabel.Location = New-Object System.Drawing.Point(10, 5)
    $catLabel.AutoSize = $true
    $catPanel.Controls.Add($catLabel)

    $tabApps.Controls.Add($catPanel)
    $yPos += 30

    $col = 0
    $rowStartY = $yPos

    foreach ($app in $catData.Apps) {
        $xPos = if ($col -eq 0) { 0 } else { 388 }

        $appPanel = New-Object System.Windows.Forms.Panel
        $appPanel.Location = New-Object System.Drawing.Point($xPos, $yPos)
        $appPanel.Size = New-Object System.Drawing.Size(380, 34)
        $appPanel.BackColor = $colors.Surface

        $toggle = New-ToggleSwitch -Text $app.Name -Tag $app -X 10 -Y 5 -Width 200 -OnChange {
            $selected = ($checkboxes.Values | Where-Object { $_.Checked }).Count
            $countLabel.Text = "$selected selected"
        }
        $appPanel.Controls.Add($toggle)
        $checkboxes[$app.Name] = $toggle

        $descLabel = New-Object System.Windows.Forms.Label
        $descLabel.Text = $app.Desc
        $descLabel.Font = $fonts.Small
        $descLabel.ForeColor = $colors.TextMuted
        $descLabel.Location = New-Object System.Drawing.Point(210, 10)
        $descLabel.Size = New-Object System.Drawing.Size(160, 14)
        $descLabel.TextAlign = 'MiddleRight'
        $appPanel.Controls.Add($descLabel)

        $tabApps.Controls.Add($appPanel)

        $col++
        if ($col -ge 2) {
            $yPos += 38
            $col = 0
        }
    }

    if ($col -eq 1) { $yPos += 38 }
    $yPos += 12
}

$tabTweaks.AutoScroll = $true

$tweakCheckboxes = @{}

$tweaksYPos = 10

$tweakButtonPanel = New-Object System.Windows.Forms.Panel
$tweakButtonPanel.Location = New-Object System.Drawing.Point(0, $tweaksYPos)
$tweakButtonPanel.Size = New-Object System.Drawing.Size(770, 36)
$tweakButtonPanel.BackColor = $colors.Surface

$tweakSelectEssential = New-Object System.Windows.Forms.Button
$tweakSelectEssential.Location = New-Object System.Drawing.Point(12, 6)
$tweakSelectEssential.Size = New-Object System.Drawing.Size(80, 24)
$tweakSelectEssential.Text = 'Essential'
$tweakSelectEssential.FlatStyle = 'Flat'
$tweakSelectEssential.BackColor = $colors.SuccessMuted
$tweakSelectEssential.ForeColor = $colors.Success
$tweakSelectEssential.Font = $fonts.Small
$tweakSelectEssential.FlatAppearance.BorderSize = 0
$tweakSelectEssential.Cursor = 'Hand'
$tweakSelectEssential.Add_Click({
        foreach ($key in $tweakCheckboxes.Keys) {
            $tweakCheckboxes[$key].Checked = $false
        }
        $essentialTweaks = @(
            "DisableTelemetry",
            "DisableActivityHistory",
            "DisableLocation",
            "EnableEndTask",
            "DisablePS7Tele",
            "DisableWiFiSense",
            "SetServicesManual",

            "PreferIPv4",
            "ClassicRightClick",
            "RemoveOneDrive",

            "DarkTheme",
            "ShowFileExtensions",
            "DisableMouseAccel",
            "ShowHiddenFiles",
            "CenterTaskbar",
            "DisableStickyKeys"
        )
        foreach ($id in $essentialTweaks) {
            if ($tweakCheckboxes.ContainsKey($id)) { $tweakCheckboxes[$id].Checked = $true }
        }
    })
$tweakButtonPanel.Controls.Add($tweakSelectEssential)

$tweakSelectMinimal = New-Object System.Windows.Forms.Button
$tweakSelectMinimal.Location = New-Object System.Drawing.Point(98, 6)
$tweakSelectMinimal.Size = New-Object System.Drawing.Size(70, 24)
$tweakSelectMinimal.Text = 'Minimal'
$tweakSelectMinimal.FlatStyle = 'Flat'
$tweakSelectMinimal.BackColor = $colors.SurfaceLight
$tweakSelectMinimal.ForeColor = $colors.Primary
$tweakSelectMinimal.Font = $fonts.Small
$tweakSelectMinimal.FlatAppearance.BorderSize = 0
$tweakSelectMinimal.Cursor = 'Hand'
$tweakSelectMinimal.Add_Click({
        foreach ($key in $tweakCheckboxes.Keys) {
            $tweakCheckboxes[$key].Checked = $false
        }
        $minimalTweaks = @("DisableTelemetry", "DisableActivityHistory", "DisableBingSearch", "ShowFileExtensions")
        foreach ($id in $minimalTweaks) {
            if ($tweakCheckboxes.ContainsKey($id)) { $tweakCheckboxes[$id].Checked = $true }
        }
    })
$tweakButtonPanel.Controls.Add($tweakSelectMinimal)

$tweakClearBtn = New-Object System.Windows.Forms.Button
$tweakClearBtn.Location = New-Object System.Drawing.Point(174, 6)
$tweakClearBtn.Size = New-Object System.Drawing.Size(60, 24)
$tweakClearBtn.Text = 'Clear'
$tweakClearBtn.FlatStyle = 'Flat'
$tweakClearBtn.BackColor = $colors.SurfaceLight
$tweakClearBtn.ForeColor = $colors.TextSecondary
$tweakClearBtn.Font = $fonts.Small
$tweakClearBtn.FlatAppearance.BorderSize = 0
$tweakClearBtn.Cursor = 'Hand'
$tweakClearBtn.Add_Click({
        foreach ($key in $tweakCheckboxes.Keys) {
            $tweakCheckboxes[$key].Checked = $false
        }
    })
$tweakButtonPanel.Controls.Add($tweakClearBtn)

$tabTweaks.Controls.Add($tweakButtonPanel)
$tweaksYPos += 46

foreach ($category in $tweakCategories.Keys) {
    $catData = $tweakCategories[$category]

    $catPanel = New-Object System.Windows.Forms.Panel
    $catPanel.Location = New-Object System.Drawing.Point(0, $tweaksYPos)
    $catPanel.Size = New-Object System.Drawing.Size(770, 24)
    $catPanel.BackColor = $colors.Background

    $colorBar = New-Object System.Windows.Forms.Panel
    $colorBar.Location = New-Object System.Drawing.Point(0, 7)
    $colorBar.Size = New-Object System.Drawing.Size(3, 10)
    $colorBar.BackColor = $catData.Color
    $catPanel.Controls.Add($colorBar)

    $catLabel = New-Object System.Windows.Forms.Label
    $catLabel.Text = $category.ToUpper()
    $catLabel.Font = $fonts.Category
    $catLabel.ForeColor = if ($category -match "CAUTION") { $colors.Warning } else { $colors.TextSecondary }
    $catLabel.Location = New-Object System.Drawing.Point(10, 4)
    $catLabel.AutoSize = $true
    $catPanel.Controls.Add($catLabel)

    $tabTweaks.Controls.Add($catPanel)
    $tweaksYPos += 28

    $col = 0

    foreach ($tweak in $catData.Tweaks) {
        $xPos = if ($col -eq 0) { 0 } else { 388 }

        $tweakPanel = New-Object System.Windows.Forms.Panel
        $tweakPanel.Location = New-Object System.Drawing.Point($xPos, $tweaksYPos)
        $tweakPanel.Size = New-Object System.Drawing.Size(380, 30)
        $tweakPanel.BackColor = $colors.Surface

        $toggle = New-ToggleSwitch -Text $tweak.Name -Tag $tweak -X 8 -Y 3 -Width 360
        $tweakPanel.Controls.Add($toggle)
        $tweakCheckboxes[$tweak.ID] = $toggle

        $toolTip = New-Object System.Windows.Forms.ToolTip
        $toolTip.SetToolTip($tweakPanel, $tweak.Desc)

        $tabTweaks.Controls.Add($tweakPanel)

        $col++
        if ($col -ge 2) {
            $tweaksYPos += 34
            $col = 0
        }
    }

    if ($col -eq 1) { $tweaksYPos += 34 }
    $tweaksYPos += 8
}

$appsScrollState = Add-DarkScrollbar -Panel $tabApps -ContentHeight $yPos
$appsScrollState.Track.Parent = $tabAppsWrapper
$appsScrollState.Track.BringToFront()

$tweaksScrollState = Add-DarkScrollbar -Panel $tabTweaks -ContentHeight $tweaksYPos
$tweaksScrollState.Track.Parent = $tabTweaksWrapper
$tweaksScrollState.Track.BringToFront()

$progressPanel = New-Object System.Windows.Forms.Panel
$progressPanel.Location = New-Object System.Drawing.Point(20, 565)
$progressPanel.Size = New-Object System.Drawing.Size(795, 95)
$progressPanel.BackColor = $colors.Surface

$script:statusLabel = New-Object System.Windows.Forms.Label
$script:statusLabel.Location = New-Object System.Drawing.Point(16, 14)
$script:statusLabel.Size = New-Object System.Drawing.Size(620, 20)
$script:statusLabel.Text = 'Ready'
$script:statusLabel.Font = $fonts.Header
$script:statusLabel.ForeColor = $colors.Text
$progressPanel.Controls.Add($script:statusLabel)

$script:progressBar = New-ModernProgressBar -X 16 -Y 38 -Width 620 -Height 4
$progressPanel.Controls.Add($script:progressBar)

$script:progressDetail = New-Object System.Windows.Forms.Label
$script:progressDetail.Location = New-Object System.Drawing.Point(16, 48)
$script:progressDetail.Size = New-Object System.Drawing.Size(620, 18)
$script:progressDetail.Text = 'Select items and click to begin'
$script:progressDetail.Font = $fonts.Small
$script:progressDetail.ForeColor = $colors.TextMuted
$progressPanel.Controls.Add($script:progressDetail)

$script:installButton = New-Object System.Windows.Forms.Button
$script:installButton.Location = New-Object System.Drawing.Point(655, 14)
$script:installButton.Size = New-Object System.Drawing.Size(120, 60)
$script:installButton.Text = "Install"
$script:installButton.FlatStyle = 'Flat'
$script:installButton.BackColor = $colors.Primary
$script:installButton.ForeColor = $colors.Background
$script:installButton.Font = $fonts.Button
$script:installButton.FlatAppearance.BorderSize = 0
$script:installButton.Cursor = 'Hand'
$progressPanel.Controls.Add($script:installButton)

$form.Controls.Add($progressPanel)

function Set-UILocked {
    param([bool]$Locked)

    $enabled = -not $Locked

    foreach ($cb in $checkboxes.Values) { $cb.Enabled = $enabled }
    foreach ($cb in $tweakCheckboxes.Values) { $cb.Enabled = $enabled }

    $selectAllBtn.Enabled = $enabled
    $deselectAllBtn.Enabled = $enabled
    $tweakSelectEssential.Enabled = $enabled
    $tweakSelectMinimal.Enabled = $enabled
    $tweakClearBtn.Enabled = $enabled
    $tabBtnApps.Enabled = $enabled
    $tabBtnTweaks.Enabled = $enabled

    if (-not $Locked) {
        $script:installButton.Enabled = $true
        $script:installButton.BackColor = $colors.Primary
        $form.Refresh()
        return
    }

    $script:installButton.Enabled = $false
    $script:installButton.BackColor = $colors.SurfaceLight
    $script:installButton.Text = "Wait.."
    $form.Refresh()
}

$script:installButton.Add_Click({
        $script:statusLabel.Text = "Starting .."
        $script:progressDetail.Text = ""
        $script:progressBar.Visible = $true

        Write-Host ""
        Write-Host "=============================================" -ForegroundColor Cyan
        Write-Host "  Tweakr - Starting ..     " -ForegroundColor Cyan
        Write-Host "=============================================" -ForegroundColor Cyan
        Write-Host ""

        Write-Log "Starting installation process.. "

        $selectedApps = @()
        foreach ($cb in $checkboxes.Values) {
            if ($cb.Checked) {
                $selectedApps += $cb.OriginalTag
            }
        }

        $selectedTweaks = @()
        foreach ($key in $tweakCheckboxes.Keys) {
            if ($tweakCheckboxes[$key].Checked) {
                $selectedTweaks += $key
            }
        }

        if ($selectedApps.Count -eq 0 -and $selectedTweaks.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Please select at least one application or tweak.", "Nothing Selected", 'OK', 'Warning')
            return
        }

        $totalTasks = $selectedApps.Count + $selectedTweaks.Count

        Set-ProgressBarMaximum -ProgressBar $script:progressBar -Maximum $totalTasks
        Set-ProgressBarValue -ProgressBar $script:progressBar -Value 0
        $currentTask = 0

        Set-UILocked -Locked $true

        Write-Host ""
        Write-Host "+-------------------------------------------------------------------+" -ForegroundColor Cyan
        Write-Host "|                      INSTALLATION SUMMARY                         |" -ForegroundColor Cyan
        Write-Host "+-------------------------------------------------------------------+" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  Selected $($selectedApps.Count) application(s) and $($selectedTweaks.Count) tweak(s)" -ForegroundColor White
        Write-Host ""

        if ($selectedApps.Count -gt 0) {
            Write-Host "  APPLICATIONS:" -ForegroundColor Yellow
            foreach ($app in $selectedApps) {
                Write-Host " - $($app.Name)" -ForegroundColor Gray
            }
            Write-Host ""
        }

        if ($selectedTweaks.Count -gt 0) {
            Write-Host "  TWEAKS:" -ForegroundColor Yellow
            foreach ($tweakID in $selectedTweaks) {
                Write-Host " - $tweakID" -ForegroundColor Gray
            }
            Write-Host ""
        }

        Write-Host "===================================================================" -ForegroundColor DarkGray
        Write-Host ""

        if ($selectedApps.Count -gt 0) {
            Write-Host "+-------------------------------------------------------------------+" -ForegroundColor Magenta
            Write-Host "|                   INSTALLING APPLICATIONS                         |" -ForegroundColor Magenta
            Write-Host "+-------------------------------------------------------------------+" -ForegroundColor Magenta
            Write-Host ""
        }

        foreach ($app in $selectedApps) {
            $currentTask++
            Set-ProgressBarValue -ProgressBar $script:progressBar -Value $currentTask
            $script:statusLabel.Text = "Installing $($app.Name)"
            $script:progressDetail.Text = "[$currentTask/$totalTasks] Installing application.. "

            Write-Host "---------------------------------------------" -ForegroundColor DarkGray
            Write-Log "[$currentTask/$totalTasks] Installing $($app.Name).. "

            $isPythonCustom = ($app.Type -eq "custom" -and $app.Name -match "Python")

            if ($isPythonCustom) {
                try {
                    Write-Log "Downloading Python 3.12.9.. "

                    $installerPath = "$env:TEMP\python-3.12.9-amd64.exe"
                    Invoke-WebRequest -Uri $app.URL -OutFile $installerPath -UseBasicParsing

                    Write-Log "Installing with custom settings.. "

                    $arguments = "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0 TargetDir=C:\Python312 SimpleInstall=1"
                    Start-Process -FilePath $installerPath -ArgumentList $arguments -Wait

                    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"
                    Set-ItemProperty -Path $regPath -Name "LongPathsEnabled" -Value 1 -ErrorAction SilentlyContinue

                    Write-Log "[OK] Python 3.12.9 installed!" "OK"
                    Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
                }
                catch {
                    Write-Log "[ERROR] $($_.Exception.Message)" "ERROR"
                }
                continue
            }

            try {
                Write-Host "Running: winget install --id $($app.ID) --exact --silent" -ForegroundColor DarkGray
                $result = winget install --id $app.ID --exact --silent --accept-package-agreements --accept-source-agreements 2>&1
                Write-Host $result -ForegroundColor Gray

                if ($LASTEXITCODE -ne 0) {
                    Write-Host "[!] CHECK MANUALLY" -ForegroundColor Yellow
                    Write-Log "[WARN] $($app.Name) - check manually" "WARN"
                    continue
                }

                Write-Host "[OK] SUCCESS" -ForegroundColor Green
                Write-Log "[OK] $($app.Name) installed!" "OK"
            }
            catch {
                Write-Host "[X] FAILED: $($_.Exception.Message)" -ForegroundColor Red
                Write-Log "[ERROR] $($_.Exception.Message)" "ERROR"
            }
        }

        if ($selectedTweaks.Count -gt 0) {
            Write-Host ""
            Write-Host "+-------------------------------------------------------------------+" -ForegroundColor Yellow
            Write-Host "|                    APPLYING SYSTEM TWEAKS                         |" -ForegroundColor Yellow
            Write-Host "+-------------------------------------------------------------------+" -ForegroundColor Yellow
            Write-Host ""

            # Auto-create restore point before any tweaks
            Write-Host "---------------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host "  [AUTO] " -NoNewline -ForegroundColor Magenta
            Write-Host "Creating System Restore Point..." -ForegroundColor White
            $script:statusLabel.Text = "Creating restore point..."
            try {
                Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
                Checkpoint-Computer -Description "Before Tweakr Changes" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
                Write-Host "[OK] Restore point created!" -ForegroundColor Green
                Write-Log "[OK] Restore point created!" "OK"
            }
            catch {
                Write-Host "[!] Could not create restore point (may already exist today)" -ForegroundColor Yellow
                Write-Log "[WARN] Could not create restore point" "WARN"
            }
        }

        foreach ($tweakID in $selectedTweaks) {
            $currentTask++
            Set-ProgressBarValue -ProgressBar $script:progressBar -Value $currentTask
            $script:statusLabel.Text = "Applying $tweakID"
            $script:progressDetail.Text = "[$currentTask/$totalTasks] Applying tweak.. "

            Write-Host "---------------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host "  [$currentTask/$totalTasks] " -NoNewline -ForegroundColor Cyan
            Write-Host "$tweakID" -ForegroundColor White
            Write-Log "[$currentTask/$totalTasks] Applying: $tweakID"

            if (-not $tweakFunctions.ContainsKey($tweakID)) {
                Write-Host "[!] NOT IMPLEMENTED" -ForegroundColor Yellow
                Write-Log "[WARN] Tweak not implemented: $tweakID" "WARN"
                continue
            }

            try {
                & $tweakFunctions[$tweakID]
                Write-Host "[OK] APPLIED" -ForegroundColor Green
            }
            catch {
                Write-Host "[X] FAILED: $($_.Exception.Message)" -ForegroundColor Red
                Write-Log "[ERROR] $($_.Exception.Message)" "ERROR"
            }
        }

        Write-Host ""
        Write-Host "+-------------------------------------------------------------------+" -ForegroundColor Green
        Write-Host "|                    INSTALLATION COMPLETE!                         |" -ForegroundColor Green
        Write-Host "+-------------------------------------------------------------------+" -ForegroundColor Green
        Write-Host ""
        Write-Host "  Apps Installed: $($selectedApps.Count)" -ForegroundColor White
        Write-Host "  Tweaks Applied: $($selectedTweaks.Count)" -ForegroundColor White
        Write-Host ""
        Write-Host "  Some changes may require a restart to take effect." -ForegroundColor Yellow
        Write-Host ""

        Write-Log "Installation complete! Some changes may require a restart."

        $script:statusLabel.Text = "Complete!"
        $script:progressDetail.Text = "Installed $($selectedApps.Count) app(s), applied $($selectedTweaks.Count) tweak(s). Restart may be required."
        Set-ProgressBarValue -ProgressBar $script:progressBar -Value $totalTasks

        Set-UILocked -Locked $false
    })

[void]$form.ShowDialog()

