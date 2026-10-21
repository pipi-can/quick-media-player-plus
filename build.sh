#!/usr/bin/env bash
# --build 用指定的 Qt gcc_64 目录编译；--run 运行 build/ 里已经编好的程序
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${ROOT}/build"
APP="${BUILD_DIR}/appquick-media-player"

usage() {
    echo "用法:"
    echo "  $0 --build <Qt 的 gcc_64 目录>  编译到 build/"
    echo "  $0 --run                        运行已编译的程序"
    echo "示例:"
    echo "  $0 --build /home/Qt/6.5.3/gcc_64"
    echo "  $0 --run"
}

if [ $# -lt 1 ]; then
    echo "缺少参数。"
    usage
    exit 1
fi

case "$1" in
    --build)
        if [ $# -ne 2 ]; then
            echo "--build 需要一个 Qt 的 gcc_64 目录。"
            usage
            exit 1
        fi
        QT_GCC_PATH=$2
        if [ ! -d "${QT_GCC_PATH}" ]; then
            echo "找不到目录: ${QT_GCC_PATH}"
            usage
            exit 1
        fi
        if [ ! -f "${QT_GCC_PATH}/lib/cmake/Qt6/Qt6Config.cmake" ]; then
            echo "这个目录里没有 Qt 6: ${QT_GCC_PATH}"
            usage
            exit 1
        fi
        cmake -S "${ROOT}/quick-media-player" -B "${BUILD_DIR}" \
            -DCMAKE_PREFIX_PATH="${QT_GCC_PATH}"
        cmake --build "${BUILD_DIR}"
        ;;
    --run)
        if [ $# -ne 1 ]; then
            echo "--run 不需要其他参数。"
            usage
            exit 1
        fi
        if [ ! -e "${APP}" ]; then
            echo "还没有可执行文件: ${APP}"
            echo "请先用 --build 编译。"
            usage
            exit 1
        fi
        if [ ! -x "${APP}" ]; then
            echo "文件存在但不能执行: ${APP}"
            exit 1
        fi
        "${APP}"
        ;;
    *)
        echo "无法识别的参数: $1"
        usage
        exit 1
        ;;
esac
