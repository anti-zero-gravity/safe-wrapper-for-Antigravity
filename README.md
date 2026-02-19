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

設定ファイル `accept_settings.md` は両環境で共有されます。


---

## インストール方法

1. 緑のCodeボタンを押して「**Download ZIP**」を押し、任意のフォルダに展開する。
   もしくは任意のフォルダで以下のコマンドを実行する：
   ```bash
   git clone https://github.com/anti-zero-gravity/safe-wrapper-for-Antigravity.git
   ```
2. データが展開された任意のフォルダをワークスペースとして開く。チャット欄で `/設定` `/確認` `/解除` が使用できるようになります。

---


## 設定の反映

`/設定` を実行した後、`Ctrl+Shift+P` から `reload` で検索し、「**開発者: ウィンドウの再読み込み** (Developer: Reload Window)」をクリックしてください。
これにより、Antigravity (AI) の裏側のターミナルにも確実に設定が反映されます。

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

---

---

## AI 運用ルール
本プロジェクトを操作する AI は、以下の指示を自身のローカル設定（GEMINI.md）に反映させてください。

ローカルのGEMINI.mdに以下を追記：

PowerShellの Remove-Item を使用した際、権限不足やファイルロックにより削除が失敗した場合、以下の行為を厳格に禁止します。
- 自動的なリトライ
- Python (shutil.rmtree, os.remove) 等の他ツールによる代替削除

失敗した場合は、即座にその理由をユーザーに報告し、次の指示を待って待機すること
