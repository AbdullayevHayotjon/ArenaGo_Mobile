import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/app_controller.dart';
import '../models/football_field.dart';
import '../services/football_field_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import 'football_field_details_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    required this.controller,
    required this.isActive,
  });

  final AppController controller;
  final bool isActive;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _fallbackCenter = LatLng(41.311081, 69.240562);

  late final FootballFieldService _fieldService;
  late final MapController _mapController;
  List<FootballFieldMapLocation> _locations = const [];
  LatLng? _userLocation;
  LatLng? _pendingCenter;
  bool _started = false;
  bool _mapReady = false;
  bool _loading = false;
  bool _locating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fieldService = FootballFieldService(widget.controller.apiClient);
    _mapController = MapController();
    if (widget.isActive) _start();
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isActive || oldWidget.isActive) return;
    if (_started) {
      _loadLocations();
    } else {
      _start();
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _start() {
    _started = true;
    _loadLocations();
    _locateUser(showMessage: true);
  }

  Future<void> _loadLocations() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final locations = await _fieldService.getLocations();
      if (!mounted) return;
      setState(() {
        _locations = locations;
        _loading = false;
      });
      if (_userLocation == null) _showAllFields(locations);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = widget.controller.strings.t('mapLoadError');
      });
    }
  }

  Future<void> _locateUser({bool showMessage = false}) async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (showMessage && mounted) {
          AppToast.warning(
            context,
            widget.controller.strings.t('locationServiceDisabled'),
          );
        }
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (showMessage && mounted) {
          AppToast.info(
            context,
            widget.controller.strings.t('locationPermissionDenied'),
          );
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      if (!mounted) return;
      final point = LatLng(position.latitude, position.longitude);
      setState(() => _userLocation = point);
      _moveTo(point, 15.2);
    } catch (_) {
      if (showMessage && mounted) {
        AppToast.info(
          context,
          widget.controller.strings.t('locationPermissionDenied'),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _moveTo(LatLng center, double zoom) {
    if (!_mapReady) {
      _pendingCenter = center;
      return;
    }
    _mapController.move(center, zoom);
  }

  void _showAllFields(List<FootballFieldMapLocation> locations) {
    if (locations.isEmpty) return;
    final points = locations
        .map((item) => LatLng(item.latitude, item.longitude))
        .toList(growable: false);
    if (!_mapReady) {
      _pendingCenter = points.first;
      return;
    }
    if (points.length == 1) {
      _mapController.move(points.first, 15.2);
      return;
    }
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.fromLTRB(45, 150, 45, 135),
        maxZoom: 15.2,
      ),
    );
  }

  void _onMapReady() {
    _mapReady = true;
    final pendingCenter = _pendingCenter;
    _pendingCenter = null;
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 15.2);
    } else if (_locations.length > 1) {
      _showAllFields(_locations);
    } else if (pendingCenter != null) {
      _mapController.move(pendingCenter, 15.2);
    }
  }

  void _openField(FootballFieldMapLocation location) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FootballFieldDetailsScreen(
          controller: widget.controller,
          footballFieldId: location.id,
        ),
      ),
    );
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
    return SafeArea(
      bottom: false,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _fallbackCenter,
              initialZoom: 12.5,
              minZoom: 3,
              maxZoom: 19,
              onMapReady: _onMapReady,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'uz.arenago.arenago',
              ),
              MarkerLayer(
                markers: [
                  ..._locations.map(
                    (location) => Marker(
                      point: LatLng(location.latitude, location.longitude),
                      width: 54,
                      height: 60,
                      alignment: Alignment.bottomCenter,
                      child: Semantics(
                        button: true,
                        label: s.t('fieldDetailsTitle'),
                        child: GestureDetector(
                          onTap: () => _openField(location),
                          child: const _FieldMarker(),
                        ),
                      ),
                    ),
                  ),
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 36,
                      height: 36,
                      child: const _UserMarker(),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 96),
                child: RichAttributionWidget(
                  alignment: AttributionAlignment.bottomLeft,
                  showFlutterMapAttribution: false,
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      onTap: _openAttribution,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 16,
            left: 18,
            right: 18,
            child: _MapHeader(
              title: s.t('navMap'),
              subtitle: s.t('mapSubtitle'),
            ),
          ),
          Positioned(
            top: 100,
            right: 18,
            child: _MapActionButton(
              tooltip: s.t('myLocation'),
              loading: _locating,
              onPressed: () => _locateUser(showMessage: true),
            ),
          ),
          if (_loading)
            const Positioned(top: 108, left: 20, child: _LoadingChip()),
          if (_error != null)
            Positioned(
              top: 100,
              left: 18,
              right: 80,
              child: _MapErrorChip(
                text: _error!,
                retryLabel: s.t('mapRetry'),
                onRetry: _loadLocations,
              ),
            ),
        ],
      ),
    );
  }
}

class _MapHeader extends StatelessWidget {
  const _MapHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 12, 16, 12),
          decoration: BoxDecoration(
            color: (dark ? AppColors.darkSurface : Colors.white).withValues(
              alpha: .93,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: dark
                  ? Colors.white.withValues(alpha: .09)
                  : Colors.white.withValues(alpha: .92),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? .25 : .12),
                blurRadius: 24,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.map_rounded,
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
                      title,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12.5,
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

class _FieldMarker extends StatelessWidget {
  const _FieldMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          bottom: 5,
          child: Transform.rotate(
            angle: .785398,
            child: Container(
              width: 16,
              height: 16,
              color: const Color(0xFF137C53),
            ),
          ),
        ),
        Positioned(
          top: 2,
          child: Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF25B878), Color(0xFF137C53)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.sports_soccer_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
        ),
      ],
    );
  }
}

class _UserMarker extends StatelessWidget {
  const _UserMarker();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0x332C7BE5),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x552C7BE5)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2C7BE5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 8)],
        ),
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.tooltip,
    required this.loading,
    required this.onPressed,
  });
  final String tooltip;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: .95),
      elevation: 7,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      child: IconButton(
        tooltip: tooltip,
        onPressed: loading ? null : onPressed,
        style: IconButton.styleFrom(minimumSize: const Size(50, 50)),
        icon: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              )
            : const Icon(
                Icons.my_location_rounded,
                color: AppColors.primaryDark,
              ),
      ),
    );
  }
}

class _LoadingChip extends StatelessWidget {
  const _LoadingChip();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 14)],
      ),
      child: const CircularProgressIndicator(strokeWidth: 2.2),
    );
  }
}

class _MapErrorChip extends StatelessWidget {
  const _MapErrorChip({
    required this.text,
    required this.retryLabel,
    required this.onRetry,
  });
  final String text;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: .96),
      elevation: 6,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onRetry,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const Icon(
                Icons.refresh_rounded,
                color: AppColors.danger,
                size: 20,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                retryLabel,
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
