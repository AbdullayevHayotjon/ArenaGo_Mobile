import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/app_controller.dart';
import '../models/booking.dart';
import '../services/api_config.dart';
import '../services/booking_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';

class BookingDetailsScreen extends StatefulWidget {
  const BookingDetailsScreen({
    super.key,
    required this.controller,
    required this.bookingId,
  });

  final AppController controller;
  final String bookingId;

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  late final BookingService _bookingService;
  Booking? _booking;
  Duration _remaining = Duration.zero;
  Timer? _timer;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bookingService = BookingService(widget.controller.apiClient);
    widget.controller.addListener(_onControllerChanged);
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted || widget.controller.stage == AppStage.home) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _load() async {
    _timer?.cancel();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final booking = await _bookingService.getById(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _booking = booking;
        _loading = false;
      });
      _startCountdownIfNeeded(booking);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = widget.controller.strings.t('bookingDetailsLoadError');
      });
    }
  }

  bool _isPendingPayment(Booking booking) =>
      booking.status.trim().toLowerCase() == 'pendingpayment';

  void _startCountdownIfNeeded(Booking booking) {
    if (!_isPendingPayment(booking)) return;
    _updateRemaining(booking);
    if (_remaining == Duration.zero) return;
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateRemaining(booking),
    );
  }

  void _updateRemaining(Booking booking) {
    final milliseconds = booking.expiresAt
        .difference(DateTime.now())
        .inMilliseconds;
    final remaining = milliseconds <= 0
        ? Duration.zero
        : Duration(seconds: (milliseconds / 1000).ceil());
    if (!mounted) return;
    setState(() => _remaining = remaining);
    if (remaining == Duration.zero) {
      _timer?.cancel();
      _timer = null;
    }
  }

  Future<void> _callAdmin(Booking booking) async {
    final phone = booking.field.phoneNumber.trim();
    if (phone.isEmpty) return;
    try {
      final opened = await launchUrl(
        Uri(scheme: 'tel', path: phone),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        AppToast.error(context, widget.controller.strings.t('callOpenError'));
      }
    } catch (_) {
      if (mounted) {
        AppToast.error(context, widget.controller.strings.t('callOpenError'));
      }
    }
  }

  Future<void> _openExternalMap(Booking booking) async {
    final latitude = booking.field.latitude;
    final longitude = booking.field.longitude;
    final name = booking.field.name.value(widget.controller.language);
    final geoUri = Uri.parse(
      'geo:$latitude,$longitude?q=$latitude,$longitude(${Uri.encodeComponent(name)})',
    );
    final webUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    try {
      if (await launchUrl(geoUri, mode: LaunchMode.externalApplication)) return;
      final opened = await launchUrl(
        webUri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        AppToast.error(context, widget.controller.strings.t('mapOpenError'));
      }
    } catch (_) {
      if (mounted) {
        AppToast.error(context, widget.controller.strings.t('mapOpenError'));
      }
    }
  }

  Future<void> _openAttribution() async {
    await launchUrl(
      Uri.parse('https://www.openstreetmap.org/copyright'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.controller.strings;
    final booking = _booking;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: _loading || _error != null || booking == null
            ? _LoadState(
                title: s.t('bookingDetailsTitle'),
                backLabel: s.t('back'),
                loading: _loading,
                error: _error,
                retryLabel: s.t('tryAgain'),
                onBack: () => Navigator.of(context).pop(),
                onRetry: _load,
              )
            : _BookingContent(
                booking: booking,
                language: widget.controller.language,
                remaining: _remaining,
                showCountdown: _isPendingPayment(booking),
                strings: s.t,
                onBack: () => Navigator.of(context).pop(),
                onCall: () => _callAdmin(booking),
                onOpenMap: () => _openExternalMap(booking),
                onOpenAttribution: _openAttribution,
              ),
      ),
    );
  }
}

class _BookingContent extends StatelessWidget {
  const _BookingContent({
    required this.booking,
    required this.language,
    required this.remaining,
    required this.showCountdown,
    required this.strings,
    required this.onBack,
    required this.onCall,
    required this.onOpenMap,
    required this.onOpenAttribution,
  });

  final Booking booking;
  final String language;
  final Duration remaining;
  final bool showCountdown;
  final String Function(String key) strings;
  final VoidCallback onBack;
  final VoidCallback onCall;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenAttribution;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = booking.field.name.value(language);
    final address = booking.field.address.value(language);
    final currency = _currencyLabel(booking.currency, language);
    final status = _bookingStatus(booking.status, strings);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: _BookingHero(
            imageUrl: resolveApiUrl(booking.field.image?.url ?? ''),
            title: strings('bookingDetailsTitle'),
            backLabel: strings('back'),
            onBack: onBack,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          sliver: SliverList.list(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      name.isEmpty ? '—' : name,
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.7,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _StatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      address.isEmpty ? '—' : address,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (showCountdown) ...[
                const SizedBox(height: 20),
                _CountdownCard(
                  remaining: remaining,
                  title: remaining == Duration.zero
                      ? strings('bookingExpired')
                      : strings('paymentTimeLeft'),
                  text: remaining == Duration.zero
                      ? strings('bookingExpiredText')
                      : strings('paymentTimeHint'),
                ),
              ],
              const SizedBox(height: 23),
              _SectionTitle(title: strings('bookingInformation')),
              const SizedBox(height: 10),
              _SurfaceCard(
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.confirmation_number_outlined,
                      label: strings('bookingNumber'),
                      value: booking.bookingNumber,
                    ),
                    const _CardDivider(),
                    _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: strings('bookingDate'),
                      value: _displayDate(booking.bookingDate),
                    ),
                    const _CardDivider(),
                    _DetailRow(
                      icon: Icons.schedule_rounded,
                      label: strings('bookingTime'),
                      value:
                          '${_shortTime(booking.startsAt)}–${_shortTime(booking.endsAt)}',
                    ),
                    const _CardDivider(),
                    _DetailRow(
                      icon: status.icon,
                      iconColor: status.color,
                      label: strings('bookingStatus'),
                      value: status.text,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _SectionTitle(title: strings('paymentInformation')),
              const SizedBox(height: 10),
              _SurfaceCard(
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.payments_outlined,
                      label: strings('totalAmount'),
                      value: '${_formatNumber(booking.totalAmount)} $currency',
                    ),
                    const _CardDivider(),
                    _DetailRow(
                      icon: Icons.account_balance_wallet_outlined,
                      label: strings('prepaymentAmount'),
                      value:
                          '${_formatNumber(booking.prepaymentAmount)} $currency',
                    ),
                    const _CardDivider(),
                    _DetailRow(
                      icon: Icons.check_circle_outline_rounded,
                      label: strings('paidAmount'),
                      value:
                          '${_formatNumber(booking.collectedAmount)} $currency',
                    ),
                    const _CardDivider(),
                    _DetailRow(
                      icon: Icons.pending_actions_outlined,
                      label: strings('remainingAmount'),
                      value:
                          '${_formatNumber(booking.remainingAmount)} $currency',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _SectionTitle(title: strings('fieldContact')),
              const SizedBox(height: 10),
              _PhoneCard(
                label: strings('phone'),
                phone: booking.field.phoneNumber,
                onTap: onCall,
              ),
              if (booking.field.hasValidCoordinates) ...[
                const SizedBox(height: 22),
                _SectionTitle(title: strings('fieldLocation')),
                const SizedBox(height: 10),
                _MapCard(
                  coordinates: LatLng(
                    booking.field.latitude,
                    booking.field.longitude,
                  ),
                  openMapLabel: strings('viewOnMap'),
                  onOpenMap: onOpenMap,
                  onOpenAttribution: onOpenAttribution,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BookingHero extends StatelessWidget {
  const _BookingHero({
    required this.imageUrl,
    required this.title,
    required this.backLabel,
    required this.onBack,
  });

  final String imageUrl;
  final String title;
  final String backLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).scaffoldBackgroundColor;
    return SizedBox(
      height: 305,
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageUrl.isEmpty
              ? const _HeroPlaceholder()
              : Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _HeroPlaceholder(),
                ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0x55000000),
                  Colors.transparent,
                  const Color(0x99000000),
                  background,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, .34, .73, 1],
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 16,
            right: 16,
            child: Row(
              children: [
                IconButton(
                  tooltip: backLabel,
                  onPressed: onBack,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(46, 46),
                    backgroundColor: Colors.black.withValues(alpha: .35),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(color: Color(0x66000000), blurRadius: 10),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownCard extends StatelessWidget {
  const _CountdownCard({
    required this.remaining,
    required this.title,
    required this.text,
  });
  final Duration remaining;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final expired = remaining == Duration.zero;
    final color = expired ? AppColors.danger : const Color(0xFFE99824);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              expired ? Icons.timer_off_outlined : Icons.timer_outlined,
              color: color,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  expired ? text : _formatDuration(remaining),
                  style: TextStyle(
                    color: expired
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : color,
                    fontSize: expired ? 12 : 27,
                    height: expired ? 1.35 : 1,
                    fontWeight: FontWeight.w900,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (!expired) ...[
                  const SizedBox(height: 5),
                  Text(
                    text,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusData {
  const _StatusData(this.text, this.color, this.icon);
  final String text;
  final Color color;
  final IconData icon;
}

_StatusData _bookingStatus(String raw, String Function(String) strings) {
  switch (raw.trim().toLowerCase()) {
    case 'pendingpayment':
      return _StatusData(
        strings('orderStatusPendingPayment'),
        const Color(0xFFE99824),
        Icons.hourglass_top_rounded,
      );
    case 'confirmed':
      return _StatusData(
        strings('orderStatusConfirmed'),
        AppColors.primaryDark,
        Icons.check_circle_outline_rounded,
      );
    case 'completed':
      return _StatusData(
        strings('orderStatusCompleted'),
        const Color(0xFF3478C9),
        Icons.task_alt_rounded,
      );
    case 'cancelled':
    case 'canceled':
      return _StatusData(
        strings('orderStatusCancelled'),
        AppColors.danger,
        Icons.cancel_outlined,
      );
    case 'expired':
      return _StatusData(
        strings('orderStatusExpired'),
        const Color(0xFF7B8180),
        Icons.timer_off_outlined,
      );
    default:
      return _StatusData(
        strings('orderStatusUnknown'),
        const Color(0xFF7B8180),
        Icons.help_outline_rounded,
      );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final _StatusData status;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, color: status.color, size: 14),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              status.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: status.color,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
  );
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .55)),
      ),
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = AppColors.primaryDark,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Divider(
      height: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
    ),
  );
}

class _PhoneCard extends StatelessWidget {
  const _PhoneCard({
    required this.label,
    required this.phone,
    required this.onTap,
  });
  final String label;
  final String phone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final available = phone.trim().isNotEmpty;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .55)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: available ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.phone_outlined,
                  color: AppColors.primaryDark,
                  size: 21,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      available ? phone : '—',
                      style: TextStyle(
                        color: available
                            ? AppColors.primaryDark
                            : scheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        decoration: available
                            ? TextDecoration.underline
                            : TextDecoration.none,
                        decorationColor: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              if (available)
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryDark,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.call_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({
    required this.coordinates,
    required this.openMapLabel,
    required this.onOpenMap,
    required this.onOpenAttribution,
  });
  final LatLng coordinates;
  final String openMapLabel;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenAttribution;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .55)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 230,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: coordinates,
                initialZoom: 15.5,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'uz.arenago.arenago',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: coordinates,
                      width: 52,
                      height: 52,
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x44000000),
                              blurRadius: 14,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.sports_soccer_rounded,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                    ),
                  ],
                ),
                RichAttributionWidget(
                  showFlutterMapAttribution: false,
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      onTap: onOpenAttribution,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: OutlinedButton.icon(
              onPressed: onOpenMap,
              icon: const Icon(Icons.map_outlined),
              label: Text(openMapLabel),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: AppColors.primaryDark,
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: .45),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder();
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1D3027)
        : const Color(0xFFDDECE4),
    child: const Center(
      child: Icon(Icons.stadium_outlined, color: AppColors.primary, size: 62),
    ),
  );
}

class _LoadState extends StatelessWidget {
  const _LoadState({
    required this.title,
    required this.backLabel,
    required this.loading,
    required this.error,
    required this.retryLabel,
    required this.onBack,
    required this.onRetry,
  });
  final String title;
  final String backLabel;
  final bool loading;
  final String? error;
  final String retryLabel;
  final VoidCallback onBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 20, 12),
          child: Row(
            children: [
              IconButton(
                tooltip: backLabel,
                onPressed: onBack,
                style: IconButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  backgroundColor: AppColors.primary.withValues(alpha: .10),
                  foregroundColor: AppColors.primaryDark,
                ),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: loading
                ? const CircularProgressIndicator()
                : Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          color: AppColors.danger,
                          size: 48,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          error ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.tonalIcon(
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(retryLabel),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
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

String _currencyLabel(String value, String language) {
  return value.toUpperCase() == 'UZS'
      ? (language == 'ru' ? 'сум' : 'so‘m')
      : value;
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.toString().padLeft(2, '0');
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
