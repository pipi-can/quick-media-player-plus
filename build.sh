#!/usr/bin/env bash
# --build 编译，--run 运行，--rebuild 编译后运行，--clean 删除仓库里的 build/
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${ROOT}/build"
APP="${BUILD_DIR}/appquick-media-player"

usage() {
    echo "用法:"
    echo "  $0 --build <Qt 的 gcc_64 目录>    编译到 build/"
    echo "  $0 --run                          运行已编译的程序"
    echo "  $0 --rebuild <Qt 的 gcc_64 目录>  编译后立刻运行"
    echo "  $0 --clean                        删除 build/"
    echo "示例:"
    echo "  $0 --build /home/Qt/6.5.3/gcc_64"
    echo "  $0 --run"
    echo "  $0 --rebuild /home/Qt/6.5.3/gcc_64"
    echo "  $0 --clean"
}

do_build() {
    local qt_gcc_path=$1
    if [ ! -d "${qt_gcc_path}" ]; then
        echo "找不到目录: ${qt_gcc_path}"
        usage
        exit 1
    fi
    if [ ! -f "${qt_gcc_path}/lib/cmake/Qt6/Qt6Config.cmake" ]; then
        echo "这个目录里没有 Qt 6: ${qt_gcc_path}"
        usage
        exit 1
    fi
    cmake -S "${ROOT}/quick-media-player" -B "${BUILD_DIR}" \
        -DCMAKE_PREFIX_PATH="${qt_gcc_path}"
    cmake --build "${BUILD_DIR}"
}

do_run() {
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
}

do_clean() {
    # 只删仓库根下的 build。路径空或变成根目录时拒绝删除
    if [ -z "${BUILD_DIR}" ] || [ "${BUILD_DIR}" = "/" ] || [ "${BUILD_DIR}" != "${ROOT}/build" ]; then
        echo "构建目录异常，拒绝删除: ${BUILD_DIR}"
        exit 1
    fi
    if [ ! -d "${BUILD_DIR}" ]; then
        echo "没有构建目录: ${BUILD_DIR}"
        exit 1
    fi
    rm -rf "${BUILD_DIR}"
    echo "已删除: ${BUILD_DIR}"
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
        do_build "$2"
        ;;
    --run)
        if [ $# -ne 1 ]; then
            echo "--run 不需要其他参数。"
            usage
            exit 1
        fi
        do_run
        ;;
    --rebuild)
        if [ $# -ne 2 ]; then
            echo "--rebuild 需要一个 Qt 的 gcc_64 目录。"
            usage
            exit 1
        fi
        do_build "$2"
        do_run
        ;;
    --clean)
        if [ $# -ne 1 ]; then
            echo "--clean 不需要其他参数。"
            usage
            exit 1
        fi
        do_clean
        ;;
    *)
        echo "无法识别的参数: $1"
        usage
        exit 1
        ;;
esac
