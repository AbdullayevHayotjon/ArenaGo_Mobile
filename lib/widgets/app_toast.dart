import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppToastType { success, error, warning, info }

abstract final class AppToast {
  static OverlayEntry? _currentEntry;

  static void success(BuildContext context, String message) {
    show(context, message: message, type: AppToastType.success);
  }

  static void error(BuildContext context, String message) {
    show(context, message: message, type: AppToastType.error);
  }

  static void warning(BuildContext context, String message) {
    show(context, message: message, type: AppToastType.warning);
  }

  static void info(BuildContext context, String message) {
    show(context, message: message, type: AppToastType.info);
  }

  static void show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    _currentEntry?.remove();

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastOverlay(
        message: message,
        type: type,
        duration: duration,
        onDismissed: () {
          if (!identical(_currentEntry, entry)) return;
          entry.remove();
          _currentEntry = null;
        },
      ),
    );

    _currentEntry = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }
}

class _ToastOverlay extends StatefulWidget {
  const _ToastOverlay({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismissed,
  });

  final String message;
  final AppToastType type;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    reverseDuration: const Duration(milliseconds: 210),
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
    reverseCurve: Curves.easeIn,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -.35),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_closing || !mounted) return;
    _closing = true;
    _timer?.cancel();
    await _controller.reverse();
    if (mounted) widget.onDismissed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visual = _visualFor(widget.type);
    return Positioned(
      top: 0,
      left: 14,
      right: 14,
      child: SafeArea(
        minimum: const EdgeInsets.only(top: 12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SlideTransition(
              position: _slide,
              child: FadeTransition(
                opacity: _opacity,
                child: Material(
                  color: Colors.transparent,
                  child: GestureDetector(
                    onTap: _dismiss,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: visual.color,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: visual.color.withValues(alpha: .28),
                            blurRadius: 24,
                            offset: const Offset(0, 9),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .18),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                visual.icon,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.message,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _dismiss,
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white70,
                                size: 19,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _ToastVisual _visualFor(AppToastType type) => switch (type) {
    AppToastType.success => const _ToastVisual(
      AppColors.primaryDark,
      Icons.check_rounded,
    ),
    AppToastType.error => const _ToastVisual(
      AppColors.danger,
      Icons.error_outline_rounded,
    ),
    AppToastType.warning => const _ToastVisual(
      Color(0xFFE3912B),
      Icons.warning_amber_rounded,
    ),
    AppToastType.info => const _ToastVisual(
      Color(0xFF3478D4),
      Icons.info_outline_rounded,
    ),
  };
}

class _ToastVisual {
  const _ToastVisual(this.color, this.icon);

  final Color color;
  final IconData icon;
}
