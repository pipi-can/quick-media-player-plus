#pragma once

#include <QString>
#include <QtGlobal>

/**
 * @brief 一条媒体文件
 *
 * 列表显示要的字段和探测出来的字段都放这里：探测层（MediaProbe）打开文件后把结果填进来，
 * 队列（PlayList）直接存这一份，显示和播放都读它。全局只有这一个类型，不再分「文件」和「信息」。
 */
struct MediaFile
{
    // 文件本身
    QString name;  // 列表上显示的文件名
    QString path;  // 播放器要打开的路径

    // 探测出来的
    bool opened = false;          // 能不能打开；false 时下面几点都没有意义
    bool hasVideoStream = false;  // 有没有视频流
    bool hasAudioStream = false;  // 有没有音频流
    qint64 durationMs = 0;        // 时长，毫秒
    QString format;               // 容器格式，例如 "matroska,webm"
    QString resolution;           // 视频流尺寸，例如 "1920x1080"
    QString codec;                // 视频流编码，例如 "h264"
    QString decoder;              // 解码器名字，例如 "h264 (native)"
    QString audio;                // 音频流编码，例如 "aac"

    // 显示用的字符串，还没定是在这边格式化还是 QML 拿原始值自己写
    QString length;  // 时长的显示文字，例如 "05:27"
    QString size;    // 文件大小的显示文字，例如 "1.2 GB"
};
