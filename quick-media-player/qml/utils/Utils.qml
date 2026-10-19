import QtQuick

// 不加参数类型：编译后的函数调用栈会丢掉调用方行号
Item {
    function debug(message) {
        const caller = new Error().stack.split("\n")[1]
        const at = caller.lastIndexOf("@")
        const place = caller.slice(at + 1)
        const colon = place.lastIndexOf(":")
        Logger.log(Logger.Debug, place.slice(0, colon), parseInt(place.slice(colon + 1)), message)
    }

    // QML 读不到日志等级枚举，错误固定走日志类的 logError
    function error(message) {
        const caller = new Error().stack.split("\n")[1]
        const at = caller.lastIndexOf("@")
        const place = caller.slice(at + 1)
        const colon = place.lastIndexOf(":")
        Logger.logError(place.slice(0, colon), parseInt(place.slice(colon + 1)), message)
    }
}
