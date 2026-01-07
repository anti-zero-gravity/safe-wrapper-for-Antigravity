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

## 設定の即時反映

`/設定` を実行すると、現在のセッションにも即座に反映されます。
**PowerShell の再起動は不要です。**

