# 管理者権限か確認してなければ再起動
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if(-not $isAdmin)
{
    Write-Host "管理者権限が必要です。昇格して再起動します。" -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

Write-Host "===== PCセットアップを開始します =====" -ForegroundColor Magenta
Write-Host ""

Write-Host "===== [1/5] エクスプローラー設定 =====" -ForegroundColor Magenta
& "$PSScriptRoot\01-exproler-settings.ps1"

Write-Host "===== [2/5] システム設定 =====" -ForegroundColor Magenta
& "$PSScriptRoot\02-system-settings.ps1"

Write-Host "===== [3/5] アプリインストール =====" -ForegroundColor Magenta
& "$PSScriptRoot\03-install-softwares.ps1"

Write-Host "===== [4/5] 壁紙設定 =====" -ForegroundColor Magenta
& "$PSScriptRoot\04-wallpaper-setting.ps1"

Write-Host "===== [5/5] Git設定 =====" -ForegroundColor Magenta
& "$PSScriptRoot\05-git-setup.ps1"

Write-Host ""
Write-Host "===== すべてのセットアップが完了しました =====" -ForegroundColor Green
Write-Host "サインアウト→サインインすると、フォルダ移動などの設定が完全に反映されます" -ForegroundColor Yellow
Write-Host ""
Write-Host "Enterキーを押して終了してください..."
Read-Host
