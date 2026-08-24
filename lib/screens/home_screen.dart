import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/football_field.dart';
import '../services/api_config.dart';
import '../services/football_field_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/field_search_bar.dart';
import 'football_field_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.onOpenFavorites,
  });

  final AppController controller;
  final VoidCallback onOpenFavorites;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const _pageSize = 20;

  late final FootballFieldService _footballFieldService;
  late final ScrollController _scrollController;
  late final TextEditingController _searchController;
  late final PageController _bannerController;
  late final AnimationController _ballController;

  final List<FootballField> _fields = [];
  final Set<String> _favoriteRequests = {};
  Timer? _searchDebounce;
  Timer? _bannerTimer;
  String? _loadError;
  int _pageNumber = 0;
  int _totalCount = 0;
  int _bannerIndex = 0;
  int _requestGeneration = 0;
  bool _hasNextPage = false;
  bool _loadingFirstPage = true;
  bool _loadingNextPage = false;

  @override
  void initState() {
    super.initState();
    _footballFieldService = FootballFieldService(widget.controller.apiClient);
    _scrollController = ScrollController()..addListener(_onScroll);
    _searchController = TextEditingController();
    _bannerController = PageController();
    _ballController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_bannerController.hasClients) return;
      final nextPage = (_bannerIndex + 1) % 3;
      _bannerController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
    });
    _loadFirstPage();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _bannerTimer?.cancel();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    _bannerController.dispose();
    _ballController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || !_hasNextPage) return;
    if (_scrollController.position.extentAfter < 500) _loadNextPage();
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), _loadFirstPage);
  }

  Future<void> _loadFirstPage() async {
    final generation = ++_requestGeneration;
    if (mounted) {
      setState(() {
        _loadingFirstPage = true;
        _loadingNextPage = false;
        _loadError = null;
      });
    }

    try {
      final result = await _footballFieldService.getList(
        search: _searchController.text,
        pageNumber: 1,
        pageSize: _pageSize,
      );
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _fields
          ..clear()
          ..addAll(result.items);
        _pageNumber = result.pageNumber;
        _totalCount = result.totalCount;
        _hasNextPage = result.hasNextPage;
        _loadingFirstPage = false;
      });
    } catch (_) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _fields.clear();
        _pageNumber = 0;
        _totalCount = 0;
        _hasNextPage = false;
        _loadingFirstPage = false;
        _loadError = widget.controller.strings.t('fieldsLoadError');
      });
    }
  }

  Future<void> _loadNextPage() async {
    if (_loadingFirstPage || _loadingNextPage || !_hasNextPage) return;
    final generation = _requestGeneration;
    setState(() => _loadingNextPage = true);

    try {
      final result = await _footballFieldService.getList(
        search: _searchController.text,
        pageNumber: _pageNumber + 1,
        pageSize: _pageSize,
      );
      if (!mounted || generation != _requestGeneration) return;
      final knownIds = _fields.map((field) => field.id).toSet();
      setState(() {
        _fields.addAll(result.items.where((field) => knownIds.add(field.id)));
        _pageNumber = result.pageNumber;
        _totalCount = result.totalCount;
        _hasNextPage = result.hasNextPage;
        _loadingNextPage = false;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _loadingNextPage = false;
        _loadError = widget.controller.strings.t('fieldsMoreLoadError');
      });
    }
  }

  void _clearSearch() {
    if (_searchController.text.isEmpty) return;
    _searchController.clear();
    FocusScope.of(context).unfocus();
    _loadFirstPage();
  }

  Future<void> _toggleFavorite(FootballField field) async {
    if (_favoriteRequests.contains(field.id)) return;
    final index = _fields.indexWhere((item) => item.id == field.id);
    if (index < 0) return;

    final wasFavorite = _fields[index].isFavorite;
    setState(() {
      _favoriteRequests.add(field.id);
      _fields[index] = _fields[index].copyWith(isFavorite: !wasFavorite);
    });

    try {
      if (wasFavorite) {
        await _footballFieldService.removeFromFavorites(field.id);
      } else {
        await _footballFieldService.addToFavorites(field.id);
      }
    } catch (_) {
      if (!mounted) return;
      final currentIndex = _fields.indexWhere((item) => item.id == field.id);
      if (currentIndex >= 0) {
        setState(() {
          _fields[currentIndex] = _fields[currentIndex].copyWith(
            isFavorite: wasFavorite,
          );
        });
      }
      AppToast.error(
        context,
        widget.controller.strings.t('favoriteUpdateError'),
      );
    } finally {
      if (mounted) setState(() => _favoriteRequests.remove(field.id));
    }
  }

  void _openDetails(FootballField field) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FootballFieldDetailsScreen(
          controller: widget.controller,
          footballFieldId: field.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.controller.strings;

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadFirstPage,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TopBar(
                      title: s.t('navHome'),
                      favoritesLabel: s.t('favorites'),
                      onFavoritesPressed: widget.onOpenFavorites,
                    ),
                    const SizedBox(height: 18),
                    _ArenaBanner(
                      controller: _bannerController,
                      animation: _ballController,
                      activeIndex: _bannerIndex,
                      name: widget.controller.session?.firstName ?? '',
                      titles: [
                        s.t('bannerTitleOne'),
                        s.t('bannerTitleTwo'),
                        s.t('bannerTitleThree'),
                      ],
                      descriptions: [
                        s.t('bannerTextOne'),
                        s.t('bannerTextTwo'),
                        s.t('bannerTextThree'),
                      ],
                      onPageChanged: (index) {
                        if (mounted) setState(() => _bannerIndex = index);
                      },
                    ),
                    const SizedBox(height: 22),
                    FieldSearchBar(
                      controller: _searchController,
                      hintText: s.t('searchFields'),
                      clearTooltip: s.t('clearSearch'),
                      onChanged: _onSearchChanged,
                      onClear: _clearSearch,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.t('footballFields'),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.4,
                            ),
                          ),
                        ),
                        if (!_loadingFirstPage && _loadError == null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: .11),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$_totalCount',
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (_loadingFirstPage)
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 126),
                sliver: SliverToBoxAdapter(child: _FieldsLoading()),
              )
            else if (_fields.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 126),
                sliver: SliverToBoxAdapter(
                  child: _EmptyOrError(
                    isError: _loadError != null,
                    title: _loadError ?? s.t('fieldsEmpty'),
                    text: _loadError != null
                        ? s.t('tryAgainText')
                        : s.t('fieldsEmptyText'),
                    retryLabel: s.t('tryAgain'),
                    onRetry: _loadFirstPage,
                  ),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: _fields.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) => FootballFieldCard(
                    field: _fields[index],
                    language: widget.controller.language,
                    favoriteBusy: _favoriteRequests.contains(_fields[index].id),
                    onFavoritePressed: () => _toggleFavorite(_fields[index]),
                    onPressed: () => _openDetails(_fields[index]),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 126),
                  child: _ListFooter(
                    loading: _loadingNextPage,
                    error: _loadError,
                    hasNextPage: _hasNextPage,
                    finishedText: s.t('allFieldsLoaded'),
                    retryLabel: s.t('tryAgain'),
                    onRetry: _loadNextPage,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.favoritesLabel,
    required this.onFavoritesPressed,
  });

  final String title;
  final String favoritesLabel;
  final VoidCallback onFavoritesPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w800,
              letterSpacing: -.8,
            ),
          ),
        ),
        Material(
          color: Theme.of(context).colorScheme.surface,
          shape: const CircleBorder(),
          child: IconButton(
            onPressed: onFavoritesPressed,
            tooltip: favoritesLabel,
            icon: const Icon(Icons.bookmark_border_rounded),
          ),
        ),
      ],
    );
  }
}

class _ArenaBanner extends StatelessWidget {
  const _ArenaBanner({
    required this.controller,
    required this.animation,
    required this.activeIndex,
    required this.name,
    required this.titles,
    required this.descriptions,
    required this.onPageChanged,
  });

  final PageController controller;
  final Animation<double> animation;
  final int activeIndex;
  final String name;
  final List<String> titles;
  final List<String> descriptions;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 184,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF06432C), Color(0xFF16885B), Color(0xFF22A96F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3322A96F),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -54,
            top: -68,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: .08),
                  width: 30,
                ),
              ),
            ),
          ),
          Positioned(
            right: 17,
            bottom: 24,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final value = animation.value;
                return Transform.translate(
                  offset: Offset(0, math.sin(value * math.pi * 2) * 6),
                  child: Transform.rotate(
                    angle: value * math.pi * 2,
                    child: child,
                  ),
                );
              },
              child: Icon(
                Icons.sports_soccer_rounded,
                color: Colors.white.withValues(alpha: .9),
                size: 68,
              ),
            ),
          ),
          Positioned.fill(
            right: 78,
            child: PageView.builder(
              controller: controller,
              itemCount: titles.length,
              onPageChanged: onPageChanged,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 8, 34),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (index == 0 && name.trim().isNotEmpty) ...[
                      Text(
                        name.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .7),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                    ],
                    Text(
                      titles[index],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      descriptions[index],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .72),
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 22,
            bottom: 16,
            child: Row(
              children: List.generate(3, (index) {
                final active = index == activeIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: active ? 20 : 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: active ? .95 : .35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class FootballFieldCard extends StatelessWidget {
  const FootballFieldCard({
    super.key,
    required this.field,
    required this.language,
    required this.favoriteBusy,
    required this.onFavoritePressed,
    required this.onPressed,
  });

  final FootballField field;
  final String language;
  final bool favoriteBusy;
  final VoidCallback onFavoritePressed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final name = field.name.value(language);
    final address = field.address.value(language);
    final description = field.description.value(language);
    final imageUrl = resolveApiUrl(field.image?.url ?? '');
    final currency = field.currency.toUpperCase() == 'UZS'
        ? (language == 'ru' ? 'сум' : 'so‘m')
        : field.currency;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: dark ? .45 : .55),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? .18 : .055),
              blurRadius: 22,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 145,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _FieldImage(url: imageUrl),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Color(0x88000000)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [.55, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: GestureDetector(
                      onTap: favoriteBusy ? null : onFavoritePressed,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: field.isFavorite
                              ? AppColors.primary
                              : Colors.black.withValues(alpha: .28),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: field.isFavorite
                                ? Colors.white.withValues(alpha: .55)
                                : Colors.white.withValues(alpha: .24),
                          ),
                        ),
                        child: Icon(
                          field.isFavorite
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 15,
                    right: 15,
                    bottom: 13,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          color: Colors.white,
                          size: 17,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_shortTime(field.opensAt)} – ${_shortTime(field.closesAt)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? '—' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          address.isEmpty ? '—' : address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 11),
                  Divider(height: 1, color: scheme.outlineVariant),
                  const SizedBox(height: 11),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              language == 'ru' ? 'Цена за час' : 'Soatlik narx',
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text.rich(
                              TextSpan(
                                text: _formatNumber(field.hourlyPrice),
                                children: [
                                  TextSpan(
                                    text: ' $currency',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          language == 'ru'
                              ? 'Предоплата ${_formatNumber(field.prepaymentAmount)} $currency'
                              : 'Oldindan ${_formatNumber(field.prepaymentAmount)} $currency',
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldImage extends StatelessWidget {
  const _FieldImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const _ImagePlaceholder();
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _ImagePlaceholder(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const _ImagePlaceholder(loading: true);
      },
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1D3027)
          : const Color(0xFFDDECE4),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 25,
                height: 25,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              )
            : Icon(
                Icons.stadium_outlined,
                size: 48,
                color: AppColors.primary.withValues(alpha: .65),
              ),
      ),
    );
  }
}

class _FieldsLoading extends StatelessWidget {
  const _FieldsLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          height: 260,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      ),
    );
  }
}

class _EmptyOrError extends StatelessWidget {
  const _EmptyOrError({
    required this.isError,
    required this.title,
    required this.text,
    required this.retryLabel,
    required this.onRetry,
  });

  final bool isError;
  final String title;
  final String text;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(
            isError ? Icons.cloud_off_rounded : Icons.search_off_rounded,
            color: AppColors.primary,
            size: 42,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          if (isError) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(retryLabel),
            ),
          ],
        ],
      ),
    );
  }
}

class _ListFooter extends StatelessWidget {
  const _ListFooter({
    required this.loading,
    required this.error,
    required this.hasNextPage,
    required this.finishedText,
    required this.retryLabel,
    required this.onRetry,
  });

  final bool loading;
  final String? error;
  final bool hasNextPage;
  final String finishedText;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
      );
    }
    if (error != null && hasNextPage) {
      return Center(
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(retryLabel),
        ),
      );
    }
    if (!hasNextPage) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 17),
          const SizedBox(width: 7),
          Text(
            finishedText,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

String _shortTime(String value) {
  final parts = value.split(':');
  return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : value;
}

String _formatNumber(double value) {
  final source = value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
  return source.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ');
}
