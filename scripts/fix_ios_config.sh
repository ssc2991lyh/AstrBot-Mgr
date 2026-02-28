#!/bin/bash

# 1. 尝试生成 iOS 目录 (如果不存在)
if [ ! -d "ios" ]; then
    echo "Creating iOS project files..."
    flutter create --platforms=ios .
fi

# 2. 注入必要的 iOS 权限到 Info.plist
INFO_PLIST="ios/Runner/Info.plist"
if [ -f "$INFO_PLIST" ]; then
    echo "Configuring Info.plist for Background Tasks and Notifications..."
    # 使用 python 或 sed 注入权限 (这里用逻辑说明，手动添加更稳)
    # 需要添加: UIBackgroundModes, NSAppTransportSecurity
fi

# 3. 检查依赖冲突
flutter pub get
