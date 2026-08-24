import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/football_field.dart';
import '../services/football_field_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/field_search_bar.dart';
import 'home_screen.dart';

class FavoriteFieldsScreen extends StatefulWidget {
  const FavoriteFieldsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<FavoriteFieldsScreen> createState() => _FavoriteFieldsScreenState();
}

class _FavoriteFieldsScreenState extends State<FavoriteFieldsScreen> {
  static const _pageSize = 20;

  late final FootballFieldService _footballFieldService;
  late final ScrollController _scrollController;
  late final TextEditingController _searchController;

  final List<FootballField> _fields = [];
  final Set<String> _removeRequests = {};
  Timer? _searchDebounce;
  String? _loadError;
  int _pageNumber = 0;
  int _totalCount = 0;
  int _requestGeneration = 0;
  bool _hasNextPage = false;
  bool _loadingFirstPage = true;
  bool _loadingNextPage = false;

  @override
  void initState() {
    super.initState();
    _footballFieldService = FootballFieldService(widget.controller.apiClient);
    widget.controller.addListener(_onControllerChanged);
    _scrollController = ScrollController()..addListener(_onScroll);
    _searchController = TextEditingController();
    _loadFirstPage();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted || widget.controller.stage == AppStage.home) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _onScroll() {
    if (!_scrollController.hasClients || !_hasNextPage) return;
    if (_scrollController.position.extentAfter < 500) _loadNextPage();
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), _loadFirstPage);
  }

  void _clearSearch() {
    if (_searchController.text.isEmpty) return;
    _searchController.clear();
    FocusScope.of(context).unfocus();
    _loadFirstPage();
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
      final result = await _footballFieldService.getFavorites(
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
        _loadError = widget.controller.strings.t('favoritesLoadError');
      });
    }
  }

  Future<void> _loadNextPage() async {
    if (_loadingFirstPage || _loadingNextPage || !_hasNextPage) return;
    final generation = _requestGeneration;
    setState(() => _loadingNextPage = true);

    try {
      final result = await _footballFieldService.getFavorites(
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

  Future<void> _removeFavorite(FootballField field) async {
    if (_removeRequests.contains(field.id)) return;
    final index = _fields.indexWhere((item) => item.id == field.id);
    if (index < 0) return;
    final generation = _requestGeneration;

    setState(() {
      _removeRequests.add(field.id);
      _fields.removeAt(index);
      if (_totalCount > 0) _totalCount--;
    });

    try {
      await _footballFieldService.removeFromFavorites(field.id);
    } catch (_) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        final restoreIndex = index.clamp(0, _fields.length);
        _fields.insert(restoreIndex, field.copyWith(isFavorite: true));
        _totalCount++;
      });
      AppToast.error(
        context,
        widget.controller.strings.t('favoriteUpdateError'),
      );
    } finally {
      if (mounted) setState(() => _removeRequests.remove(field.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.controller.strings;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
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
                      Row(
                        children: [
                          IconButton(
                            tooltip: s.t('back'),
                            onPressed: () => Navigator.of(context).pop(),
                            style: IconButton.styleFrom(
                              minimumSize: const Size(48, 48),
                              backgroundColor: AppColors.primary.withValues(
                                alpha: .10,
                              ),
                              foregroundColor: AppColors.primaryDark,
                            ),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.t('savedFieldsTitle'),
                                  style: const TextStyle(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -.7,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  s.t('savedFieldsSubtitle'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
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
                      const SizedBox(height: 22),
                      FieldSearchBar(
                        controller: _searchController,
                        hintText: s.t('searchSavedFields'),
                        clearTooltip: s.t('clearSearch'),
                        onChanged: _onSearchChanged,
                        onClear: _clearSearch,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              if (_loadingFirstPage)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_fields.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    child: _FavoriteEmptyState(
                      isError: _loadError != null,
                      title: _loadError ?? s.t('favoritesEmpty'),
                      text: _loadError != null
                          ? s.t('tryAgainText')
                          : s.t('favoritesEmptyText'),
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
                    itemBuilder: (context, index) {
                      final field = _fields[index];
                      return FootballFieldCard(
                        field: field,
                        language: widget.controller.language,
                        favoriteBusy: _removeRequests.contains(field.id),
                        onFavoritePressed: () => _removeFavorite(field),
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                    child: _FavoriteFooter(
                      loading: _loadingNextPage,
                      error: _loadError,
                      hasNextPage: _hasNextPage,
                      finishedText: s.t('allFavoritesLoaded'),
                      retryLabel: s.t('tryAgain'),
                      onRetry: _loadNextPage,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteEmptyState extends StatelessWidget {
  const _FavoriteEmptyState({
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
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isError ? Icons.cloud_off_rounded : Icons.bookmark_border_rounded,
              color: AppColors.primary,
              size: 45,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
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
      ),
    );
  }
}

class _FavoriteFooter extends StatelessWidget {
  const _FavoriteFooter({
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
