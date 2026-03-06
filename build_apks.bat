@echo off
:: 设置编码为 UTF-8 以解决中文乱码
chcp 65001 >nul

echo ===================================================
echo   AstrBot Manager 一键打包脚本喵✨
echo ===================================================
echo.
echo 正在执行：flutter build apk --split-per-abi --release
echo.
call flutter build apk --split-per-abi --release
echo.
echo 正在执行：flutter build apk --release
echo.
call flutter build apk --release
echo.
echo ===================================================
echo   打包完成喵！APK 文件位于：
echo   build\app\outputs\flutter-apk\
echo ===================================================
pause
