import 'dart:math' as math;

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
                      const ArenaLogo(size: 38, animate: true),
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

class _PitchHero extends StatefulWidget {
  const _PitchHero();

  @override
  State<_PitchHero> createState() => _PitchHeroState();
}

class _PitchHeroState extends State<_PitchHero> with TickerProviderStateMixin {
  late final AnimationController _centerFloat = _repeatingController(
    const Duration(milliseconds: 3200),
  );
  late final AnimationController _centerSpin = _repeatingController(
    const Duration(seconds: 8),
  );
  late final AnimationController _firstBall = _repeatingController(
    const Duration(seconds: 7),
  );
  late final AnimationController _secondBall = _repeatingController(
    const Duration(seconds: 9),
  );

  AnimationController _repeatingController(Duration duration) {
    return AnimationController(vsync: this, duration: duration)..repeat();
  }

  List<AnimationController> get _controllers => [
    _centerFloat,
    _centerSpin,
    _firstBall,
    _secondBall,
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final controller in _controllers) {
      if (MediaQuery.of(context).disableAnimations) {
        controller
          ..stop()
          ..value = 0;
      } else if (!controller.isAnimating) {
        controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

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
      clipBehavior: Clip.hardEdge,
      child: LayoutBuilder(
        builder: (context, constraints) => AnimatedBuilder(
          animation: Listenable.merge(_controllers),
          builder: (context, _) {
            final floatPhase = math.sin(math.pi * _centerFloat.value);
            final first = _sampleMotion(_firstBall.value, const [
              _BallFrame(Offset.zero, 0),
              _BallFrame(Offset(65, 35), 160 / 360),
              _BallFrame(Offset(125, -15), 330 / 360),
              _BallFrame(Offset(205, 45), 520 / 360),
              _BallFrame(Offset.zero, 0),
            ]);
            final second = _sampleMotion(_secondBall.value, const [
              _BallFrame(Offset.zero, 0),
              _BallFrame(Offset(-155, 12), -420 / 360),
              _BallFrame(Offset(-75, -45), -210 / 360),
              _BallFrame(Offset.zero, 0),
            ]);

            return Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(child: CustomPaint(painter: _PitchPainter())),
                Positioned(
                  left: constraints.maxWidth * .08,
                  top: constraints.maxHeight * .30,
                  child: _MovingBall(size: 28, frame: first),
                ),
                Positioned(
                  right: constraints.maxWidth * .10,
                  bottom: constraints.maxHeight * .18,
                  child: _MovingBall(size: 20, frame: second),
                ),
                Transform.translate(
                  offset: Offset(0, -9 * floatPhase),
                  child: Transform.scale(
                    scale: 1 + (.04 * floatPhase),
                    child: Transform.rotate(
                      angle: _centerSpin.value * (350 / 360) * math.pi * 2,
                      child: Container(
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
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  _BallFrame _sampleMotion(double progress, List<_BallFrame> frames) {
    final segmentCount = frames.length - 1;
    final scaled = progress * segmentCount;
    final index = scaled.floor().clamp(0, segmentCount - 1);
    final localProgress = Curves.easeInOut.transform(scaled - index);
    return _BallFrame.lerp(frames[index], frames[index + 1], localProgress);
  }
}

class _MovingBall extends StatelessWidget {
  const _MovingBall({required this.size, required this.frame});

  final double size;
  final _BallFrame frame;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: frame.offset,
      child: Transform.rotate(
        angle: frame.turns * math.pi * 2,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 8,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Image.asset('assets/images/logo.png'),
        ),
      ),
    );
  }
}

class _BallFrame {
  const _BallFrame(this.offset, this.turns);

  final Offset offset;
  final double turns;

  static _BallFrame lerp(_BallFrame begin, _BallFrame end, double t) {
    return _BallFrame(
      Offset.lerp(begin.offset, end.offset, t)!,
      begin.turns + ((end.turns - begin.turns) * t),
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
