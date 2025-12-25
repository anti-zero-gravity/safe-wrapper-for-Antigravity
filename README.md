# Safe Command Wrapper for Antigravity

![PowerShell 7](https://img.shields.io/badge/Recommended-PowerShell_7_(Core)-blue?style=for-the-badge&logo=powershell)
![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey?style=for-the-badge&logo=windows)

> [!IMPORTANT]
> **推奨環境：PowerShell 7 (Core)**
> 
> 本ツールは Windows PowerShell 5.1 にも対応していますが、**Antigravity (AI Agent) と同じ「PowerShell 7 (Core)」の常用を強く推奨します。**
>
> 1.  **AIとの完全同期**: Antigravity はデフォルトで `pwsh` (v7+) を使用します。あなたも同じ環境を使うことで、環境差異によるエラーや挙動不審を未然に防ぎ、AIとの協業効率を最大化できます。
> 2.  **文字化け回避**: PowerShell 7 は UTF-8 をネイティブサポートしているため、モダンなツール出力やAIテキストの結合時に発生する文字化けトラブルから解放されます。
> 3.  **脱レガシー**: メンテナンスモードに入った 5.1 ではなく、進化し続ける 7 環境で、より高速で機能的なシェル体験を得られます。

---

## 安全のための制限事項

誤操作による事故を防ぐため、以下のコマンドは AI から実行できないようになっています。

### ディスク・パーティション操作
* `Clear-Disk` : ディスクのパーティション情報を消去
* `Initialize-Disk` : ディスクを初期化
* `Format-Volume` : ドライブをフォーマット
* `Remove-Partition` : パーティションを削除

### システム・重要設定操作
* `Stop-Computer` : システムのシャットダウン
* `Restart-Computer` : システムの再起動
* `Remove-LocalUser` : ローカルユーザーの削除
* `Stop-Process` : プロセスの強制終了（システム重要プロセス保護のため）
* `Stop-Service` : Windowsサービスの停止
* `Remove-ItemProperty` : レジストリ値などの削除

---

## デュアル環境の保護システム

このラッパーは、システムにインストールされている以下の両方の PowerShell 環境を自動検出し、同時に保護します。
どちらのシェルから起動しても、同じ「Safe Command Wrapper」が有効になります。

| 環境 | バージョン | プロファイルパス |
| :--- | :--- | :--- |
| **PowerShell Core** | 7.x+ | `...\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` |
| **Windows PowerShell** | 5.1 | `...\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1` |

設定ファイル `accept_settings.md` は両環境で共有されます。片方で設定を変更して適用（`/設定`）すれば、もう片方にも自動的に反映されます。

---

## PowerShell Profile Snapshot

**Path:** （上記2つのパスに同じ内容が書き込まれます）

以下は、初期ラップ設定のまま `/設定` を実行した場合のプロファイル内容のコピーです。

```powershell
# ============================================================
# PowerShell Profile - Safe Command Wrapper (auto-generated)
# Installed by: safe-cmd-profile-manager.ps1
# Settings from: $env:USERPROFILE\.gemini\antigravity\scratch\safe-wrapper\accept_settings.md
# ============================================================
$Global:SafeCmdPath = "$env:USERPROFILE\.gemini\antigravity\scratch\safe-wrapper\scripts\safe-cmd-msgbox.ps1"
$Global:SafeCmdEnabled = $true

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

Set-Alias -Name rm -Value Remove-Item -Force -Scope Global -Option AllScope
Set-Alias -Name del -Value Remove-Item -Force -Scope Global -Option AllScope
Set-Alias -Name erase -Value Remove-Item -Force -Scope Global -Option AllScope
Set-Alias -Name rd -Value Remove-Item -Force -Scope Global -Option AllScope
Set-Alias -Name ri -Value Remove-Item -Force -Scope Global -Option AllScope
Set-Alias -Name rmdir -Value Remove-Item -Force -Scope Global -Option AllScope

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

Set-Alias -Name mv -Value Move-Item -Force -Scope Global -Option AllScope
Set-Alias -Name move -Value Move-Item -Force -Scope Global -Option AllScope
Set-Alias -Name mi -Value Move-Item -Force -Scope Global -Option AllScope

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

Set-Alias -Name sc -Value Set-Content -Force -Scope Global -Option AllScope

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

Set-Alias -Name clc -Value Clear-Content -Force -Scope Global -Option AllScope

function Global:Rename-Item {
    param(
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string[]]$Path,
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

Set-Alias -Name ren -Value Rename-Item -Force -Scope Global -Option AllScope
Set-Alias -Name rni -Value Rename-Item -Force -Scope Global -Option AllScope

# ------------------------------------------------------------------
# Strictly Prohibited Commands (Blocked regardless of setting)
# ------------------------------------------------------------------
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
```
