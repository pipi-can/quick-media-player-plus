#include "playlist/utils/mediaprobe.h"

#include <QtGlobal>

MediaInfo MediaProbe::probe(const QString &path)
{
    // ffmpeg 写在这里：avformat_open_input → avformat_find_stream_info → 遍历流看有没有
    // AVMEDIA_TYPE_VIDEO / AVMEDIA_TYPE_AUDIO → avformat_close_input。
    // 还没接，先一律报「打不开」，免得外面把没探测过的文件当成能播的
    Q_UNUSED(path)
    return MediaInfo();
}
