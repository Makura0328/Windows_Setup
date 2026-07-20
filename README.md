## 俺のPC環境を自動で構築するスクリプト
これからいろいろ追加予定
iwr https://github.com/Makura0328/Windows_Setup/archive/refs/heads/main.zip -OutFile $env:TEMP\a.zip;Expand-Archive $env:TEMP\a.zip $env:TEMP\a -Force;& "$env:TEMP\a\Windows_Setup-main\scripts\00-run-all.ps1"
