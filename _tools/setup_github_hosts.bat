@echo off
chcp 65001 >nul
echo ========================================
echo   GitHub 加速 Hosts 配置工具
echo ========================================
echo.

set HOSTS=%SystemRoot%\System32\drivers\etc\hosts

echo 正在备份当前 hosts 文件...
copy "%HOSTS%" "%HOSTS%.bak" >nul 2>&1
echo 备份完成: %HOSTS%.bak
echo.

echo 正在写入 GitHub 加速配置...
(
echo # Copyright (c) 1993-2009 Microsoft Corp.
echo # This is a sample HOSTS file used by Microsoft TCP/IP for Windows.
echo # localhost name resolution is handled within DNS itself.
echo #	127.0.0.1       localhost
echo #	::1             localhost
echo.
echo # GitHub520 Host Start - GitHub Acceleration
echo 140.82.113.25                 alive.github.com
echo 20.205.243.168                api.github.com
echo 185.199.110.133               avatars.githubusercontent.com
echo 185.199.110.133               avatars0.githubusercontent.com
echo 185.199.110.133               avatars1.githubusercontent.com
echo 185.199.110.133               avatars2.githubusercontent.com
echo 185.199.110.133               avatars3.githubusercontent.com
echo 185.199.110.133               camo.githubusercontent.com
echo 140.82.112.22                 central.github.com
echo 185.199.110.133               cloud.githubusercontent.com
echo 20.205.243.165                codeload.github.com
echo 185.199.110.133               desktop.githubusercontent.com
echo 20.205.243.166                gist.github.com
echo 192.0.66.2                    github.blog
echo 20.205.243.166                github.com
echo 140.82.113.18                 github.community
echo 185.199.110.215               github.githubassets.com
echo 151.101.193.194               github.global.ssl.fastly.net
echo 185.199.108.153               github.io
echo 185.199.110.133               github.map.fastly.net
echo 185.199.108.153               githubstatus.com
echo 140.82.112.21                 education.github.com
echo 140.82.113.25                 live.github.com
echo 185.199.110.133               media.githubusercontent.com
echo 185.199.110.133               objects.githubusercontent.com
echo 185.199.110.133               raw.githubusercontent.com
echo 185.199.110.133               user-images.githubusercontent.com
echo 185.199.110.133               private-user-images.githubusercontent.com
echo 140.82.112.21                 resources.github.com
echo 20.205.243.168                uploads.github.com
echo 140.82.112.21                 archiveprogram.github.com
echo 20.205.243.168                github.dev
echo 20.205.243.168                githubapp.com
echo 185.199.108.153               www.github.io
echo # GitHub520 Host End
) > "%HOSTS%"

echo.
echo ========================================
echo   配置完成！GitHub 已加速！
echo ========================================
echo.
echo 现在可以关闭 Watt Toolkit 了
echo git push / curl 都能直接访问 GitHub
echo.
pause
