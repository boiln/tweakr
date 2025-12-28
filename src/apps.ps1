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
            @{Name = "WinSCP"; ID = "WinSCP.WinSCP"; Type = "winget"; Desc = "SFTP/FTP client" },
            @{Name = "Wireshark"; ID = "WiresharkFoundation.Wireshark"; Type = "winget"; Desc = "Network analyzer" },
            @{Name = "ShareX"; ID = "ShareX.ShareX"; Type = "winget"; Desc = "Screen capture & sharing" },
            @{Name = "Syncthing"; ID = "Syncthing"; Type = "custom"; URL = "https://github.com/Bill-Stewart/SyncthingWindowsSetup/releases/download/v2.0.0/syncthing-windows-setup.exe"; Desc = "File synchronization" }
        )
    }
}
