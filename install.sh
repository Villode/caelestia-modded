#!/bin/bash
# caelestia-modded 安装脚本
# 将魔改版 shell 部署到系统目录

set -e

DEST="/etc/xdg/quickshell/caelestia"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 检查是否以 root 运行
if [ "$EUID" -ne 0 ]; then
    echo "请使用 sudo 运行此脚本"
    echo "用法: sudo ./install.sh"
    exit 1
fi

# 备份原版（如果没有备份过）
if [ -d "$DEST" ] && [ ! -d "${DEST}.bak" ]; then
    echo "备份原版到 ${DEST}.bak ..."
    cp -r "$DEST" "${DEST}.bak"
fi

# 复制文件
echo "安装 caelestia-modded ..."
cp -r "$SCRIPT_DIR"/assets "$DEST"/
cp -r "$SCRIPT_DIR"/components "$DEST"/
cp -r "$SCRIPT_DIR"/config "$DEST"/
cp -r "$SCRIPT_DIR"/modules "$DEST"/
cp -r "$SCRIPT_DIR"/services "$DEST"/
cp -r "$SCRIPT_DIR"/utils "$DEST"/
cp "$SCRIPT_DIR"/shell.qml "$DEST"/

# 重启 shell
echo "重启 Caelestia shell ..."
if command -v caelestia &> /dev/null; then
    caelestia shell -k 2>/dev/null || true
    sleep 1
    caelestia shell -d
fi

echo "安装完成！"
