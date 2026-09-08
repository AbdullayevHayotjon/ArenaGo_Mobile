import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/booking.dart';
import '../services/api_config.dart';
import '../services/booking_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import 'booking_details_screen.dart';

enum _OrdersTab { active, history }

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({
    super.key,
    required this.controller,
    required this.isActive,
  });

  final AppController controller;
  final bool isActive;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  static const _pageSize = 20;

  late final BookingService _bookingService;
  late final ScrollController _scrollController;

  final List<Booking> _bookings = [];
  _OrdersTab _selectedTab = _OrdersTab.active;
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
    _bookingService = BookingService(widget.controller.apiClient);
    _scrollController = ScrollController()..addListener(_onScroll);
    if (widget.isActive) _loadFirstPage();
  }

  @override
  void didUpdateWidget(covariant OrdersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  String get _apiTab =>
      _selectedTab == _OrdersTab.active ? 'active' : 'history';

  void _onScroll() {
    if (!_scrollController.hasClients || !_hasNextPage) return;
    if (_scrollController.position.extentAfter < 450) _loadNextPage();
  }

  void _selectTab(_OrdersTab tab) {
    if (_selectedTab == tab) return;
    setState(() => _selectedTab = tab);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
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
      final result = await _bookingService.getBookings(
        tab: _apiTab,
        pageNumber: 1,
        pageSize: _pageSize,
      );
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _bookings
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
        _bookings.clear();
        _pageNumber = 0;
        _totalCount = 0;
        _hasNextPage = false;
        _loadingFirstPage = false;
        _loadError = widget.controller.strings.t('ordersLoadError');
      });
    }
  }

  Future<void> _loadNextPage() async {
    if (_loadingFirstPage || _loadingNextPage || !_hasNextPage) return;
    final generation = _requestGeneration;
    setState(() => _loadingNextPage = true);

    try {
      final result = await _bookingService.getBookings(
        tab: _apiTab,
        pageNumber: _pageNumber + 1,
        pageSize: _pageSize,
      );
      if (!mounted || generation != _requestGeneration) return;
      final knownIds = _bookings.map((booking) => booking.id).toSet();
      setState(() {
        _bookings.addAll(
          result.items.where((booking) => knownIds.add(booking.id)),
        );
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
        _loadError = widget.controller.strings.t('ordersMoreLoadError');
      });
      AppToast.error(
        context,
        widget.controller.strings.t('ordersMoreLoadError'),
      );
    }
  }

  void _openDetails(Booking booking) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookingDetailsScreen(
          controller: widget.controller,
          bookingId: booking.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.controller.strings;
    final language = widget.controller.language;

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadFirstPage,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: AppColors.primaryDark,
                            size: 25,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.t('navOrders'),
                                style: const TextStyle(
                                  fontSize: 27,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.7,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                s.t('ordersSubtitle'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _TabSelector(
                      selectedTab: _selectedTab,
                      activeLabel: s.t('activeOrders'),
                      historyLabel: s.t('orderHistory'),
                      onSelected: _selectTab,
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
            if (_loadingFirstPage)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_bookings.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _OrdersEmpty(
                  isError: _loadError != null,
                  title:
                      _loadError ??
                      s.t(
                        _selectedTab == _OrdersTab.active
                            ? 'activeOrdersEmpty'
                            : 'orderHistoryEmpty',
                      ),
                  text: s.t(
                    _loadError != null
                        ? 'tryAgainText'
                        : _selectedTab == _OrdersTab.active
                        ? 'activeOrdersEmptyText'
                        : 'orderHistoryEmptyText',
                  ),
                  retryLabel: s.t('tryAgain'),
                  onRetry: _loadFirstPage,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                sliver: SliverList.separated(
                  itemCount: _bookings.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 13),
                  itemBuilder: (context, index) => _BookingCard(
                    booking: _bookings[index],
                    language: language,
                    controller: widget.controller,
                    onTap: () => _openDetails(_bookings[index]),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: _ListFooter(
                show: _bookings.isNotEmpty,
                loading: _loadingNextPage,
                allLoaded: !_hasNextPage && _bookings.length >= _totalCount,
                allLoadedText: s.t('allOrdersLoaded'),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 116)),
          ],
        ),
      ),
    );
  }
}

class _TabSelector extends StatelessWidget {
  const _TabSelector({
    required this.selectedTab,
    required this.activeLabel,
    required this.historyLabel,
    required this.onSelected,
  });

  final _OrdersTab selectedTab;
  final String activeLabel;
  final String historyLabel;
  final ValueChanged<_OrdersTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: .075)
            : const Color(0xFFE7EDE9),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _TabButton(
              label: activeLabel,
              icon: Icons.bolt_rounded,
              selected: selectedTab == _OrdersTab.active,
              onTap: () => onSelected(_OrdersTab.active),
            ),
          ),
          Expanded(
            child: _TabButton(
              label: historyLabel,
              icon: Icons.history_rounded,
              selected: selectedTab == _OrdersTab.history,
              onTap: () => onSelected(_OrdersTab.history),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? null : Colors.transparent,
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF22A96F), Color(0xFF16885B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: .28),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18.5,
              color: selected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13.8,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: selected ? .05 : 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.language,
    required this.controller,
    required this.onTap,
  });

  final Booking booking;
  final String language;
  final AppController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final imageUrl = resolveApiUrl(booking.field.image?.url ?? '');
    final fieldName = booking.field.name.value(language);
    final address = booking.field.address.value(language);
    final status = _statusView(booking.status, controller);
    final currency = booking.currency.toUpperCase() == 'UZS'
        ? (language == 'ru' ? 'сум' : 'so‘m')
        : booking.currency;

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: dark
                  ? Colors.white.withValues(alpha: .07)
                  : const Color(0xFFE5EBE8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? .18 : .055),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 126,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 116,
                      child: imageUrl.isEmpty
                          ? const _ImagePlaceholder()
                          : Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const _ImagePlaceholder(),
                            ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 13, 13, 11),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    fieldName.isEmpty ? '—' : fieldName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -.25,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 7),
                                _StatusBadge(status: status),
                              ],
                            ),
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 15,
                                  color: scheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    address.isEmpty ? '—' : address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                _CompactInfo(
                                  icon: Icons.calendar_today_outlined,
                                  text: _displayDate(booking.bookingDate),
                                ),
                                const SizedBox(width: 13),
                                _CompactInfo(
                                  icon: Icons.schedule_rounded,
                                  text:
                                      '${_shortTime(booking.startsAt)}–${_shortTime(booking.endsAt)}',
                                ),
                              ],
                            ),
                            const SizedBox(height: 9),
                            Text(
                              booking.bookingNumber,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: .15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: dark ? .07 : .045),
                  border: Border(
                    top: BorderSide(
                      color: dark
                          ? Colors.white.withValues(alpha: .06)
                          : const Color(0xFFE9EEEB),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _AmountInfo(
                        label: controller.strings.t('totalAmount'),
                        value:
                            '${_formatNumber(booking.totalAmount)} $currency',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 31,
                      color: scheme.outlineVariant.withValues(alpha: .75),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _AmountInfo(
                        label: controller.strings.t('remainingAmount'),
                        value:
                            '${_formatNumber(booking.remainingAmount)} $currency',
                        alignEnd: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusView {
  const _StatusView(this.text, this.color, this.icon);

  final String text;
  final Color color;
  final IconData icon;
}

_StatusView _statusView(String rawStatus, AppController controller) {
  switch (rawStatus.trim().toLowerCase()) {
    case 'pendingpayment':
      return _StatusView(
        controller.strings.t('orderStatusPendingPayment'),
        const Color(0xFFE99824),
        Icons.hourglass_top_rounded,
      );
    case 'confirmed':
      return _StatusView(
        controller.strings.t('orderStatusConfirmed'),
        AppColors.primaryDark,
        Icons.check_circle_outline_rounded,
      );
    case 'completed':
      return _StatusView(
        controller.strings.t('orderStatusCompleted'),
        const Color(0xFF3478C9),
        Icons.task_alt_rounded,
      );
    case 'cancelled':
    case 'canceled':
      return _StatusView(
        controller.strings.t('orderStatusCancelled'),
        AppColors.danger,
        Icons.cancel_outlined,
      );
    case 'expired':
      return _StatusView(
        controller.strings.t('orderStatusExpired'),
        const Color(0xFF7B8180),
        Icons.timer_off_outlined,
      );
    default:
      return _StatusView(
        controller.strings.t('orderStatusUnknown'),
        const Color(0xFF7B8180),
        Icons.help_outline_rounded,
      );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final _StatusView status;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 108),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 12.5, color: status.color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              status.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: status.color,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactInfo extends StatelessWidget {
  const _CompactInfo({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 1),
        Icon(icon, size: 14, color: AppColors.primaryDark),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _AmountInfo extends StatelessWidget {
  const _AmountInfo({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 10.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primary.withValues(alpha: .10),
      child: const Center(
        child: Icon(
          Icons.sports_soccer_rounded,
          color: AppColors.primary,
          size: 34,
        ),
      ),
    );
  }
}

class _OrdersEmpty extends StatelessWidget {
  const _OrdersEmpty({
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 130),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: (isError ? AppColors.danger : AppColors.primary)
                  .withValues(alpha: .11),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isError ? Icons.cloud_off_rounded : Icons.receipt_long_outlined,
              color: isError ? AppColors.danger : AppColors.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 17),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          if (isError) ...[
            const SizedBox(height: 18),
            FilledButton.tonalIcon(
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
    required this.show,
    required this.loading,
    required this.allLoaded,
    required this.allLoadedText,
  });

  final bool show;
  final bool loading;
  final bool allLoaded;
  final String allLoadedText;

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 22),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      );
    }
    if (!allLoaded) return const SizedBox(height: 12);
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 17,
            color: AppColors.primary,
          ),
          const SizedBox(width: 7),
          Text(
            allLoadedText,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _shortTime(String value) {
  final parts = value.split(':');
  return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : value;
}

String _displayDate(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}

String _formatNumber(double value) {
  final whole = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(whole[i]);
  }
  return buffer.toString();
}
