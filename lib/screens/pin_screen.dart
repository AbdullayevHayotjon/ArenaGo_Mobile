import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/arena_logo.dart';
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
  String? _firstPin;
  String? _error;
  bool _checking = false;

  @override
  void dispose() {
    _pin.dispose();
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
          _error = null;
          _checking = false;
        });
      } else if (_firstPin != value) {
        setState(() {
          _firstPin = null;
          _pin.clear();
          _error = widget.controller.strings.t('pinMismatch');
          _checking = false;
        });
      } else {
        await widget.controller.createPin(value);
      }
    } else {
      final valid = await widget.controller.unlock(value);
      if (mounted && !valid) {
        setState(() {
          _pin.clear();
          _error = widget.controller.strings.t('pinWrong');
          _checking = false;
        });
      }
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const ArenaLogo(size: 38),
                  PreferenceButtons(controller: widget.controller),
                ],
              ),
              const Spacer(),
              Container(
                width: 92,
                height: 92,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: Image.asset('assets/images/logo.png'),
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
              SizedBox(
                width: 210,
                child: TextField(
                  controller: _pin,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  obscuringCharacter: '●',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 25,
                    letterSpacing: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  onChanged: _handle,
                  decoration: const InputDecoration(
                    counterText: '',
                    contentPadding: EdgeInsets.only(
                      left: 20,
                      top: 17,
                      bottom: 17,
                    ),
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _error == null
                    ? const SizedBox(height: 43)
                    : Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text(
                          _error!,
                          key: ValueKey(_error),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
              if (!widget.create)
                TextButton.icon(
                  onPressed: widget.controller.logout,
                  icon: const Icon(Icons.logout, size: 18),
                  label: Text(s.t('logout')),
                ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
