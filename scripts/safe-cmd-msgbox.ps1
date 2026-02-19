# safe-cmd-msgbox.ps1 - MessageBox based confirmation (for profile use)
param(
    [Parameter(Mandatory=$true)][string]$Command,
    [string]$WarningMessage = ""
)

Add-Type -AssemblyName System.Windows.Forms

# === Danger patterns ===
$Patterns = @(
    @{R="\bRemove-Item\b|\brm\b|\bdel\b|\berase\b|\brd\b|\bri\b|\brmdir\b"; T="DELETE"; I="Warning"}
    @{R="\bMove-Item\b|\bmv\b|\bmove\b|\bmi\b"; T="MOVE"; I="Warning"}
    @{R="\bRename-Item\b|\bren\b|\brni\b"; T="RENAME"; I="Warning"}
    @{R="\bCopy-Item\b|\bcp\b|\bcopy\b|\bcpi\b"; T="COPY"; I="Information"}
    @{R="\bSet-Content\b|\bsc\b|\bClear-Content\b|\bclc\b"; T="OVERWRITE"; I="Warning"}
)

# === Pattern matching ===
$OpType = "UNKNOWN"; $Icon = "Warning"; $Danger = $false
foreach ($p in $Patterns) {
    if ($Command -match $p.R) {
        $Danger = $true
        $OpType = $p.T
        $Icon = $p.I
        break
    }
}

# Always warn if WarningMessage is explicitly provided (e.g. for Start-Process RunAs)
if ($WarningMessage -ne "") {
    $Danger = $true
    $OpType = "SECURITY ALERT"
}

if ($Danger) {
    # Warning sound
    try { [System.Media.SystemSounds]::Hand.Play() } catch { [Console]::Beep(1000, 500) }

    # MessageBox
    $title = "SECURITY ALERT - $OpType"
    
    if ($WarningMessage -ne "") {
        # Custom warning message
        $message = "$WarningMessage`n`nCommand:`n$Command`n`nExecute this operation?"
    } else {
        # Default message
        $message = "Dangerous command detected!`n`nCommand:`n$Command`n`nExecute this operation?"
    }
    
    $result = [System.Windows.Forms.MessageBox]::Show(
        $message,
        $title,
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::$Icon,
        [System.Windows.Forms.MessageBoxDefaultButton]::Button2,
        [System.Windows.Forms.MessageBoxOptions]::ServiceNotification
    )
    
    if ($result -ne [System.Windows.Forms.DialogResult]::Yes) {
        Write-Host "Cancelled." -ForegroundColor Red
        exit 1
    }
}

Write-Host "Executing..." -ForegroundColor Green
Invoke-Expression $Command
