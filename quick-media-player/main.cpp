#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtQml>

#include "utils/logger.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    Logger::getInstance().setLogLevel(Logger::Debug);
    LOG_DEBUG("logger ready");

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
