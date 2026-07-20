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

$advancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

# ファイル拡張子を表示
Set-ItemProperty -Path $advancedPath -Name "HideFileExt" -Value 0

# クイックアクセスに最近使ったファイルを表示しない
Set-ItemProperty -Path $advancedPath -Name "ShowRecent" -Value 0

# クイックアクセスによく使うフォルダーを表示しない
Set-ItemProperty -Path $advancedPath -Name "ShowFrequent" -Value 0

# ファイルエクスプローラーの履歴をクリア
Remove-Item -Path "$env:APPDATA\Microsoft\Windows\Recent\*" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations\*" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:APPDATA\Microsoft\Windows\Recent\CustomDestinations\*" -Force -ErrorAction SilentlyContinue

# windows11のおすすめ欄をオフ
$policyPath = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
if (-not (Test-Path $policyPath))
{
    New-Item -Path $policyPath -Force | Out-Null
}
Set-ItemProperty -Path $policyPath -Name "HideRecommendedSection" -Value 1

# クイックアクセスではなくPCから開始
Set-ItemProperty -Path $advancedPath -Name "LaunchTo" -Value 1

# エクスプローラーの「ホーム」で最近のアクティビティを表示しない
Set-ItemProperty -Path $advancedPath -Name "Start_TrackDocs" -Value 0

# クラウドファイルの最近のアクティビティも非表示
$cloudPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
Set-ItemProperty -Path $cloudPath -Name "HubMode" -Value 1

# メニューが開くまでの遅延をなくす(0ミリ秒)
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "0"

# アニメーション効果をオフ(設定 > アクセシビリティ > 視覚効果 > 「アニメーション効果」トグルと同等)
$animCode = @"
using System;
using System.Runtime.InteropServices;

public class AnimationEffects
{
    [DllImport("user32.dll", SetLastError = true)]
    public static extern int SystemParametersInfo(uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);
}
"@
Add-Type -TypeDefinition $animCode

$SPI_SETCLIENTAREAANIMATION = 0x1043
$SPIF_UPDATEINIFILE = 0x01
$SPIF_SENDCHANGE = 0x02

[AnimationEffects]::SystemParametersInfo($SPI_SETCLIENTAREAANIMATION, 0, [IntPtr]::Zero, ($SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE))

# 右クリックメニューを旧来に戻す
$clsidPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
if (-not (Test-Path $clsidPath))
{
    New-Item -Path $clsidPath -Force | Out-Null
}
Set-ItemProperty -Path $clsidPath -Name "(Default)" -Value ""

# OneDriveをアンインストール
Write-Host "OneDriveをアンインストール中..." -ForegroundColor Cyan

taskkill /f /im OneDrive.exe 2>$null

if (Test-Path "$env:SystemRoot\SysWOW64\OneDriveSetup.exe")
{
    Start-Process "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait
}
elseif (Test-Path "$env:SystemRoot\System32\OneDriveSetup.exe")
{
    Start-Process "$env:SystemRoot\System32\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait
}

# 残存フォルダ・ショートカットの削除
Remove-Item -Path "$env:USERPROFILE\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:PROGRAMDATA\Microsoft OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" -Force -ErrorAction SilentlyContinue

# OneDriveの自動起動,再インストールを防止するポリシー設定
$oneDrivePolicyPath = "HKLM:\Software\Policies\Microsoft\Windows\OneDrive"
if (-not (Test-Path $oneDrivePolicyPath))
{
    New-Item -Path $oneDrivePolicyPath -Force | Out-Null
}
Set-ItemProperty -Path $oneDrivePolicyPath -Name "DisableFileSyncNGSC" -Value 1

Write-Host "OneDriveの削除が完了しました" -ForegroundColor Green

# ユーザーフォルダの移動
# SHSetKnownFolderPath を呼び出すためのAPI定義
$code = @"
using System;
using System.Runtime.InteropServices;

public class KnownFolders
{
    [DllImport("shell32.dll")]
    public static extern int SHSetKnownFolderPath(ref Guid folderId, uint flags, IntPtr token, [MarshalAs(UnmanagedType.LPWStr)] string path);
}
"@
Add-Type -TypeDefinition $code

$targetRoot = "E:\"

if (-not (Test-Path $targetRoot))
{
    New-Item -Path $targetRoot -ItemType Directory -Force | Out-Null
}

# KNOWNFOLDERID(Windows公式のGUID)と移動先サブフォルダ名の対応表
$knownFolders = @{
    "Desktop"   = @{ Guid = "B4BFCC3A-DB2C-424C-B029-7FE99A87C641"; SubDir = "Desktop" }
    "Documents" = @{ Guid = "FDD39AD0-238F-46AF-ADB4-6C85480369C7"; SubDir = "Documents" }
    "Pictures"  = @{ Guid = "33E28130-4E1E-4676-835A-98395C3BC3BB"; SubDir = "Pictures" }
    "Music"     = @{ Guid = "4BD8D571-6D19-48D3-BE97-422220080E43"; SubDir = "Music" }
    "Videos"    = @{ Guid = "18989B1D-99B5-455B-841C-AB7C74E4DDFC"; SubDir = "Videos" }
    "Downloads" = @{ Guid = "374DE290-123F-4565-9164-39C4925E467B"; SubDir = "Downloads" }
}

foreach ($key in $knownFolders.Keys)
{
    $info = $knownFolders[$key]
    $newPath = Join-Path $targetRoot $info.SubDir

    if (-not (Test-Path $newPath))
    {
        New-Item -Path $newPath -ItemType Directory -Force | Out-Null
    }

    $guid = [Guid]$info.Guid
    $result = [KnownFolders]::SHSetKnownFolderPath([ref]$guid, 0, [IntPtr]::Zero, $newPath)

    if ($result -eq 0)
    {
        Write-Host "${key} -> ${newPath} に移動しました" -ForegroundColor Green
    }
    else
    {
        Write-Host "${key} の移動に失敗しました(エラーコード: $result)" -ForegroundColor Red
    }
}

# 変更を反映するためエクスプローラー再起動
Stop-Process -Name explorer -Force
Start-Process explorer

Write-Host "Enterキーを押して終了してください..."
Read-Host
