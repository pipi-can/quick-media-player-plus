#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "utils/logger.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    Logger::getInstance().setLogLevel(Logger::Debug);
    LOG_DEBUG("logger ready");

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("Logger"), &Logger::getInstance());
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
