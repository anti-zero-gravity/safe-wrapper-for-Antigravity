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
    param([hashtable]$Settings)
    
    $safeCmdPath = "$SafeCmdRoot\scripts\safe-cmd-msgbox.ps1"
    
    $sb = [System.Text.StringBuilder]::new()
    
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

Write-Host "Safe Command Wrapper loaded." -ForegroundColor Cyan
'@)
    
    return $sb.ToString()
}

# ============================================================
# Actions
# ============================================================
function Show-Status {
    Write-Host ""
    Write-Host "=== Safe Command Profile Status ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Profile Path: $ProfilePath"
    Write-Host "Settings File: $SettingsPath"
    
    if (Test-Path $ProfilePath) {
        Write-Host "Profile Exists: YES" -ForegroundColor Green
        $content = Get-Content $ProfilePath -Raw
        if ($content -match "Safe Command Wrapper") {
            Write-Host "SafeCmd Installed: YES" -ForegroundColor Green
        } else {
            Write-Host "SafeCmd Installed: NO" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Profile Exists: NO" -ForegroundColor Yellow
        Write-Host "SafeCmd Installed: NO" -ForegroundColor Yellow
    }
    
    if (Test-Path $SettingsPath) {
        Write-Host "Settings File Exists: YES" -ForegroundColor Green
        $settings = Parse-SettingsFile -Path $SettingsPath
        Write-Host ""
        Write-Host "Dialog Commands: $($settings.Dialog -join ', ')" -ForegroundColor Yellow
        Write-Host "AutoAccept Commands: $($settings.AutoAccept -join ', ')" -ForegroundColor Green
    } else {
        Write-Host "Settings File Exists: NO" -ForegroundColor Red
    }
    Write-Host ""
}

function Install-Profile {
    # Parse settings
    $settings = Parse-SettingsFile -Path $SettingsPath
    
    Write-Host "Parsed settings:" -ForegroundColor Cyan
    Write-Host "  Dialog: $($settings.Dialog -join ', ')" -ForegroundColor Yellow
    Write-Host "  AutoAccept: $($settings.AutoAccept -join ', ')" -ForegroundColor Green
    
    # Create directory if needed
    $dir = Split-Path $ProfilePath -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    
    # Backup existing profile
    $backupPath = "$ProfilePath$"  # e.g., Microsoft.PowerShell_profile.ps1$
    
    if (-not (Test-Path $backupPath)) {
        # No backup exists yet - create one
        if (Test-Path $ProfilePath) {
            # Backup existing profile
            Copy-Item -Path $ProfilePath -Destination $backupPath -Force
            Write-Host "Backed up existing profile to: $backupPath" -ForegroundColor Green
        } else {
            # No original profile - create placeholder
            $placeholder = @"
# This is a placeholder backup file.
# No PowerShell profile existed before Safe Command Wrapper was installed.
# Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
            $placeholder | Out-File -FilePath $backupPath -Encoding UTF8 -Force
            Write-Host "No existing profile found. Created placeholder backup." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Backup already exists at: $backupPath (not overwritten)" -ForegroundColor Cyan
    }
    
    # Generate and write profile
    $profileContent = Generate-ProfileContent -Settings $settings
    $profileContent | Out-File -FilePath $ProfilePath -Encoding UTF8 -Force
    
    Write-Host "SafeCmd profile installed!" -ForegroundColor Green
    Write-Host "Restart PowerShell to apply changes." -ForegroundColor Cyan
}

function Uninstall-Profile {
    $backupPath = "$ProfilePath$"
    
    if (Test-Path $ProfilePath) {
        Remove-Item $ProfilePath -Force
        Write-Host "Removed SafeCmd profile." -ForegroundColor Yellow
    } else {
        Write-Host "No profile to remove." -ForegroundColor Gray
    }
    
    # Restore from backup if it exists and is not a placeholder
    if (Test-Path $backupPath) {
        $backupContent = Get-Content $backupPath -Raw -ErrorAction SilentlyContinue
        if ($backupContent -match "This is a placeholder backup file") {
            # It's a placeholder - just remove it
            Remove-Item $backupPath -Force
            Write-Host "Removed placeholder backup." -ForegroundColor Gray
        } else {
            # Restore original profile
            Move-Item -Path $backupPath -Destination $ProfilePath -Force
            Write-Host "Restored original profile from backup." -ForegroundColor Green
        }
    }
    
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
