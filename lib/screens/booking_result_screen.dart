import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/booking.dart';
import '../services/api_config.dart';
import '../theme/app_theme.dart';

class BookingResultScreen extends StatefulWidget {
  const BookingResultScreen({
    super.key,
    required this.controller,
    required this.booking,
  });

  final AppController controller;
  final Booking booking;

  @override
  State<BookingResultScreen> createState() => _BookingResultScreenState();
}

class _BookingResultScreenState extends State<BookingResultScreen> {
  Timer? _timer;
  late Duration _remaining;

  bool get _expired => _remaining == Duration.zero;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _remaining = _calculateRemaining();
    if (!_expired) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
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

  Duration _calculateRemaining() {
    final milliseconds = widget.booking.expiresAt
        .difference(DateTime.now())
        .inMilliseconds;
    if (milliseconds <= 0) return Duration.zero;
    return Duration(seconds: (milliseconds + 999) ~/ 1000);
  }

  void _tick() {
    final remaining = _calculateRemaining();
    if (!mounted) return;
    setState(() => _remaining = remaining);
    if (remaining == Duration.zero) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.controller.strings;
    final language = widget.controller.language;
    final booking = widget.booking;
    final currency = _currencyLabel(booking.currency, language);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(
                children: [
                  IconButton(
                    tooltip: s.t('back'),
                    onPressed: () => Navigator.of(context).pop(),
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
                      s.t('bookingResultTitle'),
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  _SuccessHero(
                    title: s.t('bookingCreatedTitle'),
                    text: s.t('bookingCreatedText'),
                  ),
                  const SizedBox(height: 16),
                  _CountdownCard(
                    remaining: _remaining,
                    expired: _expired,
                    title: _expired
                        ? s.t('bookingExpired')
                        : s.t('paymentTimeLeft'),
                    hint: _expired
                        ? s.t('bookingExpiredText')
                        : s.t('paymentTimeHint'),
                  ),
                  const SizedBox(height: 16),
                  _AdminNotice(
                    title: s.t('adminConfirmationTitle'),
                    text: s.t('adminConfirmationText'),
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(title: s.t('bookingInformation')),
                  const SizedBox(height: 10),
                  _BookingFieldCard(booking: booking, language: language),
                  const SizedBox(height: 12),
                  _SurfaceCard(
                    child: Column(
                      children: [
                        _ResultRow(
                          icon: Icons.confirmation_number_outlined,
                          label: s.t('bookingNumber'),
                          value: booking.bookingNumber,
                        ),
                        const _CardDivider(),
                        _ResultRow(
                          icon: Icons.calendar_month_outlined,
                          label: s.t('bookingDate'),
                          value: _displayDate(booking.bookingDate),
                        ),
                        const _CardDivider(),
                        _ResultRow(
                          icon: Icons.schedule_rounded,
                          label: s.t('bookingTime'),
                          value:
                              '${_shortTime(booking.startsAt)}–${_shortTime(booking.endsAt)}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(title: s.t('paymentInformation')),
                  const SizedBox(height: 10),
                  _SurfaceCard(
                    child: Column(
                      children: [
                        _ResultRow(
                          icon: Icons.payments_outlined,
                          label: s.t('totalAmount'),
                          value:
                              '${_formatNumber(booking.totalAmount)} $currency',
                        ),
                        const _CardDivider(),
                        _ResultRow(
                          icon: Icons.account_balance_wallet_outlined,
                          label: s.t('prepaymentAmount'),
                          value:
                              '${_formatNumber(booking.prepaymentAmount)} $currency',
                          highlight: true,
                        ),
                        const _CardDivider(),
                        _ResultRow(
                          icon: Icons.pending_actions_outlined,
                          label: s.t('paymentStatus'),
                          value: s.t('pendingPayment'),
                        ),
                      ],
                    ),
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

class _SuccessHero extends StatelessWidget {
  const _SuccessHero({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF075238), Color(0xFF22A96F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3322A96F),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 31,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .76),
                    fontSize: 12.5,
                    height: 1.4,
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
    required this.expired,
    required this.title,
    required this.hint,
  });

  final Duration remaining;
  final bool expired;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final color = expired ? AppColors.danger : const Color(0xFFE3912B);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              expired ? Icons.timer_off_outlined : Icons.timer_outlined,
              color: color,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hint,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _countdown(remaining),
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingFieldCard extends StatelessWidget {
  const _BookingFieldCard({required this.booking, required this.language});

  final Booking booking;
  final String language;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveApiUrl(booking.field.image?.url ?? '');
    final name = booking.field.name.value(language);
    final address = booking.field.address.value(language);
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            height: 104,
            child: imageUrl.isEmpty
                ? const ColoredBox(
                    color: Color(0xFFDDECE4),
                    child: Icon(
                      Icons.stadium_outlined,
                      color: AppColors.primary,
                    ),
                  )
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: Color(0xFFDDECE4),
                      child: Icon(
                        Icons.stadium_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? '—' : name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          address.isEmpty ? '—' : address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontSize: 11.5,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
    );
  }
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

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primaryDark, size: 20),
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
                style: TextStyle(
                  color: highlight ? AppColors.primaryDark : null,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(
        height: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

class _AdminNotice extends StatelessWidget {
  const _AdminNotice({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFF3478D4).withValues(alpha: .09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF3478D4).withValues(alpha: .22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.support_agent_rounded,
            color: Color(0xFF3478D4),
            size: 25,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12.5,
                    height: 1.45,
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

String _countdown(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

String _shortTime(String value) {
  final parts = value.split(':');
  return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : value;
}

String _displayDate(String value) {
  final date = DateTime.tryParse('${value}T00:00:00');
  if (date == null) return value;
  return '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.${date.year}';
}

String _formatNumber(double value) {
  final source = value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
  return source.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ');
}

String _currencyLabel(String currency, String language) {
  return currency.toUpperCase() == 'UZS'
      ? (language == 'ru' ? 'сум' : 'so‘m')
      : currency;
}
