[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/boiln/myra/releases)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue?logo=powershell)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Windows Support](https://img.shields.io/badge/Windows-10%2F11-brightgreen)](https://www.microsoft.com/windows)

# Tweakr

A modern Windows setup and tweaking tool built with PowerShell. Streamline your Windows installation with one-click application installs and system optimizations.

https://github.com/user-attachments/assets/429f6443-1044-499b-aee7-129151d64fe9

## Features

-   **Application Installer** - Install popular apps via winget with a clean GUI
-   **System Tweaks** - Privacy, performance, and customization tweaks
-   **Modern Dark UI** - Clean, tabbed interface with toggle switches
-   **Safe Defaults** - Creates restore points before applying changes
-   **Portable** - Single executable or script, no installation required

## Categories

### Applications

| Category             | Apps                                         |
| -------------------- | -------------------------------------------- |
| Browsers             | Brave, Firefox                               |
| Communication        | Discord, Discord Canary                      |
| Development          | Git, VS Code, GitHub Desktop, VS Build Tools |
| Languages & Runtimes | Python, Node.js, Go, Rust, pnpm              |
| Utilities            | FileZilla, Wireshark                         |

### Tweaks

| Category    | Description                                                     |
| ----------- | --------------------------------------------------------------- |
| Essential   | Disable telemetry, activity history, GameDVR, location tracking |
| Advanced    | Disable hibernation, IPv6, Copilot, classic right-click menu    |
| Preferences | Dark theme, show file extensions, disable Bing search           |

## Installation

### Option 1: Run the Script

```powershell
# Clone the repository
git clone https://github.com/boiln/tweakr.git
cd tweakr

# Run as Administrator
.\main.ps1
```

### Option 2: Download Executable

Download the latest `tweakr-win64.exe` from [Releases](https://github.com/boiln/tweakr/releases) and run as Administrator.

### Option 3: One-Liner

```powershell
irm https://raw.githubusercontent.com/boiln/tweakr/main/release/Tweakr-Bundled.ps1 | iex
```

## Building from Source

```powershell
# Install dependencies and build
.\scripts\build.ps1 -Version "1.0.0"

# Preview without making changes
.\scripts\build.ps1 -WhatIf
```

**Build Requirements:**

-   PowerShell 5.1+
-   ps2exe module (auto-installed)
-   PSScriptAnalyzer module (auto-installed)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Disclaimer

This tool modifies Windows system settings. While it creates restore points before making changes, use at your own risk. Always review what tweaks you're applying before running them.

## Acknowledgments

-   Inspired by [Chris Titus Tech's WinUtil](https://github.com/ChrisTitusTech/winutil)
-   Built with PowerShell and Windows Forms
