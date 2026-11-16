import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/video_info.dart';
import '../services/theme_service.dart';

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
    this.tag = '4K超清',
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

  /// 精选且主流视频源 100% 存在高码率可播放资源的头部大片池（带16:9横版剧照及剧情看点）
  static final List<HeroBannerItem> _curatedItems = [
    const HeroBannerItem(
      id: '1889243',
      title: '星际穿越',
      originalTitle: 'Interstellar',
      backdrop: 'https://images.weserv.nl/?url=image.tmdb.org/t/p/w1280/xJHokMbljvjADYdit5fK5VQsXEG.jpg',
      cover: 'https://images.weserv.nl/?url=image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg',
      rate: '9.4',
      year: '2014',
      genre: '科幻 / 冒险 / 悬疑',
      tag: '豆瓣 TOP250 · 必看神作',
      overview: '地球生态彻底竭绝，前宇航员库珀穿过土星附近的神秘虫洞，在未知维度与浩瀚星海中寻找人类延续的最后希望。',
    ),
    const HeroBannerItem(
      id: '35588327',
      title: '奥本海默',
      originalTitle: 'Oppenheimer',
      backdrop: 'https://images.weserv.nl/?url=image.tmdb.org/t/p/w1280/nb3xI8XI3w4pMVZ38VijbsyBqP4.jpg',
      cover: 'https://images.weserv.nl/?url=image.tmdb.org/t/p/w500/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg',
      rate: '8.8',
      year: '2023',
      genre: '传记 / 剧情 / 历史',
      tag: '奥斯卡最佳影片',
      overview: '聚焦“原子弹之父”罗伯特·奥本海默研制人类首枚核武器的波澜历程，以及随之而来的道德困境与政治风暴。',
    ),
    const HeroBannerItem(
      id: '35267208',
      title: '流浪地球2',
      originalTitle: 'The Wandering Earth II',
      backdrop: 'https://images.weserv.nl/?url=image.tmdb.org/t/p/w1280/p2LNc1DEq9q7w2gA954L69m40rZ.jpg',
      cover: 'https://images.weserv.nl/?url=image.tmdb.org/t/p/w500/A3vSgnjN7tK4m7h0LgSj5jG0P9w.jpg',
      rate: '8.3',
      year: '2023',
      genre: '科幻 / 动作 / 灾难',
      tag: '硬核科幻里程碑',
      overview: '太阳急速老化面临毁灭，人类启动万座行星发动机奔向新家园。在数字生命危机与太空电梯浩劫面前，全人类挺身决战。',
    ),
    const HeroBannerItem(
      id: '35465232',
      title: '沙丘2',
      originalTitle: 'Dune: Part Two',
      backdrop: 'https://images.weserv.nl/?url=image.tmdb.org/t/p/w1280/xOMo8BRK7PfcJv9JCnx7s5207ne.jpg',
      cover: 'https://images.weserv.nl/?url=image.tmdb.org/t/p/w500/czembW0Rk1Ke7lCJGzyejdtHdG.jpg',
      rate: '8.3',
      year: '2024',
      genre: '科幻 / 动作 / 冒险',
      tag: 'IMAX 史诗巨制',
      overview: '保罗·厄崔迪携手契妮与弗雷曼人，踏上复仇与拯救厄拉科斯的壮丽史诗之旅，宇宙宿命在此决裂。',
    ),
    const HeroBannerItem(
      id: '1292052',
      title: '肖申克的救赎',
      originalTitle: 'The Shawshank Redemption',
      backdrop: 'https://images.weserv.nl/?url=image.tmdb.org/t/p/w1280/kXfqcdQKsToO0OUXHcrrNCHDBzO.jpg',
      cover: 'https://images.weserv.nl/?url=image.tmdb.org/t/p/w500/9cqNxx0GxF0bflZmeSMuL5tnGzr.jpg',
      rate: '9.7',
      year: '1994',
      genre: '剧情 / 犯罪 / 经典',
      tag: '影史无可超越桂冠',
      overview: '银行家安迪蒙冤入狱二十载，在残酷黑暗的高墙之内，他凭借无与伦比的坚韧与信念凿穿自由之路。',
    ),
    const HeroBannerItem(
      id: '36173648',
      title: '周处除三害',
      originalTitle: 'The Pig, the Snake and the Pigeon',
      backdrop: 'https://images.weserv.nl/?url=image.tmdb.org/t/p/w1280/14QbnygCuTO0vl7CAFmPf1fgZfV.jpg',
      cover: 'https://images.weserv.nl/?url=image.tmdb.org/t/p/w500/mCDyV28l9f1aY8eA0l3jBq9Z6P3.jpg',
      rate: '8.1',
      year: '2024',
      genre: '动作 / 犯罪 / 剧情',
      tag: '高分爽片必看',
      overview: '通缉犯陈桂林得知自己身患绝症后，决心查出前两名通缉犯并除掉他们，借此名留青史，展开亡命追凶。',
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

  Future<void> _loadBannerData() async {
    // 保持高可用大片池作为核心稳定基线
    if (!mounted) return;
    setState(() {
      _items = List.from(_curatedItems);
      _currentIndex = 0;
    });
    _startAutoScroll();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    // 沉浸式高度：约占屏幕高度 44%~48%，保证气势与大片氛围
    final double bannerHeight = (screenHeight * 0.45).clamp(320.0, 420.0);

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
                return _buildBackdropSlide(context, _items[index], bannerHeight, themeService);
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
              height: 220,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.45, 0.8, 1.0],
                      colors: [
                        Colors.transparent,
                        themeService.isDarkMode
                            ? const Color(0xFF121212).withOpacity(0.5)
                            : const Color(0xFFF6F8FA).withOpacity(0.6),
                        themeService.isDarkMode
                            ? const Color(0xFF121212).withOpacity(0.9)
                            : const Color(0xFFF6F8FA).withOpacity(0.95),
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
              child: _buildMovieMetaInfo(_items[_currentIndex]),
            ),
          ],
        ),
      ),
    );
  }

  /// 单个全屏宽剧照 Slide
  Widget _buildBackdropSlide(
    BuildContext context,
    HeroBannerItem item,
    double height,
    ThemeService themeService,
  ) {
    return GestureDetector(
      onTap: () => widget.onVideoTap?.call(item.toVideoInfo()),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 高清横版剧照大图
          CachedNetworkImage(
            imageUrl: item.backdrop,
            fit: BoxFit.cover,
            width: double.infinity,
            height: height,
            placeholder: (context, url) => Container(
              color: const Color(0xFF1B1B1F),
              child: const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white38),
                  ),
                ),
              ),
            ),
            errorWidget: (context, url, error) {
              // 备用兜底：渐变底板 + 标题
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2C3E50), Color(0xFF000000)],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.movie_creation_outlined,
                    size: 54,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 构建左下方电影元数据、徽标与剧情概述
  Widget _buildMovieMetaInfo(HeroBannerItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 顶部元数据行：标签 + 评分 + 年份/分类 + 纤细指示器
        Row(
          children: [
            // 4K超清/精选徽标
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
                const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFB800)),
                const SizedBox(width: 2),
                Text(
                  item.rate,
                  style: const TextStyle(
                    color: Color(0xFFFFB800),
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
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  shadows: const [
                    Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                  ],
                ),
              ),
            ),

            // 右侧纤细滑动指示条
            _buildSlimPageIndicator(),
          ],
        ),
        const SizedBox(height: 8),

        // 大片震撼主标题
        Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            shadows: [
              Shadow(
                color: Colors.black87,
                offset: Offset(0, 2),
                blurRadius: 10,
              ),
            ],
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
              color: Colors.white.withOpacity(0.82),
              fontSize: 12.5,
              height: 1.38,
              letterSpacing: 0.2,
              shadows: const [
                Shadow(
                  color: Colors.black87,
                  offset: Offset(0, 1),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// 极简纤细胶囊线指示器（Active: 20x4 白色圆角短条；Inactive: 6x4 微白点）
  Widget _buildSlimPageIndicator() {
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
            color: isActive ? Colors.white : Colors.white.withOpacity(0.35),
            borderRadius: BorderRadius.circular(2.0),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
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
