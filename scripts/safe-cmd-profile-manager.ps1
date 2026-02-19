# safe-cmd-profile-manager.ps1 - Profile Management Tool with Settings File Support
# Usage: .\safe-cmd-profile-manager.ps1 -Action <status|install|uninstall|enable|disable>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("status", "install", "uninstall", "enable", "disable")]
    [string]$Action
)

$ProfilePath = $PROFILE
$SafeCmdRoot = Split-Path -Parent $PSScriptRoot
$SettingsPath = "$SafeCmdRoot\accept_settings.md"

# ============================================================
# Command Templates - Define wrapper functions for each command
# ============================================================
$CommandTemplates = @{
    "Remove-Item" = @{
        Aliases = @("rm", "del", "erase", "rd", "ri", "rmdir")
        Template = @'
function Global:Remove-Item {
    param(
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [string[]]$Path,
        [switch]$Recurse,
        [switch]$Force
    )
    process {
        foreach ($p in $Path) {
            $cmd = "Microsoft.PowerShell.Management\Remove-Item -Path '$p'"
            if ($Recurse) { $cmd += " -Recurse" }
            if ($Force) { $cmd += " -Force" }
            if ($Global:SafeCmdEnabled -and (Test-Path $Global:SafeCmdPath)) {
                & $Global:SafeCmdPath -Command $cmd
            } else { Invoke-Expression $cmd }
        }
    }
}
'@
    }
    "Move-Item" = @{
        Aliases = @("mv", "move", "mi")
        Template = @'
function Global:Move-Item {
    param(
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [string[]]$Path,
        [Parameter(Position=1, Mandatory=$true)]
        [string]$Destination,
        [switch]$Force
    )
    process {
        foreach ($p in $Path) {
            $cmd = "Microsoft.PowerShell.Management\Move-Item -Path '$p' -Destination '$Destination'"
            if ($Force) { $cmd += " -Force" }
            if ($Global:SafeCmdEnabled -and (Test-Path $Global:SafeCmdPath)) {
                & $Global:SafeCmdPath -Command $cmd
            } else { Invoke-Expression $cmd }
        }
    }
}
'@
    }
    "Rename-Item" = @{
        Aliases = @("ren", "rni")
        Template = @'
function Global:Rename-Item {
    param(
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$Path,
        [Parameter(Position=1, Mandatory=$true)]
        [string]$NewName,
        [switch]$Force
    )
    process {
        $cmd = "Microsoft.PowerShell.Management\Rename-Item -Path '$Path' -NewName '$NewName'"
        if ($Force) { $cmd += " -Force" }
        if ($Global:SafeCmdEnabled -and (Test-Path $Global:SafeCmdPath)) {
            & $Global:SafeCmdPath -Command $cmd
        } else { Invoke-Expression $cmd }
    }
}
'@
    }
    "Set-Content" = @{
        Aliases = @("sc")
        Template = @'
function Global:Set-Content {
    param(
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string[]]$Path,
        [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
        [object[]]$Value,
        [switch]$Force,
        [switch]$NoNewline
    )
    process {
        foreach ($p in $Path) {
            foreach ($v in $Value) {
                 $safeVal = $v.ToString().Replace("'", "''")
                 $cmd = "Microsoft.PowerShell.Management\Set-Content -Path '$p' -Value '$safeVal'"
                 if ($Force) { $cmd += " -Force" }
                 if ($NoNewline) { $cmd += " -NoNewline" }
                 if ($Global:SafeCmdEnabled -and (Test-Path $Global:SafeCmdPath)) {
                    & $Global:SafeCmdPath -Command $cmd
                 } else { Invoke-Expression $cmd }
            }
        }
    }
}
'@
    }
    "Clear-Content" = @{
        Aliases = @("clc")
        Template = @'
function Global:Clear-Content {
    param(
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string[]]$Path,
        [switch]$Force
    )
    process {
        foreach ($p in $Path) {
            $cmd = "Microsoft.PowerShell.Management\Clear-Content -Path '$p'"
            if ($Force) { $cmd += " -Force" }
            if ($Global:SafeCmdEnabled -and (Test-Path $Global:SafeCmdPath)) {
                & $Global:SafeCmdPath -Command $cmd
            } else { Invoke-Expression $cmd }
        }
    }
}
'@
    }
    "Copy-Item" = @{
        Aliases = @("cp", "copy", "cpi")
        Template = @'
function Global:Copy-Item {
    param(
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [string[]]$Path,
        [Parameter(Position=1, Mandatory=$true)]
        [string]$Destination,
        [switch]$Recurse,
        [switch]$Force
    )
    process {
        foreach ($p in $Path) {
            $cmd = "Microsoft.PowerShell.Management\Copy-Item -Path '$p' -Destination '$Destination'"
            if ($Recurse) { $cmd += " -Recurse" }
            if ($Force) { $cmd += " -Force" }
            if ($Global:SafeCmdEnabled -and (Test-Path $Global:SafeCmdPath)) {
                & $Global:SafeCmdPath -Command $cmd
            } else { Invoke-Expression $cmd }
        }
    }
}
'@
    }
}

# ============================================================
# Settings Parser - Read configuration from markdown file
# ============================================================
function Parse-SettingsFile {
    param([string]$Path)
    
    $result = @{
        Dialog = @()      # Commands that show dialog
        AutoAccept = @()  # Commands that auto-accept
    }
    
    if (-not (Test-Path $Path)) {
        Write-Warning "Settings file not found: $Path. Using default (all commands show dialog)."
        return @{ Dialog = $CommandTemplates.Keys; AutoAccept = @() }
    }
    
    $content = Get-Content $Path -Encoding UTF8
    $currentSection = $null
    
    foreach ($line in $content) {
        # Detect section headers
        if ($line -match "^## \[DIALOG\]") {
            $currentSection = "Dialog"
        }
        elseif ($line -match "^## \[AUTO\]") {
            $currentSection = "AutoAccept"
        }
        elseif ($line -match "^#") {
            $currentSection = $null  # Other sections, ignore
        }
        elseif ($currentSection -and $line -match "^- (\w+-\w+)") {
            $cmdName = $Matches[1]
            if ($CommandTemplates.ContainsKey($cmdName)) {
                $result[$currentSection] += $cmdName
            }
        }
    }
    
    return $result
}

# ============================================================
# Profile Generator - Build profile content dynamically
# ============================================================
function Generate-ProfileContent {
    param(
        [hashtable]$Settings,
        [string]$OriginalContent = ""
    )
    
    $safeCmdPath = "$SafeCmdRoot\scripts\safe-cmd-msgbox.ps1"
    
    $sb = [System.Text.StringBuilder]::new()
    
    # ============================================================
    # Antigravity/VSCode Terminal Blindness Prevention
    # These escape codes and decorations interfere with AI output parsing
    # ============================================================
    [void]$sb.AppendLine("# ============================================================")
    [void]$sb.AppendLine("# Antigravity/VSCode Terminal Detection (AI Clean Environment)")
    [void]$sb.AppendLine("# Prevents 'terminal blindness' by disabling decorations that")
    [void]$sb.AppendLine("# interfere with AI output parsing (OSC 633, ANSI, etc.)")
    [void]$sb.AppendLine("# ============================================================")
    [void]$sb.AppendLine(@'
# Detect Antigravity/VSCode integrated terminal or non-interactive mode
if ($env:TERM_PROGRAM -eq 'vscode' -or $env:ANTIGRAVITY_AGENT -or -not [Environment]::UserInteractive) {
    # === Disable output-polluting features for AI parsing ===
    
    # Disable progress bars (prevent ANSI progress sequences)
    $Global:ProgressPreference = 'SilentlyContinue'
    
    # Disable PSReadLine decorations (syntax highlighting, predictions)
    if (Get-Module -Name PSReadLine -ErrorAction SilentlyContinue) {
        Set-PSReadLineOption -PredictionSource None -ErrorAction SilentlyContinue
    }
    
    # Neutralize prompt customizations (Oh My Posh, Starship, etc.)
    # Set minimal PS1 to avoid escape sequence injection
    function Global:prompt { "PS> " }
    
    # Clear PROMPT and PROMPT_COMMAND equivalents
    Remove-Variable -Name PROMPT -Scope Global -ErrorAction SilentlyContinue
    $env:PROMPT = $null
    
    # Disable ANSI/VT escape sequences in console output
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        $PSStyle.OutputRendering = 'PlainText'
    }
    $env:NO_COLOR = "1"
    $env:TERM = "dumb"
    
    # Note: We continue loading SafeCmd wrappers below even in AI mode
    # because they still provide safety features, just with clean output
}

'@)
    [void]$sb.AppendLine("")
    
    # Include original profile content (if exists and not placeholder)
    if ($OriginalContent -and $OriginalContent -notmatch "This is a placeholder backup file") {
        [void]$sb.AppendLine("# ============================================================")
        [void]$sb.AppendLine("# Original Profile Content (preserved)")
        [void]$sb.AppendLine("# ============================================================")
        [void]$sb.AppendLine($OriginalContent.TrimEnd())
        [void]$sb.AppendLine("")
    }
    
    # Header
    [void]$sb.AppendLine("# ============================================================")
    [void]$sb.AppendLine("# PowerShell Profile - Safe Command Wrapper (auto-generated)")
    [void]$sb.AppendLine("# Installed by: safe-cmd-profile-manager.ps1")
    [void]$sb.AppendLine("# Settings from: $SettingsPath")
    [void]$sb.AppendLine("# ============================================================")
    [void]$sb.AppendLine("`$Global:SafeCmdPath = `"$safeCmdPath`"")
    [void]$sb.AppendLine("`$Global:SafeCmdEnabled = `$true")
    [void]$sb.AppendLine("")
    
    # Add wrapper functions for Dialog commands
    foreach ($cmdName in $Settings.Dialog) {
        if ($CommandTemplates.ContainsKey($cmdName)) {
            [void]$sb.AppendLine($CommandTemplates[$cmdName].Template)
            [void]$sb.AppendLine("")
            
            # Add aliases
            foreach ($alias in $CommandTemplates[$cmdName].Aliases) {
                [void]$sb.AppendLine("Set-Alias -Name $alias -Value $cmdName -Force -Scope Global -Option AllScope")
            }
            [void]$sb.AppendLine("")
        }
    }
    
    # Strictly Prohibited Commands
    [void]$sb.AppendLine("# ------------------------------------------------------------------")
    [void]$sb.AppendLine("# Strictly Prohibited Commands (Blocked regardless of setting)")
    [void]$sb.AppendLine("# ------------------------------------------------------------------")
    [void]$sb.AppendLine(@'
function Global:Block-DangerousCommand {
    param([string]$CommandName)
    Write-Error "🚫 [Security Violation] The command '$CommandName' is strictly prohibited by policy to prevent accidental system destruction."
}

function Global:Clear-Disk { Global:Block-DangerousCommand "Clear-Disk" }
function Global:Initialize-Disk { Global:Block-DangerousCommand "Initialize-Disk" }
function Global:Format-Volume { Global:Block-DangerousCommand "Format-Volume" }
function Global:Remove-Partition { Global:Block-DangerousCommand "Remove-Partition" }
function Global:Stop-Computer { Global:Block-DangerousCommand "Stop-Computer" }
function Global:Restart-Computer { Global:Block-DangerousCommand "Restart-Computer" }
function Global:Remove-LocalUser { Global:Block-DangerousCommand "Remove-LocalUser" }
function Global:Stop-Process { Global:Block-DangerousCommand "Stop-Process" }
function Global:Stop-Service { Global:Block-DangerousCommand "Stop-Service" }
function Global:Remove-ItemProperty { Global:Block-DangerousCommand "Remove-ItemProperty" }
'@)
    [void]$sb.AppendLine("")
    
    # Utility functions
    [void]$sb.AppendLine(@'
function Global:Disable-SafeCmd { $Global:SafeCmdEnabled = $false; Write-Host "SafeCmd DISABLED" -ForegroundColor Yellow }
function Global:Enable-SafeCmd { $Global:SafeCmdEnabled = $true; Write-Host "SafeCmd ENABLED" -ForegroundColor Green }

function Global:Uninstall-SafeCmd {
    $managerPath = $Global:SafeCmdPath -replace 'safe-cmd-msgbox.ps1', 'safe-cmd-profile-manager.ps1'
    if (Test-Path $managerPath) {
        & $managerPath -Action uninstall
    } else {
        Write-Error "Manager script not found at $managerPath"
    }
}

function Global:Get-SafeCmdStatus { 
    Write-Host ""
    Write-Host "=== Safe Command Wrapper Status ===" -ForegroundColor Cyan
    Write-Host "Enabled: $Global:SafeCmdEnabled"
    Write-Host "Script:  $Global:SafeCmdPath"
    Write-Host ""
}


'@)
    
    return $sb.ToString()
}

# ============================================================
# Actions
# ============================================================
# ============================================================
# Core Logic - Target Paths
# ============================================================
function Get-TargetProfiles {
    $docs = [Environment]::GetFolderPath("MyDocuments")
    $profiles = @(
        @{
            Name = "PowerShell 7+ (Core)"
            Path = Join-Path $docs "PowerShell\Microsoft.PowerShell_profile.ps1"
        },
        @{
            Name = "Windows PowerShell 5.1"
            Path = Join-Path $docs "WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
        }
    )
    return $profiles
}

# ============================================================
# Actions
# ============================================================
function Show-Status {
    Write-Host ""
    Write-Host "=== Safe Command Profile Status ===" -ForegroundColor Cyan
    Write-Host "Settings File: $SettingsPath"
    
    if (Test-Path $SettingsPath) {
        Write-Host "Settings File Exists: YES" -ForegroundColor Green
        $settings = Parse-SettingsFile -Path $SettingsPath
        Write-Host "  Dialog: $($settings.Dialog -join ', ')" -ForegroundColor Yellow
        Write-Host "  AutoAccept: $($settings.AutoAccept -join ', ')" -ForegroundColor Green
    } else {
        Write-Host "Settings File Exists: NO" -ForegroundColor Red
    }
    Write-Host ""

    $targets = Get-TargetProfiles
    foreach ($target in $targets) {
        Write-Host "--- $($target.Name) ---" -ForegroundColor Cyan
        Write-Host "Path: $($target.Path)"
        
        if (Test-Path $target.Path) {
            Write-Host "  Profile Exists: YES" -ForegroundColor Green
            $content = Get-Content $target.Path -Raw
            if ($content -match "Safe Command Wrapper") {
                Write-Host "  SafeCmd Installed: YES" -ForegroundColor Green
            } else {
                Write-Host "  SafeCmd Installed: NO" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  Profile Exists: NO" -ForegroundColor Gray
            Write-Host "  SafeCmd Installed: NO" -ForegroundColor Gray
        }
        Write-Host ""
    }
}

function Install-Profile {
    # Parse settings
    $settings = Parse-SettingsFile -Path $SettingsPath
    
    Write-Host "Parsed settings:" -ForegroundColor Cyan
    Write-Host "  Dialog: $($settings.Dialog -join ', ')" -ForegroundColor Yellow
    Write-Host "  AutoAccept: $($settings.AutoAccept -join ', ')" -ForegroundColor Green
    Write-Host ""

    $targets = Get-TargetProfiles
    foreach ($target in $targets) {
        Write-Host "Installing for: $($target.Name)..." -ForegroundColor Cyan
        $pPath = $target.Path

        # Create directory if needed
        $dir = Split-Path $pPath -Parent
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        
        # Backup existing profile
        $backupPath = "$pPath$"  # e.g., Microsoft.PowerShell_profile.ps1$
        
        if (-not (Test-Path $backupPath)) {
            # No backup exists yet - create one
            if (Test-Path $pPath) {
                # Backup existing profile
                Copy-Item -Path $pPath -Destination $backupPath -Force
                Write-Host "  Backed up existing profile to: $backupPath" -ForegroundColor Green
            } else {
                # No original profile - create placeholder
                $placeholder = @"
# This is a placeholder backup file.
# No PowerShell profile existed before Safe Command Wrapper was installed.
# Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
                $placeholder | Out-File -FilePath $backupPath -Encoding UTF8 -Force
                Write-Host "  No existing profile found. Created placeholder backup." -ForegroundColor Yellow
            }
        } else {
            Write-Host "  Backup already exists. Skipping backup." -ForegroundColor Gray
        }
        
        # Read original content from backup (if exists)
        $originalContent = ""
        if (Test-Path $backupPath) {
            $originalContent = Get-Content $backupPath -Raw -ErrorAction SilentlyContinue
        }
        
        # Generate and write profile
        $profileContent = Generate-ProfileContent -Settings $settings -OriginalContent $originalContent
        $profileContent | Out-File -FilePath $pPath -Encoding UTF8 -Force
        
        Write-Host "  SafeCmd profile installed!" -ForegroundColor Green
    }

    Write-Host ""
    
    # === Memory Cleanup & Reload ===
    # Remove all managed wrapper functions from current session
    # IMPORTANT: Use original cmdlet to avoid triggering our own wrapper dialogs
    Write-Host "Refreshing current session..." -ForegroundColor Cyan
    foreach ($cmdName in $CommandTemplates.Keys) {
        # Remove Global Function (using original cmdlet)
        if (Test-Path "function:Global:$cmdName") {
            Microsoft.PowerShell.Management\Remove-Item "function:Global:$cmdName" -Force -ErrorAction SilentlyContinue
        }
        # Remove Global Aliases (using original cmdlet)
        if ($CommandTemplates[$cmdName].Aliases) {
            foreach ($alias in $CommandTemplates[$cmdName].Aliases) {
                Microsoft.PowerShell.Management\Remove-Item "alias:$alias" -Force -ErrorAction SilentlyContinue
            }
        }
    }
    
    # Reload profile to apply new settings
    if (Test-Path $PROFILE) {
        . $PROFILE
    }
    
    Write-Host "Settings applied to current session!" -ForegroundColor Green
}

function Uninstall-Profile {
    $targets = Get-TargetProfiles
    foreach ($target in $targets) {
        Write-Host "Uninstalling for: $($target.Name)..." -ForegroundColor Cyan
        $pPath = $target.Path
        $backupPath = "$pPath$"
        
        if (Test-Path $pPath) {
            Remove-Item $pPath -Force
            Write-Host "  Removed SafeCmd profile." -ForegroundColor Yellow
        } else {
            Write-Host "  No profile to remove." -ForegroundColor Gray
        }
        
        # Restore from backup if it exists and is not a placeholder
        if (Test-Path $backupPath) {
            $backupContent = Get-Content $backupPath -Raw -ErrorAction SilentlyContinue
            if ($backupContent -match "This is a placeholder backup file") {
                # It's a placeholder - just remove it
                Remove-Item $backupPath -Force
                Write-Host "  Removed placeholder backup." -ForegroundColor Gray
            } else {
                # Restore original profile
                Move-Item -Path $backupPath -Destination $pPath -Force
                Write-Host "  Restored original profile from backup." -ForegroundColor Green
            }
        }
    }
    
    Write-Host ""
    Write-Host "Restart PowerShell to apply changes." -ForegroundColor Cyan
}

# Execute action
switch ($Action) {
    "status" { Show-Status }
    "install" { Install-Profile }
    "uninstall" { Uninstall-Profile }
    "enable" { 
        Write-Host "Run 'Enable-SafeCmd' in PowerShell after loading profile." -ForegroundColor Cyan
    }
    "disable" { 
        Write-Host "Run 'Disable-SafeCmd' in PowerShell after loading profile." -ForegroundColor Cyan
    }
}
