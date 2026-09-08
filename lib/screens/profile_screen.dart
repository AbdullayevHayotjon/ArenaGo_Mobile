import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/app_controller.dart';
import '../services/api_config.dart';
import '../services/telegram_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_toast.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.controller});

  final AppController controller;

  Future<void> _logout(BuildContext context) async {
    final successMessage = controller.strings.t('logoutSuccess');
    final error = await controller.logout();
    if (error != null) {
      if (context.mounted) AppToast.error(context, error);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppToast.successFromRoot(successMessage);
    });
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    try {
      final opened = await launchUrl(
        Uri.parse(privacyPolicyUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        AppToast.error(context, controller.strings.t('privacyPolicyOpenError'));
      }
    } catch (_) {
      if (context.mounted) {
        AppToast.error(context, controller.strings.t('privacyPolicyOpenError'));
      }
    }
  }

  Future<void> _openBotCommand(BuildContext context, String command) async {
    final opened = await TelegramService.openBot(draftText: command);
    if (!opened && context.mounted) {
      AppToast.error(context, controller.strings.t('telegramOpenError'));
    }
  }

  Future<void> _confirmAccountDeletion(BuildContext context) async {
    final s = controller.strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.delete_forever_outlined,
          color: AppColors.danger,
          size: 34,
        ),
        title: Text(s.t('deleteAccountConfirmTitle')),
        content: Text(s.t('deleteAccountConfirmText')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(s.t('cancel')),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.telegram_rounded),
            label: Text(s.t('continueToTelegram')),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _openBotCommand(context, '/deleteaccount');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = controller.strings;
    final session = controller.session;
    final name = session?.firstName.trim() ?? '';
    final initial = name.isEmpty ? 'A' : name.characters.first.toUpperCase();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 126),
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.person_rounded,
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
                      s.t('profileTitle'),
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.7,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.t('profileSubtitle'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _ProfileCard(
            initial: initial,
            name: name.isEmpty ? '—' : name,
            phoneNumber: session?.phoneNumber ?? '',
          ),
          const SizedBox(height: 26),
          _SectionTitle(title: s.t('personalInfo')),
          const SizedBox(height: 10),
          _SurfaceCard(
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.person_outline_rounded,
                  label: s.t('fullName'),
                  value: name.isEmpty ? '—' : name,
                ),
                const _CardDivider(),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: s.t('phone'),
                  value: session?.phoneNumber ?? '—',
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          _SectionTitle(title: s.t('accountSecurity')),
          const SizedBox(height: 10),
          _SurfaceCard(
            child: Column(
              children: [
                _ActionSetting(
                  icon: Icons.lock_reset_rounded,
                  title: s.t('changePassword'),
                  subtitle: s.t('changePasswordSubtitle'),
                  onTap: () => _openBotCommand(context, '/reset'),
                ),
                const _CardDivider(),
                _ActionSetting(
                  icon: Icons.delete_forever_outlined,
                  title: s.t('deleteAccount'),
                  subtitle: s.t('deleteAccountSubtitle'),
                  danger: true,
                  onTap: () => _confirmAccountDeletion(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          _SectionTitle(title: s.t('settings')),
          const SizedBox(height: 10),
          _SurfaceCard(
            child: Column(
              children: [
                _ThemeSetting(controller: controller),
                const _CardDivider(),
                _LanguageSetting(controller: controller),
                const _CardDivider(),
                _ActionSetting(
                  icon: Icons.privacy_tip_outlined,
                  title: s.t('privacyPolicy'),
                  subtitle: s.t('privacyPolicySubtitle'),
                  onTap: () => _openPrivacyPolicy(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          OutlinedButton.icon(
            onPressed: controller.logoutBusy ? null : () => _logout(context),
            icon: controller.logoutBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_rounded),
            label: Text(s.t(controller.logoutBusy ? 'loggingOut' : 'logout')),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              foregroundColor: AppColors.danger,
              side: BorderSide(color: AppColors.danger.withValues(alpha: .55)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 26),
          Center(
            child: Text(
              'ArenaGo  •  v${controller.appVersion}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant
                    .withValues(alpha: .72),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: .25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.initial,
    required this.name,
    required this.phoneNumber,
  });

  final String initial;
  final String name;
  final String phoneNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
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
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -45,
            top: -55,
            child: _DecorativeCircle(size: 150),
          ),
          const Positioned(
            right: 52,
            bottom: -60,
            child: _DecorativeCircle(size: 110),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .55),
                      width: 3,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Color(0x33000000), blurRadius: 16),
                    ],
                  ),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phoneNumber,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .76),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .055),
        shape: BoxShape.circle,
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
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant
              .withValues(alpha: dark ? .28 : .55),
        ),
        boxShadow: dark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0D17231E),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: child,
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 54,
      color: Theme.of(context).colorScheme.outlineVariant
          .withValues(alpha: .45),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          _SettingIcon(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeSetting extends StatelessWidget {
  const _ThemeSetting({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final s = controller.strings;
    final dark = controller.themeMode == ThemeMode.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _SettingIcon(
            icon: dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.t('theme'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  s.t(dark ? 'darkMode' : 'lightMode'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: dark,
            activeTrackColor: AppColors.primary,
            onChanged: (_) => controller.toggleTheme(),
          ),
        ],
      ),
    );
  }
}

class _ActionSetting extends StatelessWidget {
  const _ActionSetting({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            _SettingIcon(icon: icon, color: danger ? AppColors.danger : null),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: danger ? AppColors.danger : null,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new_rounded,
              color: danger
                  ? AppColors.danger
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 19,
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageSetting extends StatelessWidget {
  const _LanguageSetting({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final s = controller.strings;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const _SettingIcon(icon: Icons.language_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.t('language'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  s.t('languageSubtitle'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _LanguageSelector(controller: controller),
        ],
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['uz', 'ru'].map((language) {
          final selected = controller.language == language;
          return GestureDetector(
            onTap: () => controller.setLanguage(language),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                language.toUpperCase(),
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SettingIcon extends StatelessWidget {
  const _SettingIcon({required this.icon, this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: (color ?? AppColors.primary).withValues(alpha: .10),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color ?? AppColors.primary, size: 21),
    );
  }
}
