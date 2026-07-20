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

# 電源プランを高パフォーマンスに変更
Write-Host "電源プランを高パフォーマンスに設定中..." -ForegroundColor Cyan
powercfg /setactive SCHEME_MIN

$currentScheme = powercfg /getactivescheme
Write-Host $currentScheme -ForegroundColor Green

# マウス加速をオフ(ポインター精度を高める、を無効化)
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "0"
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "0"
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "0"

# マウス感度(1から20）
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSensitivity" -Value "12"

# マウスホイールのスクロール行数を7行に
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WheelScrollLines" -Value "7"

Write-Host "マウス設定を変更しました(サインアウト後に完全に反映されます)" -ForegroundColor Cyan

Write-Host

Write-Host "Enterキーを押して終了してください..."
Read-Host