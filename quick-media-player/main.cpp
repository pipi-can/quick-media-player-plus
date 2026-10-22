#include <QFont>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtQml>

#include "utils/logger.h"

int main(int argc, char *argv[])
{
    // Qt 默认禁止 QML 读取 qrc 里的 json，主题配色打不开这个开关
    qputenv("QML_XHR_ALLOW_FILE_READ", "1");
    // Windows 自带样式不许改 Slider 的轨道和圆点，要在创建应用之前换成 Basic
    qputenv("QT_QUICK_CONTROLS_STYLE", "Basic");

    QGuiApplication app(argc, argv);

    // 本机没有 Segoe UI、苹方、微软雅黑。思源黑体是已经装上的中文界面字体
    QFont appFont(QStringLiteral("Source Han Sans SC"));
    app.setFont(appFont);

    Logger::getInstance().setLogLevel(Logger::Debug);
    LOG_DEBUG("logger ready");

    // 任务栏图标和标题栏「QMediaPlayer」左侧是同一个资源
    const QIcon windowIcon(QStringLiteral(":/quick-media-player/resources/AppIcons/MainIcon.svg"));
    if (windowIcon.isNull())
        LOG_ERROR("窗口图标资源打不开");
    app.setWindowIcon(windowIcon);

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("Logger"), &Logger::getInstance());
    // 上下文属性已经叫 Logger。枚举类型换个名字，QML 才读得到等级
    qmlRegisterUncreatableMetaObject(
        Logger::staticMetaObject,
        "LogLevel",
        1, 0,
        "LogLevel",
        "日志等级只能读，不能创建");
    const QUrl url(QStringLiteral("qrc:/quick-media-player/qml/main.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
