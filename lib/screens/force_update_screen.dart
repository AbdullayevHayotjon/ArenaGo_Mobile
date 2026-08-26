import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/app_controller.dart';
import '../services/api_config.dart';
import '../theme/app_theme.dart';
import '../widgets/arena_logo.dart';

class ForceUpdateScreen extends StatefulWidget {
  const ForceUpdateScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends State<ForceUpdateScreen>
    with WidgetsBindingObserver {
  bool _storeOpened = false;
  bool _openingStore = false;
  bool _openFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _storeOpened) {
      _storeOpened = false;
      widget.controller.recheckAppVersion();
    }
  }

  Future<void> _openStore() async {
    if (_openingStore || widget.controller.versionCheckBusy) return;
    setState(() {
      _openingStore = true;
      _openFailed = false;
    });

    final isAndroid = widget.controller.appPlatform == 'android';
    final webUrl = isAndroid ? androidStoreUrl : iosStoreUrl;
    final primaryUrl = isAndroid
        ? Uri.parse('market://details?id=uz.arenago.arenago')
        : Uri.parse(webUrl);

    try {
      var opened = await _tryLaunch(primaryUrl);
      if (!opened && primaryUrl.toString() != webUrl) {
        opened = await _tryLaunch(Uri.parse(webUrl));
      }
      if (!mounted) return;
      if (opened) {
        _storeOpened = true;
      } else {
        setState(() => _openFailed = true);
      }
    } catch (_) {
      if (mounted) setState(() => _openFailed = true);
    } finally {
      if (mounted) setState(() => _openingStore = false);
    }
  }

  Future<bool> _tryLaunch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.controller.strings;
    final checking = widget.controller.versionCheckBusy;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const _UpdateBackground(),
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.sizeOf(context).height -
                        MediaQuery.paddingOf(context).vertical -
                        56,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const ArenaLogo(size: 43, animate: true),
                      const SizedBox(height: 34),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                        decoration: BoxDecoration(
                          color: dark
                              ? AppColors.darkSurface.withValues(alpha: .97)
                              : Colors.white.withValues(alpha: .97),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: .20),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x2916885B),
                              blurRadius: 34,
                              offset: Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF22A96F),
                                    Color(0xFF08754D),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(23),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x4422A96F),
                                    blurRadius: 22,
                                    offset: Offset(0, 9),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.system_update_alt_rounded,
                                color: Colors.white,
                                size: 37,
                              ),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              s.t('forceUpdateTitle'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 25,
                                height: 1.15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -.45,
                              ),
                            ),
                            const SizedBox(height: 11),
                            Text(
                              s.t('forceUpdateText'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 14,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: .10),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Text(
                                '${s.t('installedVersion')}: ${widget.controller.appVersion}',
                                style: const TextStyle(
                                  color: AppColors.primaryDark,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (_openFailed) ...[
                              const SizedBox(height: 15),
                              Text(
                                s.t('storeOpenError'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            const SizedBox(height: 22),
                            FilledButton.icon(
                              onPressed: checking || _openingStore
                                  ? null
                                  : _openStore,
                              icon: checking || _openingStore
                                  ? const SizedBox(
                                      width: 19,
                                      height: 19,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.download_rounded),
                              label: Text(
                                s.t(checking ? 'checkingVersion' : 'updateNow'),
                              ),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(55),
                                backgroundColor: AppColors.primaryDark,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: AppColors.primaryDark
                                    .withValues(alpha: .65),
                                disabledForegroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(17),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpdateBackground extends StatelessWidget {
  const _UpdateBackground();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark
              ? const [Color(0xFF091B14), Color(0xFF10271E)]
              : const [Color(0xFFF0FAF5), Color(0xFFE1F3E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CustomPaint(painter: _FieldLinesPainter()),
    );
  }
}

class _FieldLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: .065)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final rect = Rect.fromLTWH(
      size.width * .08,
      size.height * .08,
      size.width * .84,
      size.height * .84,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(34)),
      paint,
    );
    canvas.drawLine(
      Offset(size.width / 2, rect.top),
      Offset(size.width / 2, rect.bottom),
      paint,
    );
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 72, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
