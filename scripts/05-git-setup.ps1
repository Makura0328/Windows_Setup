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

if(-not (Get-Command git -ErrorAction SilentlyContinue))
{
    Write-Host "gitが見つかりません。先にwingetでGit.Gitをインストールしてください。" -ForegroundColor Red
    Write-Host "Enterキーを押して終了してください..."
    Read-Host
    exit
}

# 名前とメールアドレスを入力
$gitUserName = git config --global user.name
if (-not $gitUserName)
{
    $gitUserName = Read-Host "Gitで使う名前を入力してください"
}

$gitUserEmail = git config --global user.email
if (-not $gitUserEmail)
{
    $gitUserEmail = Read-Host "Gitで使うメールアドレスを入力してください"
}

# ユーザー情報の設定
git config --global user.name "$gitUserName"
git config --global user.email "$gitUserEmail"

# 初期ブランチ名をmainに統一
git config --global init.defaultBranch main

# 改行コードの自動変換設定
git config --global core.autocrlf true

# デフォルトエディタをVisual Studio 2026に(インストール済みの場合)
$vswherePath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"

if (Test-Path $vswherePath)
{
    $vsInstallPath = & $vswherePath -latest -property installationPath

    if ($vsInstallPath)
    {
        $devenvPath = Join-Path $vsInstallPath "Common7\IDE\devenv.exe"

        if (Test-Path $devenvPath)
        {
            git config --global core.editor "'$devenvPath' /edit"
            Write-Host "デフォルトエディタをVisual Studio 2026に設定しました" -ForegroundColor Green
        }
    }
}
else
{
    Write-Host "Visual Studioが見つからないため、エディタ設定はスキップしました" -ForegroundColor Yellow
}

# 資格情報の保存にGit Credential Managerを使用(Git for Windowsに同梱)
git config --global credential.helper manager

Write-Host "Gitの設定が完了しました" -ForegroundColor Green
git config --global --list

# ===== SSH鍵の生成 =====
$sshDir = "$env:USERPROFILE\.ssh"
$sshKeyPath = "$sshDir\id_ed25519"

if (-not (Test-Path $sshDir))
{
    New-Item -Path $sshDir -ItemType Directory -Force | Out-Null
}

if (Test-Path $sshKeyPath)
{
    Write-Host "SSH鍵は既に存在します: $sshKeyPath" -ForegroundColor DarkGray
}
else
{
    Write-Host "SSH鍵を生成します..." -ForegroundColor Cyan
    ssh-keygen -t ed25519 -C "$gitUserEmail" -f "$sshKeyPath" -N '""'
}

# ssh-agentサービスを自動起動に設定して開始
Get-Service ssh-agent | Set-Service -StartupType Automatic
Start-Service ssh-agent

# 秘密鍵をssh-agentに登録
ssh-add $sshKeyPath

Write-Host "`n以下が公開鍵です。GitHub/GitLabなどに登録してください:" -ForegroundColor Yellow
Get-Content "$sshKeyPath.pub"
