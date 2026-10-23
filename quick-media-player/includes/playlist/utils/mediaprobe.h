#pragma once

#include <QString>

#include "playlist/utils/mediafile.h"

/**
 * @brief 媒体探测：打开一个文件，看里面有没有视频流
 *
 * 拿路径直接用：MediaProbe::probe(path)，返回的 MediaFile 里 name、path 和探测结果都填好了。
 * 只读文件头、不解码，不持有状态。
 */
class MediaProbe
{
public:
    /**
     * @brief 探测一个文件
     * @param path 本地文件路径
     * @retval 填好的 MediaFile；opened 为 false 表示打不开（文件不在、格式不认）
     */
    static MediaFile probe(const QString &path);
};
