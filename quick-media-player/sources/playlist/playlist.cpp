#include "playlist/playlist.h"

#include <QFileInfo>
#include <QRandomGenerator>

#include "utils/logger.h"

PlayList::PlayList()
    : QObject(nullptr)
{
}

PlayList::~PlayList() = default;

// 饿汉：启动时构造。跟 Logger 一样，析构私有，调用方拿不到所有权
PlayList PlayList::s_instance;

PlayList &PlayList::getInstance()
{
    return s_instance;
}

bool PlayList::addMedia(const QString &path)
{
    const MediaInfo info = MediaProbe::probe(path);
    if (!info.opened || (!info.hasVideoStream && !info.hasAudioStream)) {
        LOG_WARNING("这个文件里没有能播的流，没进队列：%s", qPrintable(path));
        return false;
    }

    // 有视频流就进视频队列，只有音频流才进音乐队列。后缀不参与判断
    const MediaType type = info.hasVideoStream ? Video : Music;

    MediaFile file;
    file.path = path;
    file.name = QFileInfo(path).fileName();
    file.format = info.format;
    file.resolution = info.resolution;
    file.codec = info.videoCodec;
    file.decoder = info.decoder;
    file.audio = info.audioCodec;
    // length、size 是显示用的字符串，等接播放层时再定这边格式化还是 QML 自己写
    return appendMedia(type, file);
}

bool PlayList::appendMedia(MediaType type, const MediaFile &file)
{
    Queue *queue = queueFor(type);
    if (queue == nullptr)
        return false;

    queue->items.push_back(file);
    emit queueContentChanged(type);
    return true;
}

bool PlayList::removeMedia(MediaType type, int index)
{
    Queue *queue = queueFor(type);
    if (queue == nullptr || index < 0 || index >= static_cast<int>(queue->items.size()))
        return false;

    queue->items.erase(queue->items.begin() + index);

    // 删的是当前位置之前的，后面都往前挪了一格，下标要跟着减；
    // 删的正好是当前这条，就让后面那条顶上来，后面没有了就收成未选中
    if (index < queue->currentIndex)
        setCurrentIndex(type, queue->currentIndex - 1);
    else if (index == queue->currentIndex)
        setCurrentIndex(type, queue->currentIndex);

    emit queueContentChanged(type);

    // 播放器正看着这条队列，而它已经没有这一条了，别再让它去读一个不存在的路径
    if (m_activeType == type && queue->currentIndex < 0)
        stop();
    return true;
}

void PlayList::clear(MediaType type)
{
    Queue *queue = queueFor(type);
    if (queue == nullptr || queue->items.empty())
        return;

    queue->items.clear();
    setCurrentIndex(type, -1);
    emit queueContentChanged(type);

    if (m_activeType == type)
        stop();
}

int PlayList::count(MediaType type) const
{
    const Queue *queue = queueFor(type);
    return queue == nullptr ? 0 : static_cast<int>(queue->items.size());
}

PlayList::MediaFile PlayList::mediaAt(MediaType type, int index) const
{
    const Queue *queue = queueFor(type);
    if (queue == nullptr || index < 0 || index >= static_cast<int>(queue->items.size()))
        return MediaFile();
    return queue->items.at(index);
}

int PlayList::currentIndex(MediaType type) const
{
    const Queue *queue = queueFor(type);
    return queue == nullptr ? -1 : queue->currentIndex;
}

QString PlayList::currentSource(MediaType type) const
{
    const Queue *queue = queueFor(type);
    return queue == nullptr ? QString() : queue->currentSource;
}

PlayList::PlayMode PlayList::playMode(MediaType type) const
{
    const Queue *queue = queueFor(type);
    return queue == nullptr ? SequentialLoop : queue->playMode;
}

void PlayList::setPlayMode(MediaType type, PlayMode mode)
{
    Queue *queue = queueFor(type);
    if (queue == nullptr || queue->playMode == mode)
        return;

    queue->playMode = mode;
    emit playModeChanged(type, mode);
}

QString PlayList::playModeName(PlayMode mode)
{
    switch (mode) {
    case SinglePlay:
        return QStringLiteral("单曲播放");
    case SingleLoop:
        return QStringLiteral("单曲循环");
    case Sequential:
        return QStringLiteral("顺序播放");
    case SequentialLoop:
        return QStringLiteral("顺序循环");
    case Shuffle:
    default:
        return QStringLiteral("随机播放");
    }
}

PlayList::MediaType PlayList::activeType() const
{
    return m_activeType;
}

bool PlayList::isActive(MediaType type) const
{
    return type != None && m_activeType == type;
}

bool PlayList::play(MediaType type, int index)
{
    Queue *queue = queueFor(type);
    if (queue == nullptr || index < 0 || index >= static_cast<int>(queue->items.size()))
        return false;

    setCurrentIndex(type, index);

    // 只有一个播放器，两条队列不能同时占着：切到哪条队列 activeType 就指哪条。
    // 另一条队列的 currentIndex 留着不动，只是不再是「正在播放」的那条
    if (m_activeType != type) {
        m_activeType = type;
        emit activeTypeChanged(m_activeType);
    }
    return true;
}

void PlayList::selectNext(MediaType type)
{
    jump(type, 1);
}

void PlayList::selectPrevious(MediaType type)
{
    jump(type, -1);
}

void PlayList::mediaFinished(MediaType type)
{
    const Queue *queue = queueFor(type);
    if (queue == nullptr)
        return;

    const int next = nextIndexByMode(*queue);
    if (next < 0) {
        stop();  // 单曲播放、顺序播放到头了：不换曲，就停在这条上
        return;
    }
    play(type, next);
}

void PlayList::stop()
{
    if (m_activeType == None)
        return;

    m_activeType = None;
    emit activeTypeChanged(m_activeType);
}

PlayList::Queue *PlayList::queueFor(MediaType type)
{
    switch (type) {
    case Video:
        return &m_videoQueue;
    case Music:
        return &m_musicQueue;
    default:
        return nullptr;
    }
}

const PlayList::Queue *PlayList::queueFor(MediaType type) const
{
    // 只有 const 不一样，不用把 switch 抄两遍
    return const_cast<PlayList *>(this)->queueFor(type);
}

int PlayList::nextIndexByMode(const Queue &queue)
{
    const int count = static_cast<int>(queue.items.size());
    if (count == 0)
        return -1;
    if (queue.currentIndex < 0 || queue.currentIndex >= count)
        return 0;  // 还没选中过，从第一条开始

    switch (queue.playMode) {
    case SinglePlay:
        return -1;
    case SingleLoop:
        return queue.currentIndex;
    case Sequential:
        return queue.currentIndex + 1 < count ? queue.currentIndex + 1 : -1;
    case SequentialLoop:
        return (queue.currentIndex + 1) % count;
    case Shuffle:
    default: {
        if (count == 1)
            return 0;
        // 连着放同一条没意义，所以从「去掉当前这条」的范围里抽
        const int pick = QRandomGenerator::global()->bounded(count - 1);
        return pick < queue.currentIndex ? pick : pick + 1;
    }
    }
}

void PlayList::jump(MediaType type, int step)
{
    Queue *queue = queueFor(type);
    if (queue == nullptr || queue->items.empty() || step == 0)
        return;

    const int count = static_cast<int>(queue->items.size());
    int index = queue->currentIndex;
    if (index < 0 || index >= count)
        index = step > 0 ? -1 : count;  // 还没选中过：下一个从头开始，上一个从末尾开始

    // 手动点不看播放模式：单曲那两种的「停在原地」说的是自动播放，
    // 用户按了下一首就该给他换，所以这里两端直接环绕
    play(type, (index + step + count) % count);
}

void PlayList::setCurrentIndex(MediaType type, int index)
{
    Queue *queue = queueFor(type);
    if (queue == nullptr)
        return;

    const bool valid = index >= 0 && index < static_cast<int>(queue->items.size());
    const int nextIndex = valid ? index : -1;
    const QString nextSource = valid ? queue->items.at(nextIndex).path : QString();

    // 下标一样但那条被换掉了（删掉当前这条之后后面顶上来）也算变了，所以要比 source
    if (queue->currentIndex == nextIndex && queue->currentSource == nextSource)
        return;

    queue->currentIndex = nextIndex;
    queue->currentSource = nextSource;
    emit currentChanged(type, nextIndex, nextSource);
}
