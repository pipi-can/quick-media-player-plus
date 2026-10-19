#include "utils/logger.h"

#include <QDateTime>

#include <cstdarg>
#include <cstdio>

namespace {

const char *levelName(Logger::Level level)
{
    switch (level) {
    case Logger::Warning:
        return "WARNING";
    case Logger::Error:
        return "ERROR";
    case Logger::Debug:
    default:
        return "DEBUG";
    }
}

}

Logger::Logger()
    : QObject(nullptr)
    , m_logLevel(Debug)
{
}

Logger::~Logger() = default;

// 饿汉：启动时构造。析构私有，调用方不能销毁这份唯一实例
Logger Logger::s_instance;

Logger &Logger::getInstance()
{
    return s_instance;
}

Logger::Level Logger::logLevel() const
{
    return m_logLevel;
}

void Logger::setLogLevel(Level level)
{
    if (m_logLevel == level)
        return;
    m_logLevel = level;
    emit logLevelChanged();
}

QString Logger::fileBaseName(const QString &path)
{
    const int slash = qMax(path.lastIndexOf('/'), path.lastIndexOf('\\'));
    return slash >= 0 ? path.mid(slash + 1) : path;
}

void Logger::write(Level level, const QString &fileName, int line, const QString &message)
{
    if (level < m_logLevel)
        return;

    const QString text = QStringLiteral("[%1][%2]\t%3:%4\t%5")
                             .arg(QDateTime::currentDateTime().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss")),
                                  QLatin1String(levelName(level)),
                                  fileName)
                             .arg(line)
                             .arg(message);
    std::fprintf(stdout, "%s\n", text.toUtf8().constData());
    std::fflush(stdout);
}

void Logger::log(Level level, const char *file, int line, const char *fmt, ...)
{
    if (level < m_logLevel || fmt == nullptr)
        return;

    va_list args;
    va_start(args, fmt);
    const QString message = QString::vasprintf(fmt, args);
    va_end(args);
    write(level, fileBaseName(QString::fromUtf8(file)), line, message);
}

void Logger::log(Level level, const QString &file, int line, const QString &message)
{
    write(level, fileBaseName(file), line, message);
}

void Logger::logError(const QString &file, int line, const QString &message)
{
    log(Error, file, line, message);
}
