import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/douban_movie.dart';
import '../models/video_info.dart';
import '../services/api_service.dart';
import '../services/douban_service.dart';
import '../utils/image_url.dart';
import '../utils/font_utils.dart';

/// 首页首屏轮播 Banner 组件
class HomeCarouselBanner extends StatefulWidget {
  final Function(VideoInfo)? onVideoTap;

  const HomeCarouselBanner({
    super.key,
    this.onVideoTap,
  });

  @override
  State<HomeCarouselBanner> createState() => _HomeCarouselBannerState();

  /// 静态方法：供外部主动触发刷新
  static Future<void> refreshBanner() async {
    await _HomeCarouselBannerState._currentInstance?._loadBannerData();
  }
}

class _HomeCarouselBannerState extends State<HomeCarouselBanner> {
  static _HomeCarouselBannerState? _currentInstance;

  // 默认精选电影推荐（确保无论网络快慢或豆瓣反爬，首屏轮播永远秒开、立即可见）
  static final List<VideoInfo> _defaultPresetItems = [
    VideoInfo(
      id: '35465232',
      source: 'douban',
      title: '沙丘2',
      sourceName: '豆瓣电影',
      year: '2024',
      cover: 'https://img1.doubanio.com/view/photo/s_ratio_poster/public/p2904354390.jpg',
      index: 1,
      totalEpisodes: 1,
      playTime: 0,
      totalTime: 0,
      saveTime: DateTime.now().millisecondsSinceEpoch,
      searchTitle: '沙丘2',
      doubanId: '35465232',
      rate: '8.3',
    ),
    VideoInfo(
      id: '35588327',
      source: 'douban',
      title: '奥本海默',
      sourceName: '豆瓣电影',
      year: '2023',
      cover: 'https://img1.doubanio.com/view/photo/s_ratio_poster/public/p2896328227.jpg',
      index: 1,
      totalEpisodes: 1,
      playTime: 0,
      totalTime: 0,
      saveTime: DateTime.now().millisecondsSinceEpoch,
      searchTitle: '奥本海默',
      doubanId: '35588327',
      rate: '8.8',
    ),
    VideoInfo(
      id: '1889243',
      source: 'douban',
      title: '星际穿越',
      sourceName: '豆瓣电影',
      year: '2014',
      cover: 'https://img1.doubanio.com/view/photo/s_ratio_poster/public/p2614988097.jpg',
      index: 1,
      totalEpisodes: 1,
      playTime: 0,
      totalTime: 0,
      saveTime: DateTime.now().millisecondsSinceEpoch,
      searchTitle: '星际穿越',
      doubanId: '1889243',
      rate: '9.4',
    ),
    VideoInfo(
      id: '36173648',
      source: 'douban',
      title: '周处除三害',
      sourceName: '豆瓣电影',
      year: '2024',
      cover: 'https://img1.doubanio.com/view/photo/s_ratio_poster/public/p2904888249.jpg',
      index: 1,
      totalEpisodes: 1,
      playTime: 0,
      totalTime: 0,
      saveTime: DateTime.now().millisecondsSinceEpoch,
      searchTitle: '周处除三害',
      doubanId: '36173648',
      rate: '8.1',
    ),
  ];

  late List<VideoInfo> _bannerItems;
  late final PageController _pageController;
  int _currentIndex = 0;
  Timer? _autoScrollTimer;
  bool _isUserInteracting = false;

  @override
  void initState() {
    super.initState();
    _currentInstance = this;
    _bannerItems = List.from(_defaultPresetItems);
    _pageController = PageController(initialPage: 0);

    // 启动自动轮播
    _startAutoScroll();

    // 延迟异步拉取实时豆瓣热门推荐更新数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBannerData();
    });
  }

  @override
  void dispose() {
    if (_currentInstance == this) {
      _currentInstance = null;
    }
    _stopAutoScroll();
    _pageController.dispose();
    super.dispose();
  }

  /// 启动自动轮播计时器（5秒）
  void _startAutoScroll() {
    _stopAutoScroll();
    if (_bannerItems.length <= 1) return;

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _isUserInteracting || !_pageController.hasClients) return;
      final nextPage = (_currentIndex + 1) % _bannerItems.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  /// 停止自动轮播
  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  /// 尝试从豆瓣拉取最新热门电影
  Future<void> _loadBannerData() async {
    if (!mounted) return;

    try {
      final moviesResult = await DoubanService.getHotMovies(context);
      if (!mounted) return;

      if (moviesResult.success && moviesResult.data != null && moviesResult.data!.isNotEmpty) {
        final List<VideoInfo> items = moviesResult.data!
            .take(6)
            .map((DoubanMovie movie) => movie.toVideoInfo())
            .toList();

        if (items.isNotEmpty && mounted) {
          setState(() {
            _bannerItems = items;
            _currentIndex = 0;
          });
          _startAutoScroll();
        }
      }
    } catch (_) {
      // 网络或接口异常时，保留兜底精选数据，UI保持稳定呈现
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 响应式高度：宽屏230dp，竖屏手机195dp
        final double height = constraints.maxWidth > 600 ? 230.0 : 195.0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: SizedBox(
            height: height,
            child: Listener(
              onPointerDown: (_) {
                _isUserInteracting = true;
                _stopAutoScroll();
              },
              onPointerUp: (_) {
                _isUserInteracting = false;
                _startAutoScroll();
              },
              onPointerCancel: (_) {
                _isUserInteracting = false;
                _startAutoScroll();
              },
              child: Stack(
                children: [
                  // PageView 轮播主体
                  PageView.builder(
                    controller: _pageController,
                    itemCount: _bannerItems.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return _buildBannerCard(
                        context,
                        _bannerItems[index],
                        height,
                      );
                    },
                  ),

                  // 底部指示器
                  Positioned(
                    bottom: 12,
                    right: 16,
                    child: _buildIndicators(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建单个轮播卡片
  Widget _buildBannerCard(
    BuildContext context,
    VideoInfo videoInfo,
    double height,
  ) {
    return GestureDetector(
      onTap: () => widget.onVideoTap?.call(videoInfo),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. 底层高斯模糊海报背景
              _buildBlurredBackground(videoInfo.cover, videoInfo.source),

              // 2. 暗色渐变蒙层
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(0.88),
                      Colors.black.withOpacity(0.65),
                      Colors.black.withOpacity(0.25),
                    ],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),

              // 3. 前景内容区
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 左侧信息与操作按钮
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 顶部标签徽章
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFE50914), Color(0xFFFF5252)],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFE50914).withOpacity(0.4),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.local_fire_department_rounded,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      '热映精选',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (videoInfo.rate != null && videoInfo.rate!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFFFB800).withOpacity(0.5),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 13,
                                        color: Color(0xFFFFB800),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        videoInfo.rate!,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFFFB800),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),

                          // 标题
                          Text(
                            videoInfo.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: height > 200 ? 18 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // 年份/信息
                          if (videoInfo.year.isNotEmpty)
                            Text(
                              '${videoInfo.year} · 豆瓣热推',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          const SizedBox(height: 12),

                          // 播放胶囊按钮
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF27AE60),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF27AE60).withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_arrow_rounded,
                                  size: 15,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '立即播放',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 右侧封面海报
                    _buildPosterImage(videoInfo.cover, videoInfo.source, height),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建底层高斯模糊海报背景
  Widget _buildBlurredBackground(String coverUrl, String source) {
    return FutureBuilder<String>(
      future: getImageUrl(coverUrl, source),
      builder: (context, snapshot) {
        final url = snapshot.data ?? coverUrl;
        final headers = getImageRequestHeaders(url, source);

        if (url.isEmpty) {
          return const ColoredBox(color: Color(0xFF1A1A1A));
        }

        return ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Transform.scale(
            scale: 1.15,
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              cacheKey: url,
              httpHeaders: headers,
              errorWidget: (_, __, ___) => const ColoredBox(color: Color(0xFF1A1A1A)),
            ),
          ),
        );
      },
    );
  }

  /// 构建右侧清晰竖版海报
  Widget _buildPosterImage(String coverUrl, String source, double containerHeight) {
    final posterHeight = containerHeight - 32;
    final posterWidth = posterHeight * (2 / 3);

    return Container(
      width: posterWidth,
      height: posterHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: FutureBuilder<String>(
          future: getImageUrl(coverUrl, source),
          builder: (context, snapshot) {
            final url = snapshot.data ?? coverUrl;
            final headers = getImageRequestHeaders(url, source);

            if (url.isEmpty) {
              return Container(
                color: const Color(0xFF2A2A2A),
                child: const Icon(Icons.movie_outlined, color: Colors.white30),
              );
            }

            return CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              cacheKey: url,
              httpHeaders: headers,
              placeholder: (context, url) => Container(
                color: const Color(0xFF2A2A2A),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF27AE60),
                    ),
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: const Color(0xFF2A2A2A),
                child: const Icon(Icons.movie_outlined, color: Colors.white30),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 构建分页指示器（小圆点 & 药丸）
  Widget _buildIndicators() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_bannerItems.length, (index) {
        final bool isSelected = index == _currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 5,
          width: isSelected ? 18 : 6,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF27AE60)
                : Colors.white.withOpacity(0.35),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
