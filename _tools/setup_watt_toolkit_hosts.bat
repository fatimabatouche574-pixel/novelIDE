@echo off
chcp 65001 >nul
echo ========================================
echo   Watt Toolkit GitHub 加速配置
echo ========================================
echo.

set HOSTS=%SystemRoot%\System32\drivers\etc\hosts

echo 正在备份当前 hosts 文件...
copy "%HOSTS%" "%HOSTS%.bak" >nul 2>&1
echo 备份完成
echo.

echo 正在写入 Watt Toolkit 加速配置...
(
echo # Copyright (c) 1993-2009 Microsoft Corp.
echo # localhost name resolution is handled within DNS itself.
echo #	127.0.0.1       localhost
echo #	::1             localhost
echo.
echo # Watt Toolkit GitHub Acceleration
echo 127.0.0.1 huggingface.co
echo 127.0.0.1 github.dev
echo 127.0.0.1 api.github.com
echo 127.0.0.1 github.githubassets.com
echo 127.0.0.1 support-assets.githubassets.com
echo 127.0.0.1 education.github.com
echo 127.0.0.1 resources.github.com
echo 127.0.0.1 uploads.github.com
echo 127.0.0.1 archiveprogram.github.com
echo 127.0.0.1 raw.github.com
echo 127.0.0.1 githubusercontent.com
echo 127.0.0.1 raw.githubusercontent.com
echo 127.0.0.1 camo.githubusercontent.com
echo 127.0.0.1 cloud.githubusercontent.com
echo 127.0.0.1 avatars.githubusercontent.com
echo 127.0.0.1 avatars0.githubusercontent.com
echo 127.0.0.1 avatars1.githubusercontent.com
echo 127.0.0.1 avatars2.githubusercontent.com
echo 127.0.0.1 avatars3.githubusercontent.com
echo 127.0.0.1 user-images.githubusercontent.com
echo 127.0.0.1 objects.githubusercontent.com
echo 127.0.0.1 private-user-images.githubusercontent.com
echo 127.0.0.1 github.com
echo 127.0.0.1 pages.github.com
echo 127.0.0.1 gist.github.com
echo 127.0.0.1 githubapp.com
echo 127.0.0.1 github.io
echo 127.0.0.1 www.github.io
echo # Watt Toolkit End
) > "%HOSTS%"

echo.
echo ========================================
echo   配置完成！
echo ========================================
echo.
echo 请确保 Watt Toolkit 已开启 GitHub 加速
echo git push / curl 都会通过 Watt Toolkit 代理访问
echo.
pause
