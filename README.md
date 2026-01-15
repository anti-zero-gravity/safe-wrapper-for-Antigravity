# Safe Command Wrapper for Antigravity

![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey?style=for-the-badge&logo=windows)

本ツールは **Windows PowerShell 5.1** および **PowerShell 7 (Core)** の両方に対応しており、どちらの環境でも Antigravity (AI Agent) による危険なコマンド実行を検出・保護します。

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

## 設定の即時反映

`/設定` を実行すると、現在のセッションにも即座に反映されます。
**PowerShell の再起動は不要です。**

---

## Terminal Blindness Prevention

Antigravity/VSCode統合ターミナルで発生する「terminal blindness」問題を自動的に解決します。

### 検出条件
```powershell
if ($env:TERM_PROGRAM -eq 'vscode' -or $env:ANTIGRAVITY_AGENT -or -not [Environment]::UserInteractive)
```

### 無効化される項目
| 項目 | 対策 |
|------|------|
| **プログレスバー** | `$Global:ProgressPreference = 'SilentlyContinue'` |
| **PSReadLine装飾** | 予測入力・シンタックスハイライト無効化 |
| **プロンプトカスタマイズ** | シンプルな `"PS> "` に置換（Oh My Posh、Starship等を無効化） |
| **ANSIエスケープシーケンス** | `$PSStyle.OutputRendering = 'PlainText'`、`NO_COLOR=1`、`TERM=dumb` |

> [!NOTE]
> 通常のターミナル（人間が使用）では従来どおりの装飾・カスタマイズが維持されます。

