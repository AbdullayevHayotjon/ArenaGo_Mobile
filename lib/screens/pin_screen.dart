import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/arena_logo.dart';
import '../widgets/app_toast.dart';
import '../widgets/floating_football.dart';
import '../widgets/preference_buttons.dart';

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const ArenaLogo(size: 38, animate: true),
                  PreferenceButtons(controller: widget.controller),
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
              ),
              const SizedBox(height: 28),
              if (!widget.create)
                TextButton.icon(
                  onPressed: widget.controller.logoutBusy ? null : _logout,
                  icon: widget.controller.logoutBusy
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.logout, size: 18),
                  label: Text(
                    s.t(widget.controller.logoutBusy ? 'loggingOut' : 'logout'),
                  ),
                ),
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
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRect(
          child: SizedBox(
            width: 1,
            height: 1,
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                keyboardType: TextInputType.number,
                enableInteractiveSelection: false,
                showCursor: false,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                onChanged: onChanged,
                decoration: const InputDecoration.collapsed(hintText: ''),
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        AnimatedBuilder(
          animation: Listenable.merge([controller, focusNode]),
          builder: (context, _) {
            final length = controller.text.length;
            return Semantics(
              label: '4-digit PIN',
              textField: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  focusNode.requestFocus();
                  controller.selection = TextSelection.collapsed(
                    offset: controller.text.length,
                  );
                  SystemChannels.textInput.invokeMethod<void>('TextInput.show');
                },
                child: Row(
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
                                : Theme.of(context).colorScheme.outlineVariant,
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
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
