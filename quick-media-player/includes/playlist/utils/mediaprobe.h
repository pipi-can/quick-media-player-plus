#pragma once

#include <QString>
#include <QtGlobal>

/**
 * @brief 一次探测拿到的信息
 *
 * 一个文件进哪条队列看有没有视频流：有视频流算视频，只有音频流算音乐。
 * 后缀只说明文件名，说明不了里面装的是什么，所以不参与判断。
 */
struct MediaInfo
{
    bool opened = false;          // 文件能不能打开；false 时下面的字段都没有意义
    bool hasVideoStream = false;  // 有没有视频流
    bool hasAudioStream = false;  // 有没有音频流
    qint64 durationMs = 0;        // 时长，毫秒
    QString format;               // 容器格式，例如 "matroska,webm"
    QString resolution;           // 视频流尺寸，例如 "1920x1080"
    QString videoCodec;           // 视频流编码，例如 "h264"
    QString decoder;              // 解码器名字，例如 "h264 (native)"
    QString audioCodec;           // 音频流编码，例如 "aac"
};

/**
 * @brief 媒体探测：打开一个文件，看里面有没有视频流
 *
 * 拿路径直接用：MediaProbe::probe(path)。只读文件头、不解码，不持有状态。
 */
class MediaProbe
{
public:
    /**
     * @brief 探测一个文件
     * @param path 本地文件路径
     * @retval 探测结果；opened 为 false 表示打不开（文件不在、格式不认）
     */
    static MediaInfo probe(const QString &path);
};
