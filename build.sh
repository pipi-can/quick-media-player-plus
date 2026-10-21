#!/usr/bin/env bash
# 用指定的 Qt gcc_64 目录配置并编译，构建目录固定为仓库根下的 build/
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${ROOT}/build"

if [ $# -ne 1 ]; then
    echo "用法: $0 <Qt 的 gcc_64 目录>"
    echo "示例: $0 /home/Qt/6.5.3/gcc_64"
    exit 1
fi

QT_GCC_PATH=$1

if [ ! -d "${QT_GCC_PATH}" ]; then
    echo "找不到目录: ${QT_GCC_PATH}"
    exit 1
fi

cmake -S "${ROOT}/quick-media-player" -B "${BUILD_DIR}" \
    -DCMAKE_PREFIX_PATH="${QT_GCC_PATH}"
cmake --build "${BUILD_DIR}"
