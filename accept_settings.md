# 現在のラップ設定

## [DIALOG] ダイアログ表示

- Remove-Item (rm, del) - ファイル/フォルダを削除
- Move-Item (mv) - ファイル/フォルダを移動
- Set-Content (sc) - ファイルの内容を上書き
- Clear-Content (clc) - ファイルの内容を空にする
- Rename-Item (ren) - ファイル/フォルダをリネーム

## [AUTO] 自動Accept
- Copy-Item (cp) - ファイル/フォルダをコピー

# 設定解除方法

**チャット欄から:**
> /解除

**PowerShell コンソールで:**
```powershell
Remove-Item $PROFILE -Force
```

# プロファイル設定確認

**チャット欄から:**
> /確認

**期待する出力:**
| コマンド | ダイアログ | 
|----------|----------|
| Remove-Item (rm, del) | 表示 | 
| Move-Item (mv) | 表示 | 
| Rename-Item (ren) | 表示 | 
| Set-Content (sc) | 表示 | 
| Clear-Content (clc) | 表示 | 
| Copy-Item (cp) | 自動で許可 | 

**PowerShell コンソールで:**
```powershell
& "$env:USERPROFILE\.gemini\antigravity\scratch\safe-wrapper\scripts\safe-cmd-profile-manager.ps1" -Action status
```

# プロファイル変更　上記リスト（現在のラップ設定）の通りに設定
必要に応じて上記リストを直接編集してから設定して下さい

**チャット欄から:**
> /設定

**PowerShell コンソールで:**
```powershell
& "$env:USERPROFILE\.gemini\antigravity\scratch\safe-wrapper\scripts\safe-cmd-profile-manager.ps1" -Action install
```