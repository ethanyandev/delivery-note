#!/bin/bash

# 构建 macOS .app 并打包成 DMG
# 用法: ./build_mac.sh          (当前架构)
#       ./build_mac.sh --intel  (交叉编译 Intel x64 包)
# 输出: dist/送货单生成系统-mac-<arch>.dmg

set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

# 支持 --intel 参数，在 Apple Silicon 上交叉编译 Intel 包
FORCE_INTEL=false
if [ "$1" = "--intel" ]; then
    FORCE_INTEL=true
fi

if [ "$FORCE_INTEL" = true ]; then
    ARCH_LABEL="Intel (cross-compile)"
    ARCH_SUFFIX="x64"
    # 使用系统自带的 universal python3，通过 Rosetta 以 x86_64 模式运行
    PYTHON_CMD="arch -x86_64 /usr/bin/python3"
    PIP_PREFIX="arch -x86_64"
else
    ARCH=$(uname -m)
    if [ "$ARCH" = "arm64" ]; then
        ARCH_LABEL="Apple Silicon"
        ARCH_SUFFIX="arm64"
    else
        ARCH_LABEL="Intel"
        ARCH_SUFFIX="x64"
    fi
    PYTHON_CMD="python3"
    PIP_PREFIX=""
fi

echo "========================================="
echo "  构建 macOS 安装包 ($ARCH_LABEL)"
echo "========================================="
echo ""

# 0. 创建干净的 venv（避免 anaconda 干扰）
if [ "$FORCE_INTEL" = true ]; then
    VENV="$DIR/.buildenv-x64"
else
    VENV="$DIR/.buildenv"
fi

if [ ! -d "$VENV" ]; then
    echo "[0/4] 创建构建环境..."
    $PYTHON_CMD -m venv "$VENV"
    $PIP_PREFIX "$VENV/bin/python3" -m pip install -q fastapi uvicorn openpyxl python-multipart pywebview pyinstaller
    echo "  构建环境就绪"
else
    echo "[0/4] 构建环境已存在"
fi

# 1. 构建前端
echo "[1/4] 构建前端..."
cd "$DIR/frontend"
if [ ! -d "node_modules" ]; then
    npm install -q
fi
npm run build -q 2>&1 | grep -v "^$"
echo "  前端构建完成"

# 2. 打包
echo "[2/4] 打包应用..."
cd "$DIR/backend"

# 清理旧构建
rm -rf build dist *.spec

$PIP_PREFIX "$VENV/bin/python3" -m PyInstaller \
    --name "送货单生成系统" \
    --windowed \
    --noconfirm \
    --clean \
    --add-data "templates:templates" \
    --add-data "../frontend/dist:static" \
    desktop.py 2>&1 | grep -E "completed successfully|ERROR"

# 3. 制作 DMG
echo "[3/4] 制作 DMG..."
cd "$DIR/backend/dist"
DMG_NAME="送货单生成系统-mac-${ARCH_SUFFIX}.dmg"
rm -f "$DMG_NAME"

# 临时目录里摆放 .app + 指向 /Applications 的快捷方式，
# 这样打开 DMG 时是经典的"把 App 拖进 Applications"安装界面
STAGING="$DIR/backend/dist/.dmg-staging"
rm -rf "$STAGING"
mkdir -p "$STAGING"
cp -R "送货单生成系统.app" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

# hdiutil 是 macOS 系统自带命令，无需任何额外依赖
hdiutil create \
    -volname "送货单生成系统" \
    -srcfolder "$STAGING" \
    -fs HFS+ \
    -format UDZO \
    -ov \
    "$DMG_NAME"

rm -rf "$STAGING"

# 4. 输出
SIZE=$(du -sh "$DMG_NAME" | cut -f1)
APP_SIZE=$(du -sh "送货单生成系统.app" | cut -f1)
echo ""
echo "========================================="
echo "  构建完成!"
echo ""
echo "  .app 大小: $APP_SIZE"
echo "  .dmg 大小: $SIZE"
echo "  架构: macOS $ARCH_LABEL"
echo ""
echo "  安装包: backend/dist/$DMG_NAME"
echo "========================================="
echo ""
echo "分发: 将 .dmg 发送给用户，双击打开后把 App 拖入 Applications 即可"
echo "注意: 未签名，用户首次打开需右键→打开，或先执行 xattr -cr 送货单生成系统.app"
