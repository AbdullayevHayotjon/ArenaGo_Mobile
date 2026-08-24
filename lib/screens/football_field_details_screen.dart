import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/app_controller.dart';
import '../models/football_field.dart';
import '../services/api_config.dart';
import '../services/football_field_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';

class FootballFieldDetailsScreen extends StatefulWidget {
  const FootballFieldDetailsScreen({
    super.key,
    required this.controller,
    required this.footballFieldId,
  });

  final AppController controller;
  final String footballFieldId;

  @override
  State<FootballFieldDetailsScreen> createState() =>
      _FootballFieldDetailsScreenState();
}

class _FootballFieldDetailsScreenState
    extends State<FootballFieldDetailsScreen> {
  late final FootballFieldService _footballFieldService;

  FootballField? _field;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _footballFieldService = FootballFieldService(widget.controller.apiClient);
    widget.controller.addListener(_onControllerChanged);
    _load();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted || widget.controller.stage == AppStage.home) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final field = await _footballFieldService.getById(widget.footballFieldId);
      if (!mounted) return;
      setState(() {
        _field = field;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = widget.controller.strings.t('fieldDetailsLoadError');
      });
    }
  }

  Future<void> _openExternalMap(FootballField field) async {
    final latitude = field.location.latitude;
    final longitude = field.location.longitude;
    final name = field.name.value(widget.controller.language);
    final encodedName = Uri.encodeComponent(name);
    final geoUri = Uri.parse(
      'geo:$latitude,$longitude?q=$latitude,$longitude($encodedName)',
    );
    final webUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    try {
      final opened = await launchUrl(
        geoUri,
        mode: LaunchMode.externalApplication,
      );
      if (opened) return;
      final openedOnWeb = await launchUrl(
        webUri,
        mode: LaunchMode.externalApplication,
      );
      if (!openedOnWeb && mounted) {
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
    final field = _field;

    return Scaffold(
      bottomNavigationBar: field == null
          ? null
          : _BookingBar(
              field: field,
              language: widget.controller.language,
              priceLabel: s.t('hourlyPrice'),
              bookingLabel: s.t('bookNow'),
            ),
      body: SafeArea(
        bottom: field == null,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
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
                      s.t('fieldDetailsTitle'),
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
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _DetailsError(
                      message: _error!,
                      text: s.t('tryAgainText'),
                      retryLabel: s.t('tryAgain'),
                      onRetry: _load,
                    )
                  : _DetailsContent(
                      field: field!,
                      language: widget.controller.language,
                      onOpenMap: () => _openExternalMap(field),
                      onOpenAttribution: _openAttribution,
                      strings: s.t,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsContent extends StatelessWidget {
  const _DetailsContent({
    required this.field,
    required this.language,
    required this.onOpenMap,
    required this.onOpenAttribution,
    required this.strings,
  });

  final FootballField field;
  final String language;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenAttribution;
  final String Function(String key) strings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = field.name.value(language);
    final address = field.address.value(language);
    final description = field.description.value(language);
    final coordinates = LatLng(
      field.location.latitude,
      field.location.longitude,
    );
    final currency = _currencyLabel(field.currency, language);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          sliver: SliverList.list(
            children: [
              _HeroImage(
                imageUrl: resolveApiUrl(field.image?.url ?? ''),
                isFavorite: field.isFavorite,
              ),
              const SizedBox(height: 18),
              Text(
                name.isEmpty ? '—' : name,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.7,
                ),
              ),
              const SizedBox(height: 10),
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
              const SizedBox(height: 14),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  _InfoChip(
                    icon: Icons.schedule_rounded,
                    text:
                        '${_shortTime(field.opensAt)} – ${_shortTime(field.closesAt)}',
                  ),
                  _InfoChip(
                    icon: Icons.payments_outlined,
                    text:
                        '${_formatNumber(field.hourlyPrice)} $currency / ${strings('hourShort')}',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: strings('description')),
              const SizedBox(height: 10),
              _SurfaceCard(
                child: Text(
                  description.isEmpty ? strings('noDescription') : description,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _SectionTitle(title: strings('priceDetails')),
              const SizedBox(height: 10),
              _SurfaceCard(
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.access_time_rounded,
                      label: strings('hourlyPrice'),
                      value: '${_formatNumber(field.hourlyPrice)} $currency',
                    ),
                    const _CardDivider(),
                    _DetailRow(
                      icon: Icons.account_balance_wallet_outlined,
                      label: strings('prepaymentAmount'),
                      value:
                          '${_formatNumber(field.prepaymentAmount)} $currency',
                    ),
                    const _CardDivider(),
                    _DetailRow(
                      icon: Icons.percent_rounded,
                      label: strings('prepaymentPercent'),
                      value: '${_formatNumber(field.prepaymentPercent)}%',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _SectionTitle(title: strings('contact')),
              const SizedBox(height: 10),
              _SurfaceCard(
                child: _DetailRow(
                  icon: Icons.phone_outlined,
                  label: strings('phone'),
                  value: field.phoneNumber.isEmpty ? '—' : field.phoneNumber,
                ),
              ),
              const SizedBox(height: 22),
              _SectionTitle(title: strings('location')),
              const SizedBox(height: 10),
              _MapCard(
                coordinates: coordinates,
                latitudeLabel: strings('latitude'),
                longitudeLabel: strings('longitude'),
                openMapLabel: strings('viewOnMap'),
                onOpenMap: onOpenMap,
                onOpenAttribution: onOpenAttribution,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.imageUrl, required this.isFavorite});

  final String imageUrl;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const _HeroPlaceholder(),
            )
          else
            const _HeroPlaceholder(),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Color(0x66000000)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: 14,
            right: 14,
            child: Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: isFavorite
                    ? AppColors.primary
                    : Colors.black.withValues(alpha: .30),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: .45)),
              ),
              child: Icon(
                isFavorite
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: Colors.white,
                size: 22,
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
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1D3027)
          : const Color(0xFFDDECE4),
      child: const Center(
        child: Icon(Icons.stadium_outlined, color: AppColors.primary, size: 62),
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({
    required this.coordinates,
    required this.latitudeLabel,
    required this.longitudeLabel,
    required this.openMapLabel,
    required this.onOpenMap,
    required this.onOpenAttribution,
  });

  final LatLng coordinates;
  final String latitudeLabel;
  final String longitudeLabel;
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
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _Coordinate(
                        label: latitudeLabel,
                        value: coordinates.latitude.toStringAsFixed(6),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Coordinate(
                        label: longitudeLabel,
                        value: coordinates.longitude.toStringAsFixed(6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                OutlinedButton.icon(
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Coordinate extends StatelessWidget {
  const _Coordinate({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: AppColors.primaryDark),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

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

class _BookingBar extends StatelessWidget {
  const _BookingBar({
    required this.field,
    required this.language,
    required this.priceLabel,
    required this.bookingLabel,
  });

  final FootballField field;
  final String language;
  final String priceLabel;
  final String bookingLabel;

  @override
  Widget build(BuildContext context) {
    final currency = _currencyLabel(field.currency, language);
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 11, 20, 12),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
            top: BorderSide(color: scheme.outlineVariant.withValues(alpha: .7)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .08),
              blurRadius: 22,
              offset: const Offset(0, -7),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    priceLabel,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 10.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatNumber(field.hourlyPrice)} $currency',
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 152,
              child: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.calendar_month_outlined, size: 20),
                label: Text(bookingLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsError extends StatelessWidget {
  const _DetailsError({
    required this.message,
    required this.text,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String text;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.primary,
              size: 48,
            ),
            const SizedBox(height: 14),
            Text(
              message,
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
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
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

String _currencyLabel(String currency, String language) {
  return currency.toUpperCase() == 'UZS'
      ? (language == 'ru' ? 'сум' : 'so‘m')
      : currency;
}
