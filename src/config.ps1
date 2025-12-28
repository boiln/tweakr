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
