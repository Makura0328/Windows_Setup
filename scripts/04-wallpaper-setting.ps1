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

# SystemParametersInfo を呼び出すためのAPI定義
$code = @"
using System;
using System.Runtime.InteropServices;

public class Wallpaper
{
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
Add-Type -TypeDefinition $code

$wallpaperPath = "C:\Windows\Web\Wallpaper\Windows\img0.jpg"

$SPI_SETDESKWALLPAPER = 20
$SPIF_UPDATEINIFILE = 0x01
$SPIF_SENDCHANGE = 0x02

[Wallpaper]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $wallpaperPath, ($SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE))

Write-Host "壁紙を変更しました: $wallpaperPath" -ForegroundColor Green

Write-Host "Enterキーを押して終了してください..."
Read-Host