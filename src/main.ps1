if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as Administrator!"
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Set UTF-8 encoding for proper Unicode output (winget progress bars, etc.)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

. "$scriptDir\config.ps1"
. "$scriptDir\functions.ps1"
. "$scriptDir\ui-controls.ps1"
. "$scriptDir\apps.ps1"
. "$scriptDir\tweaks.ps1"

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
                Write-Host "Running: winget install --id $($app.ID) --exact --silent --source winget" -ForegroundColor DarkGray
                $result = winget install --id $app.ID --exact --silent --accept-package-agreements --accept-source-agreements --source winget 2>&1
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
