#!/bin/bash
# 恢复原版 Caelestia shell

set -e

DEST="/etc/xdg/quickshell/caelestia"

if [ "$EUID" -ne 0 ]; then
    echo "请使用 sudo 运行此脚本"
    exit 1
fi

if [ -d "${DEST}.bak" ]; then
    echo "恢复原版 ..."
    rm -rf "$DEST"
    mv "${DEST}.bak" "$DEST"

    echo "重启 Caelestia shell ..."
    if command -v caelestia &> /dev/null; then
        caelestia shell -k 2>/dev/null || true
        sleep 1
        caelestia shell -d
    fi
    echo "已恢复原版！"
else
    echo "未找到备份 (${DEST}.bak)，无法恢复"
    exit 1
fi
