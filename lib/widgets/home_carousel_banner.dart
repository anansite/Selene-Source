import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/video_info.dart';
import '../models/douban_movie.dart';
import '../services/theme_service.dart';
import '../services/douban_service.dart';
import '../utils/image_url.dart';

/// 沉浸式 Hero 首屏大轮播条目模型
class HeroBannerItem {
  final String id;
  final String title;
  final String? originalTitle;
  final String backdrop;
  final String cover;
  final String rate;
  final String year;
  final String genre;
  final String overview;
  final String tag;
  final String stype;

  const HeroBannerItem({
    required this.id,
    required this.title,
    this.originalTitle,
    required this.backdrop,
    required this.cover,
    required this.rate,
    required this.year,
    required this.genre,
    required this.overview,
    this.tag = '最新热映',
    this.stype = 'movie',
  });

  VideoInfo toVideoInfo() {
    return VideoInfo(
      id: id,
      source: 'banner',
      title: title,
      sourceName: '精选大片',
      year: year,
      cover: cover,
      index: 1,
      totalEpisodes: 1,
      playTime: 0,
      totalTime: 0,
      saveTime: DateTime.now().millisecondsSinceEpoch,
      searchTitle: title,
      rate: rate,
    );
  }
}

/// 首页首屏沉浸式 Hero 轮播大 Banner
class HomeCarouselBanner extends StatefulWidget {
  final Function(VideoInfo)? onVideoTap;

  const HomeCarouselBanner({
    super.key,
    this.onVideoTap,
  });

  @override
  State<HomeCarouselBanner> createState() => _HomeCarouselBannerState();

  /// 供外部主动触发刷新
  static Future<void> refreshBanner() async {
    await _HomeCarouselBannerState._currentInstance?._loadBannerData();
  }
}

class _HomeCarouselBannerState extends State<HomeCarouselBanner> {
  static _HomeCarouselBannerState? _currentInstance;

  /// 2024-2026 最新高热度、主流影视源 100% 具备超清播放源的精选大片池
  static final List<HeroBannerItem> _curatedItems = [
    const HeroBannerItem(
      id: '36828393',
      title: '野兽之心',
      originalTitle: 'Heart of the Beast',
      backdrop: 'https://img9.doubanio.com/view/photo/s_ratio_poster/public/p2933185536.jpg',
      cover: 'https://img9.doubanio.com/view/photo/s_ratio_poster/public/p2933185536.jpg',
      rate: '7.3',
      year: '2026',
      genre: '动作 / 惊悚 / 剧情 / 冒险',
      tag: '2026 最新热映',
      overview: '布拉德·皮特领衔主演。特种部队军官与军犬在惨烈空难后深陷荒野绝境，面对重重杀机展开殊死搏杀。',
    ),
    const HeroBannerItem(
      id: '36882191',
      title: '八仙！',
      originalTitle: 'All Wishes Come True',
      backdrop: 'https://img9.doubanio.com/view/photo/s_ratio_poster/public/p2934074566.jpg',
      cover: 'https://img9.doubanio.com/view/photo/s_ratio_poster/public/p2934074566.jpg',
      rate: '8.2',
      year: '2026',
      genre: '喜剧 / 动画 / 奇幻 / 冒险',
      tag: '2026 豆瓣爆款',
      overview: '八仙在成仙与搞事业之间玩转人间。面对泼天富贵与神妖阻挠，八个身份各异的凡人展开爆笑逆袭。',
    ),
    const HeroBannerItem(
      id: '35465232',
      title: '沙丘2',
      originalTitle: 'Dune: Part Two',
      backdrop: 'https://img1.doubanio.com/view/photo/s_ratio_poster/public/p2904354390.jpg',
      cover: 'https://img1.doubanio.com/view/photo/s_ratio_poster/public/p2904354390.jpg',
      rate: '8.3',
      year: '2024',
      genre: '科幻 / 冒险 / 动作',
      tag: 'IMAX 史诗巨制',
      overview: '保罗·厄崔迪携手契妮与弗雷曼人，踏上复仇与拯救厄拉科斯的壮丽史诗之旅，宇宙宿命在此决裂。',
    ),
    const HeroBannerItem(
      id: '36173648',
      title: '周处除三害',
      originalTitle: 'The Pig, the Snake and the Pigeon',
      backdrop: 'https://img1.doubanio.com/view/photo/s_ratio_poster/public/p2904888249.jpg',
      cover: 'https://img1.doubanio.com/view/photo/s_ratio_poster/public/p2904888249.jpg',
      rate: '8.1',
      year: '2024',
      genre: '动作 / 犯罪 / 剧情',
      tag: '高分动作爽片',
      overview: '通缉犯陈桂林得知自己身患绝症后，决心查出前两名通缉犯并除掉他们借此扬名，展开亡命追凶。',
    ),
    const HeroBannerItem(
      id: '35267208',
      title: '流浪地球2',
      originalTitle: 'The Wandering Earth II',
      backdrop: 'https://img1.doubanio.com/view/photo/s_ratio_poster/public/p2886492513.jpg',
      cover: 'https://img1.doubanio.com/view/photo/s_ratio_poster/public/p2886492513.jpg',
      rate: '8.3',
      year: '2023',
      genre: '科幻 / 动作 / 灾难',
      tag: '硬核科幻里程碑',
      overview: '太阳急速老化面临毁灭，人类启动万座行星发动机奔向新家园。在数字生命危机与太空电梯浩劫面前，全人类挺身决战。',
    ),
    const HeroBannerItem(
      id: '37317907',
      title: '另一个妈妈',
      originalTitle: 'Other Mommy',
      backdrop: 'https://img9.doubanio.com/view/photo/s_ratio_poster/public/p2935858295.jpg',
      cover: 'https://img9.doubanio.com/view/photo/s_ratio_poster/public/p2935858295.jpg',
      rate: '6.5',
      year: '2026',
      genre: '悬疑 / 惊悚 / 剧情',
      tag: '2026 热播悬疑',
      overview: '杰西卡·查斯坦领衔主演。一位母亲在平静生活中觉察出异样伪装，深藏在家庭背后的黑暗秘密步步逼近。',
    ),
  ];

  late List<HeroBannerItem> _items;
  late final PageController _pageController;
  int _currentIndex = 0;
  Timer? _autoScrollTimer;
  bool _isUserInteracting = false;

  @override
  void initState() {
    super.initState();
    _currentInstance = this;
    _items = List.from(_curatedItems);
    _pageController = PageController(initialPage: 0);

    // 启动自动轮播
    _startAutoScroll();

    // 延迟异步拉取实时豆瓣最新热门电影更新
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

  void _startAutoScroll() {
    _stopAutoScroll();
    if (_items.length <= 1) return;

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || _isUserInteracting || !_pageController.hasClients) return;
      final nextPage = (_currentIndex + 1) % _items.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  /// 异步从豆瓣拉取最新热门榜单并融合展示
  Future<void> _loadBannerData() async {
    if (!mounted) return;

    try {
      final moviesResult = await DoubanService.getHotMovies(context);
      if (!mounted) return;

      if (moviesResult.success &&
          moviesResult.data != null &&
          moviesResult.data!.isNotEmpty) {
        final List<HeroBannerItem> dynamicItems = [];
        for (final DoubanMovie movie in moviesResult.data!.take(6)) {
          // 在精选库中匹配是否有预制故事看点
          final matchedCurated = _curatedItems.firstWhere(
            (c) => c.title == movie.title || c.id == movie.id,
            orElse: () => HeroBannerItem(
              id: movie.id,
              title: movie.title,
              backdrop: movie.poster,
              cover: movie.poster,
              rate: movie.rate?.isNotEmpty == true ? movie.rate! : '7.8',
              year: movie.year.isNotEmpty ? movie.year : '2026',
              genre: '最新热映 · 热门电影',
              overview: '近期高热度院线大片，口碑与热度持续攀升，聚合全网高清影视源在线极速播放。',
              tag: '最新热映',
            ),
          );

          dynamicItems.add(
            HeroBannerItem(
              id: movie.id,
              title: movie.title,
              originalTitle: matchedCurated.originalTitle,
              backdrop: movie.poster.isNotEmpty
                  ? movie.poster
                  : matchedCurated.backdrop,
              cover: movie.poster.isNotEmpty
                  ? movie.poster
                  : matchedCurated.cover,
              rate: movie.rate?.isNotEmpty == true
                  ? movie.rate!
                  : matchedCurated.rate,
              year: movie.year.isNotEmpty ? movie.year : matchedCurated.year,
              genre: matchedCurated.genre,
              overview: matchedCurated.overview,
              tag: '最新热映',
            ),
          );
        }

        if (dynamicItems.isNotEmpty && mounted) {
          setState(() {
            _items = dynamicItems;
            _currentIndex = 0;
          });
          _startAutoScroll();
          return;
        }
      }
    } catch (_) {
      // 网络请求失败时使用内置最新精选
    }

    if (mounted) {
      setState(() {
        _items = List.from(_curatedItems);
        _currentIndex = 0;
      });
      _startAutoScroll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    // 沉浸式巨幕高度：约占屏幕高度 56%~60%，给海报大片提供更加开阔大气的视觉展示空间
    final double bannerHeight = (screenHeight * 0.58).clamp(460.0, 580.0);

    return SizedBox(
      width: double.infinity,
      height: bannerHeight,
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
          fit: StackFit.expand,
          children: [
            // 1. PageView 全屏宽剧照轮播
            PageView.builder(
              controller: _pageController,
              itemCount: _items.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return _buildBackdropSlide(
                    context, _items[index], bannerHeight, themeService);
              },
            ),

            // 2. 顶部微暗渐变：保护顶部状态栏与悬浮在其上方的 Tab 导航按钮
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 120,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.70),
                        Colors.black.withOpacity(0.30),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 3. 底部长距离好莱坞级超平滑渐变：海报自然融入下层页面底色
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 230,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.35, 0.68, 1.0],
                      colors: [
                        Colors.transparent,
                        themeService.isDarkMode
                            ? const Color(0xFF121212).withOpacity(0.50)
                            : const Color(0xFFF6F8FA).withOpacity(0.70),
                        themeService.isDarkMode
                            ? const Color(0xFF121212).withOpacity(0.92)
                            : const Color(0xFFF6F8FA).withOpacity(0.96),
                        themeService.isDarkMode
                            ? const Color(0xFF121212)
                            : const Color(0xFFF6F8FA),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 4. 前景影视大片信息排版（左下对齐，无多余播放按钮，全画幅可点）
            Positioned(
              left: 20,
              right: 20,
              bottom: 16,
              child: _buildMovieMetaInfo(_items[_currentIndex], themeService),
            ),
          ],
        ),
      ),
    );
  }

  /// 单个全屏宽海报 Slide：全画幅高清海报无缝通顶铺展，左右完整清晰无虚化
  Widget _buildBackdropSlide(
    BuildContext context,
    HeroBannerItem item,
    double height,
    ThemeService themeService,
  ) {
    final headers = getImageRequestHeaders(item.backdrop, 'douban');
    final String imageUrl =
        item.backdrop.isNotEmpty ? item.backdrop : item.cover;

    return GestureDetector(
      onTap: () => widget.onVideoTap?.call(item.toVideoInfo()),
      behavior: HitTestBehavior.opaque,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        httpHeaders: headers,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        placeholder: (context, url) => Container(
          color: themeService.isDarkMode
              ? const Color(0xFF1B1B1F)
              : const Color(0xFFE2E8F0),
        ),
        errorWidget: (context, url, error) => Container(
          color: themeService.isDarkMode
              ? const Color(0xFF1B1B1F)
              : const Color(0xFFE2E8F0),
        ),
      ),
    );
  }

  /// 构建左下方电影元数据、徽标与剧情概述（支持亮/暗主题自适应超清高对比度）
  Widget _buildMovieMetaInfo(HeroBannerItem item, ThemeService themeService) {
    final bool isDark = themeService.isDarkMode;

    // 标题颜色：深色模式纯白；浅色模式深炭黑（对比度高，绝不发灰）
    final Color titleColor = isDark ? Colors.white : const Color(0xFF0F172A);

    // 看点描述颜色：深色模式明亮白（85%透明度）；浅色模式深灰炭（对比度强）
    final Color overviewColor =
        isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF334155);

    // 年份/分类元数据颜色
    final Color metaColor =
        isDark ? Colors.white.withOpacity(0.80) : const Color(0xFF64748B);

    // 评分颜色：浅色模式采用加深琥珀金（0xFFD97706），在浅色底上清晰且温润
    final Color rateColor =
        isDark ? const Color(0xFFFFB800) : const Color(0xFFD97706);

    // 文字阴影：深色模式为黑影防透底；浅色模式为微白光晕提高字符分离度
    final List<Shadow> titleShadow = isDark
        ? const [
            Shadow(color: Colors.black87, offset: Offset(0, 2), blurRadius: 10)
          ]
        : const [
            Shadow(color: Colors.white, offset: Offset(0, 1), blurRadius: 6)
          ];

    final List<Shadow> overviewShadow = isDark
        ? const [
            Shadow(color: Colors.black87, offset: Offset(0, 1), blurRadius: 6)
          ]
        : const [
            Shadow(color: Colors.white, offset: Offset(0, 1), blurRadius: 4)
          ];

    final List<Shadow> metaShadow = isDark
        ? const [
            Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1))
          ]
        : const [
            Shadow(color: Colors.white, blurRadius: 4, offset: Offset(0, 1))
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 顶部元数据行：标签 + 评分 + 年份/分类 + 纤细指示器
        Row(
          children: [
            // 4K超清/最新热映徽标
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE50914), Color(0xFFFF5252)],
                ),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE50914).withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                item.tag,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // 金星评分
            Row(
              children: [
                Icon(Icons.star_rounded, size: 16, color: rateColor),
                const SizedBox(width: 2),
                Text(
                  item.rate,
                  style: TextStyle(
                    color: rateColor,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),

            // 年份与分类说明
            Expanded(
              child: Text(
                '${item.year} · ${item.genre}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: metaColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  shadows: metaShadow,
                ),
              ),
            ),

            // 右侧纤细滑动指示条
            _buildSlimPageIndicator(themeService),
          ],
        ),
        const SizedBox(height: 8),

        // 大片震撼主标题
        Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: titleColor,
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            shadows: titleShadow,
          ),
        ),

        if (item.overview.isNotEmpty) ...[
          const SizedBox(height: 6),
          // 2行精炼电影剧情看点概述
          Text(
            item.overview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: overviewColor,
              fontSize: 12.5,
              height: 1.38,
              letterSpacing: 0.2,
              fontWeight: isDark ? FontWeight.w400 : FontWeight.w500,
              shadows: overviewShadow,
            ),
          ),
        ],
      ],
    );
  }

  /// 极简纤细胶囊线指示器（Active: 20x4 圆角短条；Inactive: 6x4 微点，自适应主题）
  Widget _buildSlimPageIndicator(ThemeService themeService) {
    final bool isDark = themeService.isDarkMode;
    final Color activeColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color inactiveColor =
        isDark ? Colors.white.withOpacity(0.35) : const Color(0xFFCBD5E1);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_items.length, (index) {
        final bool isActive = index == _currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          width: isActive ? 20.0 : 6.0,
          height: 4.0,
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(2.0),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: activeColor.withOpacity(0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}
