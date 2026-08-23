import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/arena_logo.dart';
import '../widgets/preference_buttons.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController(text: '+998 ');
  final _password = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 12 ||
        !digits.startsWith('998') ||
        _password.text.isEmpty) {
      _showError(widget.controller.strings.t('invalidForm'));
      return;
    }
    final error = await widget.controller.login(digits, _password.text);
    if (mounted && error != null) _showError(error);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.controller.strings;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 46,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const ArenaLogo(size: 38),
                      PreferenceButtons(controller: widget.controller),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const _PitchHero(),
                  const SizedBox(height: 30),
                  Text(
                    s.t('welcome'),
                    style: const TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.t('loginText'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    s.t('phone'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [_UzbekPhoneFormatter()],
                    autofillHints: const [AutofillHints.telephoneNumber],
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.phone_outlined),
                      hintText: '+998 90 123 45 67',
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    s.t('password'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _password,
                    obscureText: !_showPassword,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: widget.controller.busy ? null : _submit,
                    child: widget.controller.busy
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(s.t('loggingIn')),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(s.t('login')),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 19),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PitchHero extends StatelessWidget {
  const _PitchHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF06432C), Color(0xFF159461)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3322A96F),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: CustomPaint(painter: _PitchPainter())),
          Container(
            width: 84,
            height: 84,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .10),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: Color(0x4474EDB5), blurRadius: 35),
              ],
            ),
            child: Image.asset('assets/images/logo.png'),
          ),
        ],
      ),
    );
  }
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(14, 14, size.width - 28, size.height - 28),
        const Radius.circular(16),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(size.width / 2, 14),
      Offset(size.width / 2, size.height - 14),
      paint,
    );
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 42, paint);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(14, size.height / 2),
        width: 62,
        height: 76,
      ),
      paint,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width - 14, size.height / 2),
        width: 62,
        height: 76,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _UzbekPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('998')) digits = digits.substring(3);
    digits = digits.length > 9 ? digits.substring(0, 9) : digits;
    final parts = <String>[];
    if (digits.isNotEmpty) {
      parts.add(digits.substring(0, digits.length.clamp(0, 2)));
    }
    if (digits.length > 2) {
      parts.add(digits.substring(2, digits.length.clamp(2, 5)));
    }
    if (digits.length > 5) {
      parts.add(digits.substring(5, digits.length.clamp(5, 7)));
    }
    if (digits.length > 7) {
      parts.add(digits.substring(7, digits.length.clamp(7, 9)));
    }
    final text = '+998${parts.isEmpty ? ' ' : ' ${parts.join(' ')}'}';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
