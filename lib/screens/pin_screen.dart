import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/floating_football.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key, required this.controller, required this.create});
  final AppController controller;
  final bool create;

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final _pin = TextEditingController();
  final _pinFocus = FocusNode();
  String? _firstPin;
  bool _checking = false;
  bool _openingApp = false;
  bool _biometricAvailable = false;
  bool _biometricRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.create) {
        _ensurePinKeyboardIsVisible();
      } else {
        _initializeUnlock();
      }
    });
  }

  @override
  void dispose() {
    _pin.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  Future<void> _handle(String value) async {
    if (value.length != 4 || _checking) return;
    setState(() => _checking = true);
    if (widget.create) {
      if (_firstPin == null) {
        setState(() {
          _firstPin = value;
          _pin.clear();
          _checking = false;
        });
      } else if (_firstPin != value) {
        final message = widget.controller.strings.t('pinMismatch');
        setState(() {
          _firstPin = null;
          _pin.clear();
          _checking = false;
        });
        if (mounted) AppToast.error(context, message);
      } else {
        _hideKeyboard();
        setState(() => _openingApp = true);
        await widget.controller.createPin(value);
        if (!mounted) return;
        await _offerBiometrics();
        await widget.controller.completePinSetup();
      }
    } else {
      _hideKeyboard();
      setState(() => _openingApp = true);
      final valid = await widget.controller.unlock(value);
      if (mounted && !valid) {
        setState(() {
          _pin.clear();
          _checking = false;
          _openingApp = false;
        });
        AppToast.error(context, widget.controller.strings.t('pinWrong'));
        _ensurePinKeyboardIsVisible();
      }
    }
  }

  Future<void> _initializeUnlock() async {
    final enabled = await widget.controller.isBiometricEnabled();
    final available = enabled && await widget.controller.canUseBiometrics();
    if (!mounted) return;
    setState(() => _biometricAvailable = available);
    if (available) {
      await _authenticateBiometrically(showFailure: false);
    } else {
      await _ensurePinKeyboardIsVisible();
    }
  }

  Future<void> _authenticateBiometrically({required bool showFailure}) async {
    if (_biometricRunning || _openingApp) return;
    _hideKeyboard();
    setState(() => _biometricRunning = true);
    final authenticated = await widget.controller.authenticateWithBiometrics();
    if (!mounted) return;
    if (authenticated) {
      setState(() {
        _biometricRunning = false;
        _openingApp = true;
      });
      await widget.controller.unlockWithBiometrics();
      return;
    }
    setState(() => _biometricRunning = false);
    if (showFailure) {
      AppToast.info(context, widget.controller.strings.t('biometricFailed'));
    }
    await _ensurePinKeyboardIsVisible();
  }

  Future<void> _offerBiometrics() async {
    if (!await widget.controller.canUseBiometrics() || !mounted) return;
    final s = widget.controller.strings;
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.fingerprint_rounded,
            color: AppColors.primaryDark,
            size: 32,
          ),
        ),
        title: Text(s.t('enableBiometricsTitle')),
        content: Text(s.t('enableBiometricsText'), textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s.t('notNow')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s.t('enableBiometrics')),
          ),
        ],
      ),
    );
    if (accepted != true) {
      await widget.controller.setBiometricEnabled(false);
      return;
    }
    final authenticated = await widget.controller.confirmBiometricSetup();
    await widget.controller.setBiometricEnabled(authenticated);
    if (!authenticated && mounted) {
      AppToast.info(context, s.t('biometricFailed'));
    }
  }

  Future<void> _logout() async {
    final successMessage = widget.controller.strings.t('logoutSuccess');
    final error = await widget.controller.logout();
    if (error != null) {
      if (mounted) AppToast.error(context, error);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppToast.successFromRoot(successMessage);
    });
  }

  void _showPinKeyboard() {
    _pinFocus.requestFocus();
    _pin.selection = TextSelection.collapsed(offset: _pin.text.length);
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }

  void _hideKeyboard() {
    _pinFocus.unfocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  }

  Future<void> _ensurePinKeyboardIsVisible() async {
    for (var attempt = 0; attempt < 4; attempt++) {
      await Future<void>.delayed(
        Duration(milliseconds: attempt == 0 ? 180 : 320),
      );
      if (!mounted) return;
      _showPinKeyboard();
      await Future<void>.delayed(const Duration(milliseconds: 160));
      if (!mounted || MediaQuery.viewInsetsOf(context).bottom > 0) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final confirming = widget.create && _firstPin != null;
    final s = widget.controller.strings;
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (widget.create)
                        _PinActionButton(
                          tooltip: s.t('backToLogin'),
                          loading: widget.controller.logoutBusy,
                          icon: Icons.arrow_back_rounded,
                          onPressed: widget.controller.logoutBusy
                              ? null
                              : _logout,
                        )
                      else
                        const SizedBox(width: 48),
                      const Spacer(),
                      if (!widget.create)
                        _PinActionButton(
                          tooltip: s.t('logout'),
                          loading: widget.controller.logoutBusy,
                          icon: Icons.logout_rounded,
                          foregroundColor: AppColors.danger,
                          onPressed: widget.controller.logoutBusy
                              ? null
                              : _logout,
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                  const Spacer(),
                  const FloatingFootball(
                    size: 92,
                    padding: 20,
                    backgroundColor: Color(0x1F22A96F),
                    shadowColor: Color(0x3322A96F),
                    shadowBlurRadius: 28,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    widget.create
                        ? (confirming ? s.t('confirmPin') : s.t('createPin'))
                        : s.t('unlock'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.7,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    widget.create
                        ? (confirming
                              ? s.t('confirmPinText')
                              : s.t('createPinText'))
                        : s.t('unlockText'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _PinCodeFields(
                    controller: _pin,
                    focusNode: _pinFocus,
                    onChanged: _handle,
                    onTap: _showPinKeyboard,
                  ),
                  if (!widget.create && _biometricAvailable) ...[
                    const SizedBox(height: 20),
                    TextButton.icon(
                      onPressed: _biometricRunning || _checking
                          ? null
                          : () => _authenticateBiometrically(showFailure: true),
                      icon: _biometricRunning
                          ? const SizedBox(
                              width: 19,
                              height: 19,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.fingerprint_rounded),
                      label: Text(s.t('useBiometrics')),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryDark,
                        textStyle: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
          if (_openingApp)
            Positioned.fill(child: _OpeningOverlay(text: s.t('openingApp'))),
        ],
      ),
    );
  }
}

class _OpeningOverlay extends StatelessWidget {
  const _OpeningOverlay({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: (dark ? AppColors.darkBackground : AppColors.background)
          .withValues(alpha: .97),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 82,
                height: 82,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
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

class _PinCodeFields extends StatelessWidget {
  const _PinCodeFields({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 262,
      height: 62,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: Listenable.merge([controller, focusNode]),
                builder: (context, _) {
                  final length = controller.text.length;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final filled = index < length;
                      final active =
                          focusNode.hasFocus &&
                          (index == length || (length == 4 && index == 3));
                      return Padding(
                        padding: EdgeInsets.only(right: index == 3 ? 0 : 10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          width: 58,
                          height: 62,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: filled
                                ? AppColors.primary.withValues(alpha: .10)
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: active || filled
                                  ? AppColors.primary
                                  : Theme.of(context)
                                        .colorScheme
                                        .outlineVariant,
                              width: active ? 2 : 1.2,
                            ),
                            boxShadow: active
                                ? const [
                                    BoxShadow(
                                      color: Color(0x2922A96F),
                                      blurRadius: 16,
                                    ),
                                  ]
                                : null,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 140),
                            child: filled
                                ? const Text(
                                    '●',
                                    key: ValueKey('filled'),
                                    style: TextStyle(
                                      color: AppColors.primaryDark,
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  )
                                : SizedBox(key: ValueKey('empty-$index')),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: .01,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                keyboardType: TextInputType.number,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                enableInteractiveSelection: false,
                showCursor: false,
                style: const TextStyle(color: Colors.transparent),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                onTap: onTap,
                onChanged: onChanged,
                decoration: const InputDecoration.collapsed(hintText: ''),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinActionButton extends StatelessWidget {
  const _PinActionButton({
    required this.tooltip,
    required this.loading,
    required this.icon,
    required this.onPressed,
    this.foregroundColor = AppColors.primaryDark,
  });

  final String tooltip;
  final bool loading;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        backgroundColor: AppColors.primary.withValues(alpha: .10),
        foregroundColor: foregroundColor,
      ),
      icon: loading
          ? const SizedBox(
              width: 19,
              height: 19,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
    );
  }
}
