# Kondo File Organizer - PowerShell Build Script for Windows
# Usage: .\build.ps1 [command]

param(
    [Parameter(Position=0)]
    [string]$Command = "help"
)

$BinaryName = "kondo"
$ConfigDir = "$env:APPDATA\kondo"
$ConfigFile = "$ConfigDir\kondo.toml"
$LogFile = "$ConfigDir\kondo.log"
$InstallDir = "$env:LOCALAPPDATA\Programs\kondo"

function Show-Help {
    Write-Host ""
    Write-Host "Kondo File Organizer - Windows Build Commands" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Build & Install:" -ForegroundColor Yellow
    Write-Host "  .\build.ps1 build         - Build release binary"
    Write-Host "  .\build.ps1 install       - Build and install"
    Write-Host "  .\build.ps1 uninstall     - Remove installed binary"
    Write-Host ""
    Write-Host "Development:" -ForegroundColor Yellow
    Write-Host "  .\build.ps1 run           - Run in current directory"
    Write-Host "  .\build.ps1 test          - Run tests"
    Write-Host "  .\build.ps1 clean         - Clean build artifacts"
    Write-Host "  .\build.ps1 dev           - Build and run debug version"
    Write-Host ""
    Write-Host "Configuration:" -ForegroundColor Yellow
    Write-Host "  .\build.ps1 config-edit   - Edit config file"
    Write-Host "  .\build.ps1 config-path   - Show config file path"
    Write-Host "  .\build.ps1 config-view   - View config contents"
    Write-Host "  .\build.ps1 config-reset  - Reset config to defaults"
    Write-Host "  .\build.ps1 config-backup - Backup current config"
    Write-Host ""
    Write-Host "Quality:" -ForegroundColor Yellow
    Write-Host "  .\build.ps1 fmt           - Format code"
    Write-Host "  .\build.ps1 lint          - Run clippy"
    Write-Host "  .\build.ps1 check         - Check setup"
    Write-Host ""
}

function Build-Release {
    Write-Host "Building Kondo..." -ForegroundColor Cyan
    cargo build --release
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Build complete: target\release\$BinaryName.exe" -ForegroundColor Green
    } else {
        Write-Host "✗ Build failed" -ForegroundColor Red
        exit 1
    }
}

function Install-Kondo {
    Build-Release

    Write-Host "Installing Kondo..." -ForegroundColor Cyan

    # Create directories
    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }
    if (-not (Test-Path $ConfigDir)) {
        New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
    }

    # Copy binary
    Copy-Item "target\release\$BinaryName.exe" "$InstallDir\$BinaryName.exe" -Force

    Write-Host "✓ Installed to: $InstallDir\$BinaryName.exe" -ForegroundColor Green
    Write-Host "✓ Config directory: $ConfigDir" -ForegroundColor Green
    Write-Host ""

    # Check if in PATH
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*$InstallDir*") {
        Write-Host "Adding to PATH..." -ForegroundColor Yellow
        $newPath = "$InstallDir;$currentPath"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Host "✓ Added to PATH (restart terminal to apply)" -ForegroundColor Green
        Write-Host ""
        Write-Host "To use immediately, run:" -ForegroundColor Yellow
        Write-Host "  `$env:Path = `"$InstallDir;`$env:Path`"" -ForegroundColor Cyan
    } else {
        Write-Host "✓ Already in PATH" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "Run 'kondo --help' to start organizing!" -ForegroundColor Cyan
}

function Uninstall-Kondo {
    Write-Host "Uninstalling Kondo..." -ForegroundColor Cyan

    if (Test-Path "$InstallDir\$BinaryName.exe") {
        Remove-Item "$InstallDir\$BinaryName.exe" -Force
        Write-Host "✓ Binary removed" -ForegroundColor Green
    } else {
        Write-Host "✓ Binary not found" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "Config still exists at: $ConfigDir" -ForegroundColor Yellow
    Write-Host "To remove config: Remove-Item -Recurse '$ConfigDir'" -ForegroundColor Yellow

    # Ask if user wants to remove from PATH
    Write-Host ""
    $response = Read-Host "Remove from PATH? (y/N)"
    if ($response -eq "y" -or $response -eq "Y") {
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
        $newPath = $currentPath -replace [regex]::Escape("$InstallDir;"), ""
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Host "✓ Removed from PATH (restart terminal to apply)" -ForegroundColor Green
    }
}

function Run-Kondo {
    Write-Host "Running Kondo..." -ForegroundColor Cyan
    cargo run --release
}

function Run-Tests {
    Write-Host "Running tests..." -ForegroundColor Cyan
    cargo test
}

function Clean-Build {
    Write-Host "Cleaning..." -ForegroundColor Cyan
    cargo clean
    Write-Host "✓ Clean complete" -ForegroundColor Green
}

function Edit-Config {
    if (-not (Test-Path $ConfigFile)) {
        Write-Host "Config doesn't exist. Run '.\build.ps1 run' first." -ForegroundColor Red
        exit 1
    }

    # Try to find a suitable editor
    if (Get-Command "code" -ErrorAction SilentlyContinue) {
        code $ConfigFile
    } elseif (Get-Command "notepad++" -ErrorAction SilentlyContinue) {
        notepad++ $ConfigFile
    } else {
        notepad $ConfigFile
    }
}

function Show-ConfigPath {
    Write-Host $ConfigFile
}

function View-Config {
    if (-not (Test-Path $ConfigFile)) {
        Write-Host "Config doesn't exist. Run '.\build.ps1 run' first." -ForegroundColor Red
        exit 1
    }
    Get-Content $ConfigFile
}

function Reset-Config {
    Write-Host "Resetting config to defaults..." -ForegroundColor Cyan
    if (Test-Path $ConfigFile) {
        Remove-Item $ConfigFile -Force
        Write-Host "✓ Config removed. Run 'kondo' to generate new defaults." -ForegroundColor Green
    } else {
        Write-Host "✓ No config to reset" -ForegroundColor Yellow
    }
}

function Backup-Config {
    if (-not (Test-Path $ConfigFile)) {
        Write-Host "No config to backup." -ForegroundColor Red
        exit 1
    }

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupFile = "$ConfigFile.backup-$timestamp"
    Copy-Item $ConfigFile $backupFile
    Write-Host "✓ Config backed up to: $backupFile" -ForegroundColor Green
}

function Check-Setup {
    Write-Host "Checking setup..." -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Rust version:" -ForegroundColor Yellow
    rustc --version
    cargo --version
    Write-Host ""

    Write-Host "Binary location:" -ForegroundColor Yellow
    if (Test-Path "$InstallDir\$BinaryName.exe") {
        Write-Host "  ✓ $InstallDir\$BinaryName.exe" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Not installed (run '.\build.ps1 install')" -ForegroundColor Red
    }
    Write-Host ""

    Write-Host "Config file:" -ForegroundColor Yellow
    if (Test-Path $ConfigFile) {
        Write-Host "  ✓ $ConfigFile" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Not found (will be created on first run)" -ForegroundColor Yellow
    }
    Write-Host ""

    Write-Host "Log file:" -ForegroundColor Yellow
    if (Test-Path $LogFile) {
        $logSize = (Get-Item $LogFile).Length / 1KB
        Write-Host "  ✓ $LogFile ($([math]::Round($logSize, 2)) KB)" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Not found (will be created on first run)" -ForegroundColor Yellow
    }
    Write-Host ""

    Write-Host "PATH includes install dir:" -ForegroundColor Yellow
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -like "*$InstallDir*") {
        Write-Host "  ✓ Yes" -ForegroundColor Green
    } else {
        Write-Host "  ✗ No - run '.\build.ps1 install' to add" -ForegroundColor Yellow
    }
}

function Build-Dev {
    Write-Host "Building debug version..." -ForegroundColor Cyan
    cargo build
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Running..." -ForegroundColor Cyan
        .\target\debug\$BinaryName.exe
    }
}

function Format-Code {
    Write-Host "Formatting code..." -ForegroundColor Cyan
    cargo fmt
    Write-Host "✓ Format complete" -ForegroundColor Green
}

function Lint-Code {
    Write-Host "Running clippy..." -ForegroundColor Cyan
    cargo clippy -- -D warnings
}

function Show-Version {
    $version = Select-String -Path "Cargo.toml" -Pattern '^version\s*=\s*"([^"]+)"' |
               ForEach-Object { $_.Matches.Groups[1].Value }
    Write-Host "Kondo v$version" -ForegroundColor Cyan
}

# Main command dispatcher
switch ($Command.ToLower()) {
    "help" { Show-Help }
    "build" { Build-Release }
    "install" { Install-Kondo }
    "uninstall" { Uninstall-Kondo }
    "run" { Run-Kondo }
    "test" { Run-Tests }
    "clean" { Clean-Build }
    "config-edit" { Edit-Config }
    "config-path" { Show-ConfigPath }
    "config-view" { View-Config }
    "config-reset" { Reset-Config }
    "config-backup" { Backup-Config }
    "check" { Check-Setup }
    "dev" { Build-Dev }
    "fmt" { Format-Code }
    "lint" { Lint-Code }
    "version" { Show-Version }
    default {
        Write-Host "Unknown command: $Command" -ForegroundColor Red
        Write-Host ""
        Show-Help
        exit 1
    }
}
