# Changelog

All notable changes to this project will be documented in this file.

## [1.2.0] - 2026-01-15

### 新機能
- **Terminal Blindness Prevention**: Antigravity/VSCode統合ターミナルでの「terminal blindness」問題を解決

  **検出条件**:
  - `$env:TERM_PROGRAM -eq 'vscode'`
  - `$env:ANTIGRAVITY_AGENT` が設定されている
  - 非対話モード (`-not [Environment]::UserInteractive`)

  **無効化される項目**:
  | 項目 | 対策 |
  |------|------|
  | プログレスバー | `$Global:ProgressPreference = 'SilentlyContinue'` |
  | PSReadLine装飾 | 予測入力・シンタックスハイライト無効化 |
  | プロンプトカスタマイズ | シンプルな `"PS> "` に置換 |
  | ANSIエスケープシーケンス | `$PSStyle.OutputRendering = 'PlainText'`、`NO_COLOR=1`、`TERM=dumb` |

  ### 検証結果 (vs 強制無効時)
  | 検証項目 | 🚫 強制無効 (Unsafe) | ✅ 対策適用後 (Safe) |
  |----------|----------------------|--------------------|
  | **ANSI出力** | `'Host'` (色コードあり) | `'PlainText'` (テキストのみ) |
  | **Progress** | `'Continue'` (大量出力) | `'SilentlyContinue'` (無効) |
  | **Prompt** | デフォルト関数 | `' "PS> " '` (固定) |
  | **NO_COLOR** | `''` (色有効) | `'1'` (色無効) |

---

## [1.1.0] - 2026-01-07

### 新機能
- **設定の即時反映**: `/設定` 実行後、PowerShell の再起動が不要になりました。設定変更は現在のセッションに即座に反映されます。

### バグ修正
- **メモリクリーン処理の自己参照バグ**: 設定適用時に `Remove-Item` でラッパー関数を削除しようとすると、ラップされた `Remove-Item` 自体が呼ばれてダイアログが表示される問題を修正。オリジナルの Cmdlet (`Microsoft.PowerShell.Management\Remove-Item`) を使用するように変更。
- **2窓環境でのダイアログ非表示問題**: 複数のインスタンスやウィンドウを開いている環境で、確認ダイアログが他のウィンドウの下に隠れて見えなくなる問題を修正。`MessageBoxOptions.ServiceNotification` を使用して強制的に最前面に表示するように変更。

### ドキュメント
- README.md から冗長な Profile Snapshot セクションを削除
- はじめに.md に即時反映機能の説明を追記

---

## [1.0.0] - 初回リリース

### 機能
- PowerShell の危険なコマンド（`Remove-Item`, `Move-Item`, `Set-Content` など）を確認ダイアログで保護
- デュアル環境サポート（PowerShell 7 Core + Windows PowerShell 5.1）
- 設定ファイル (`accept_settings.md`) による柔軟なカスタマイズ
- 厳格に禁止されたコマンド（`Clear-Disk`, `Stop-Computer` など）のブロック機能
