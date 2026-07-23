## 俺のPC環境を自動で構築するスクリプト
これからいろいろ追加予定
cd $env:TEMP;curl.exe -L https://github.com/Makura0328/Windows_Setup/archive/refs/heads/main.zip -o a.zip;tar -xf a.zip;cd Windows_Setup-main;powershell -ep bypass -f .\scripts\00-run-all.ps1
