#pragma once

#include <QObject>
#include <QString>

#define LOG_DEBUG(...) \
Logger::getInstance().log(Logger::Debug, __FILE__, __LINE__, __VA_ARGS__)
#define LOG_WARNING(...) \
    Logger::getInstance().log(Logger::Warning, __FILE__, __LINE__, __VA_ARGS__)
#define LOG_ERROR(...) \
    Logger::getInstance().log(Logger::Error, __FILE__, __LINE__, __VA_ARGS__)


class Logger : public QObject
{
    Q_OBJECT

public:
    // 数值越大越严重，只输出大于等于当前等级的日志
    enum Level {
        Debug = 0,
        Warning = 1,
        Error = 2
    };
    Q_ENUM(Level)

    Q_PROPERTY(Level logLevel READ logLevel WRITE setLogLevel NOTIFY logLevelChanged)

    static Logger &getInstance();

    Logger(const Logger &) = delete;
    Logger &operator=(const Logger &) = delete;

    Level logLevel() const;
    void setLogLevel(Level level);

    /**
     * @brief 按 printf 格式写一条日志
     * @param level 本条日志等级
     * @param file 源文件路径，输出时只保留文件名
     * @param line 行号
     * @param fmt printf 格式串
     * @retval 无
     */
    void log(Level level, const char *file, int line, const char *fmt, ...);

    Q_INVOKABLE void log(Level level, const QString &file, int line, const QString &message);

signals:
    void logLevelChanged();

private:
    Logger();
    ~Logger() override;

    void write(Level level, const QString &fileName, int line, const QString &message);
    static QString fileBaseName(const QString &path);

    static Logger s_instance;
    Level m_logLevel;
};

