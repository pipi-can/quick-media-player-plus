#pragma once

#include <QObject>
#include <QString>

#include <vector>

/**
 * @brief 整个播放器的播放队列
 *
 * 视频和音乐各一条队列，两条队列共用一个播放器，所以同一时刻只有一条在播，
 * 谁在播由 activeType 说。队列只管「放哪一条」，暂停/播放状态归播放层。
 */
class PlayList : public QObject
{
    Q_OBJECT

public:
    // 队列只有视频和音乐两种。None 只出现在 activeType 上：没有哪条队列在播
    enum MediaType {
        None = 0,
        Video = 1,
        Music = 2
    };
    Q_ENUM(MediaType)

    // 播放模式管的是「一条放完之后接着放哪条」，手动点上一首/下一首不看它
    enum PlayMode {
        SinglePlay = 0,      // 单曲播放：这条放完就停
        SingleLoop = 1,      // 单曲循环：一直重放这条
        Sequential = 2,      // 顺序播放：往下一条走，到队尾就停
        SequentialLoop = 3,  // 顺序循环：到队尾绕回第一条
        Shuffle = 4          // 随机播放：随机换一条，不会连着放同一条
    };
    Q_ENUM(PlayMode)

    // 一条媒体文件。时长、分辨率、编码这些要探测出来的字段先留空，等播放层接上再补
    struct MediaFile {
        QString name;        // 列表上显示的文件名
        QString path;        // 播放器要打开的路径
        QString length;      // 时长的显示文字，例如 "05:27"
        QString format;
        QString resolution;
        QString codec;
        QString decoder;
        QString audio;
        QString size;
    };

    static PlayList &getInstance();

    PlayList(const PlayList &) = delete;
    PlayList &operator=(const PlayList &) = delete;

    /**
     * @brief 加一条媒体文件
     * @param source 文件路径，按后缀认视频还是音乐
     * @retval true 加进队列了；false 后缀认不出来，没加
     */
    bool addMedia(const QString &source);

    /**
     * @brief 加一条探测好的媒体文件
     * @param file 至少要有 path，按 path 的后缀认队列
     * @retval true 加进队列了；false 后缀认不出来，没加
     */
    bool addMedia(const MediaFile &file);

    /**
     * @brief 从队列里删掉一条
     * @param type 哪条队列
     * @param index 要删的下标
     * @retval true 删掉了；false 下标越界
     */
    bool removeMedia(MediaType type, int index);

    void clear(MediaType type);

    int count(MediaType type) const;

    /**
     * @brief 取队列里的一条
     * @param type 哪条队列
     * @param index 下标
     * @retval 下标越界时返回空项（path 为空）
     */
    MediaFile mediaAt(MediaType type, int index) const;

    int currentIndex(MediaType type) const;

    // 当前这条的 path。播放器直接读它，不用自己去列表里对下标
    QString currentSource(MediaType type) const;

    PlayMode playMode(MediaType type) const;
    void setPlayMode(MediaType type, PlayMode mode);

    // 控制条上显示的名字，映射只留这一份
    static QString playModeName(PlayMode mode);

    // 播放器的输入现在取自哪条队列，None 表示没在播
    MediaType activeType() const;
    bool isActive(MediaType type) const;

    /**
     * @brief 从某条队列的第 index 条开始播
     * @param type 哪条队列
     * @param index 下标
     * @retval true 选中了；false 下标越界
     */
    bool play(MediaType type, int index);

    // 用户点上一首/下一首：沿列表走一格，两端环绕，不看播放模式
    void selectNext(MediaType type);
    void selectPrevious(MediaType type);

    // 播放器报告当前这条放完了，按播放模式决定接着放哪条
    void mediaFinished(MediaType type);

    void stop();

    // 按后缀认队列，认不出来返回 None。等接了媒体探测再换成读 QMediaFormat
    static MediaType typeOfSource(const QString &source);

signals:
    void queueContentChanged(MediaType type);  // 加、删、清空都发这个
    void currentChanged(MediaType type, int index, const QString &source);
    void playModeChanged(MediaType type, PlayMode mode);
    void activeTypeChanged(MediaType type);

private:
    // 一条队列的全部状态。两条队列走同一套算法，所以状态放结构体、算法只写一遍
    struct Queue {
        std::vector<MediaFile> items;
        int currentIndex = -1;                 // -1 表示还没有选中过
        QString currentSource;                 // 跟着 currentIndex 走
        PlayMode playMode = SequentialLoop;    // 控制条默认显示顺序循环
    };

    PlayList();
    ~PlayList() override;

    Queue *queueFor(MediaType type);
    const Queue *queueFor(MediaType type) const;

    /**
     * @brief 按播放模式算这条放完之后接着放哪条
     * @param queue 当前队列
     * @retval 下一条的下标；-1 表示按模式就该停了
     */
    static int nextIndexByMode(const Queue &queue);

    // 手动换一条：在列表里走 step 格，两端环绕
    void jump(MediaType type, int step);

    void setCurrentIndex(MediaType type, int index);

    static PlayList s_instance;

    Queue m_videoQueue;
    Queue m_musicQueue;
    MediaType m_activeType = None;
};
