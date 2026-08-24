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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensurePinKeyboardIsVisible();
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
        await widget.controller.createPin(value);
        if (mounted) {
          AppToast.success(context, widget.controller.strings.t('pinCreated'));
        }
      }
    } else {
      final valid = await widget.controller.unlock(value);
      if (mounted && !valid) {
        setState(() {
          _pin.clear();
          _checking = false;
        });
        AppToast.error(context, widget.controller.strings.t('pinWrong'));
      } else if (mounted) {
        AppToast.success(context, widget.controller.strings.t('loginSuccess'));
      }
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
      body: SafeArea(
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
                      onPressed: widget.controller.logoutBusy ? null : _logout,
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
                      onPressed: widget.controller.logoutBusy ? null : _logout,
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
              const SizedBox(height: 28),
              const Spacer(flex: 2),
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
