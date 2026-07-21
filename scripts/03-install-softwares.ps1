param(
    [string]$jsonPath = "$PSScriptRoot\..\winget-lists.json"
)

# 管理者権限か確認してなければ再起動
# 今実行しているユーザーの情報を.NETクラスを直接読んで取得
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()

# そのユーザーが管理者グループに属しているか判定
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# もし管理者じゃなければUAC昇格プロンプトを出して新しいPSを管理者として実行
if(-not $isAdmin)
{
    Write-Host "管理者権限が必要です。昇格して再起動します。" -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -JsonPath `"$JsonPath`""
    exit
}

if(-not (Get-Command winget -ErrorAction SilentlyContinue))
{
    Write-Host "wingetが見つかりません。" -ForegroundColor Red
    exit
}

# jsonファイル全体を一つの文字列として読み込む。-Rawで指定でファイル全体を一つの文字列に
# |はパイプで、左のコマンドの出力結果を右のコマンドに渡して実行
$json = Get-Content -Raw -Path $jsonPath | ConvertFrom-Json

# 失敗したやつを格納する文字列配列（空）
$failed = @()

# wingetのソースを更新
Write-Host "wingetのソースを更新中..." -ForegroundColor Cyan
winget source update

foreach($source in $json.Sources)
{
    # wingetがソースネーム
    $sourceName = $source.SourceDetails.Name

    # パッケージについて回す
    foreach($pkg in $source.Packages)
    {
        write-Host # 改行

        $id = $pkg.PackageIdentifier

        # インストール中メッセージ表示
        Write-Host "${id} を ${sourceName} からインストール中" -ForegroundColor Cyan

        # サイレントでインストールを実行（ライセンスなどに自動で同意し、y/nも出さない）
        winget install --id $id --source $sourceName --accept-package-agreements --accept-source-agreements --silent --disable-interactivity

        # 失敗リストに追加
        if($LASTEXITCODE -ne 0)
        {
            Write-Host "    ->${id} のインストールに失敗しました" -ForegroundColor Red
            $failed += $id
        }
    }
}

write-Host

if($failed.Count -eq 0)
{
    Write-Host "すべてのパッケージのインストールに成功しました！" -ForegroundColor Green
}
else
{
    Write-Host "以下のパッケージはインストールに失敗したので手動での対応が必要です" -ForegroundColor Red
    foreach($item in $failed)
    {
        Write-Host " - $item" -ForegroundColor Red
    }
}
