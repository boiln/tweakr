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
