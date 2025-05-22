#!/bin/bash

# 设置 IPK 根目录（可自定义）
IPK_DIR="/root/ipk"
ARCH=$(opkg print-architecture | awk '{print $2}' | tail -n1)

echo "-----------------------------------------------------"
echo "在 '$IPK_DIR' 目录中递归搜索 .ipk 文件并强制安装..."
echo "架构: $ARCH"
echo "-----------------------------------------------------"

# 过滤掉 macOS 资源文件和其他非 ipk
find "$IPK_DIR" -type f -name "*.ipk" ! -name "._*" | while read -r ipk; do
    echo "==> 准备安装: $ipk"

    # 解压验证
    mkdir -p /tmp/ipktmp
    if ! tar -tf "$ipk" > /dev/null 2>&1; then
        echo "    🚫 无法解压，可能是损坏的 IPK 文件: $ipk"
        continue
    fi

    # 读取 control 文件中的 Package 字段
    PKG_NAME=$(tar -xOf "$ipk" ./control.tar.gz 2>/dev/null | tar -xzOf - ./control 2>/dev/null | grep '^Package:' | cut -d' ' -f2)
    if [[ -z "$PKG_NAME" ]]; then
        echo "    🚫 读取不到 Package 名称，跳过。"
        continue
    fi

    # 强制安装
    opkg install --force-depends "$ipk"
    if [[ $? -ne 0 ]]; then
        echo "    ❌ 安装失败: $ipk"
    else
        echo "    ✅ 成功安装: $ipk"
    fi
    echo "-----------------------------------------------------"
done

