import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons_flutter.dart';
import '../models/douban_movie.dart';
import '../models/video_info.dart';
import '../services/douban_service.dart';
import '../utils/image_url.dart';
import '../utils/font_utils.dart';
import 'shimmer_effect.dart';

/// 首页首屏轮播 Banner 组件
class HomeCarouselBanner extends StatefulWidget {
  final Function(VideoInfo)? onVideoTap;

  const HomeCarouselBanner({
    super.key,
    this.onVideoTap,
  });

  @override
  State<HomeCarouselBanner> createState() => _HomeCarouselBannerState();

  /// 静态方法：供外部（如首页下拉刷新）主动触发刷新
  static Future<void> refreshBanner() async {
    await _HomeCarouselBannerState._currentInstance?._loadBannerData();
  }
}

class _HomeCarouselBannerState extends State<HomeCarouselBanner> {
  static _HomeCarouselBannerState? _currentInstance;

  List<VideoInfo> _bannerItems = [];
  bool _isLoading = true;
  bool _hasError = false;

  late final PageController _pageController;
  int _currentIndex = 0;
  Timer? _autoScrollTimer;
  bool _isUserInteracting = false;

  @override
  void initState() {
    super.initState();
    _currentInstance = this;
    _pageController = PageController(initialPage: 0);
    _loadBannerData();
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

  /// 加载轮播数据（提取豆瓣热门精选推荐）
  Future<void> _loadBannerData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final moviesResult = await DoubanService.getHotMovies(context);
      if (!mounted) return;

      final List<VideoInfo> items = [];
      if (moviesResult.success && moviesResult.data != null && moviesResult.data!.isNotEmpty) {
        // 取前 6 部热门电影作为首屏推荐
        items.addAll(
          moviesResult.data!
              .take(6)
              .map((DoubanMovie movie) => movie.toVideoInfo()),
        );
      }

      if (mounted) {
        setState(() {
          _bannerItems = items;
          _isLoading = false;
          _hasError = items.isEmpty;
        });

        if (items.isNotEmpty) {
          _startAutoScroll();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildSkeleton(context);
    }

    if (_hasError || _bannerItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 响应式高度：移动端约 190~210dp，桌面或平板端按比例最高 240dp
        final double height = constraints.maxWidth > 600 ? 240.0 : 190.0;

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

  /// 构建骨架屏占位
  Widget _buildSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: AspectRatio(
        aspectRatio: 16 / 8,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: const ShimmerEffect(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFF1E1E1E),
              ),
            ),
          ),
        ),
      ),
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

              // 2. 暗色渐变蒙层，保证文字前景清晰立体
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

              // 3. 前景内容区：左侧文本与播放按钮，右侧清晰海报
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
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      LucideIcons.flame,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '热映精选',
                                      style: FontUtils.poppins(
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
                                        style: FontUtils.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFFFFB800),
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
                            style: FontUtils.poppins(
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
                              style: FontUtils.poppins(
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.play,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '立即播放',
                                  style: FontUtils.poppins(
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
                child: const Icon(LucideIcons.film, color: Colors.white30),
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
                child: const Icon(LucideIcons.film, color: Colors.white30),
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
