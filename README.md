# quick-media-player

用 C++ 和 Qt 6 写的桌面播放器。界面在 `quick-media-player/qml/`，程序入口是 `quick-media-player/main.cpp`。

## 编译

需要：

- CMake 3.16 或更高
- g++
- Qt 6，并且装有 Quick、Core5Compat。本机装在 `/home/Qt/6.5.3/gcc_64`

在仓库根目录用 `build.sh`。`--build` 后面跟 Qt 的 `gcc_64` 目录，构建目录固定为仓库根下的 `build/`。`--run` 运行已经编好的程序。`--rebuild` 是先编译再运行。`--clean` 删除这个 `build/`。

```bash
chmod +x build.sh
./build.sh --build /home/Qt/6.5.3/gcc_64
./build.sh --run
./build.sh --rebuild /home/Qt/6.5.3/gcc_64
./build.sh --clean
```

`--build` 会依次执行：

```bash
cmake -S quick-media-player -B build \
    -DCMAKE_PREFIX_PATH=/home/Qt/6.5.3/gcc_64
cmake --build build
```

`CMAKE_PREFIX_PATH` 用来告诉 CMake 去哪找 Qt 6。系统自带的 qmake 是 Qt 5，不传这个目录会找不到 Qt 6。

编好的程序是 `build/appquick-media-player`。还没编译就执行 `--run`，或者没有 `build/` 就执行 `--clean` 时，脚本会说明缺什么。参数不对时，脚本会打印用法。
