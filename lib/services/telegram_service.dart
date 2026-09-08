import 'package:url_launcher/url_launcher.dart';

class TelegramService {
  const TelegramService._();

  static const botUsername = 'ArenaGoSportBot';

  static Future<bool> openBot({String? draftText}) async {
    final query = <String, String>{
      'domain': botUsername,
      if (draftText?.trim().isNotEmpty == true) 'text': draftText!.trim(),
    };
    final telegramApp = Uri(
      scheme: 'tg',
      host: 'resolve',
      queryParameters: query,
    );
    final telegramWeb = Uri.https(
      't.me',
      '/$botUsername',
      draftText?.trim().isNotEmpty == true ? {'text': draftText!.trim()} : null,
    );

    try {
      final opened = await launchUrl(
        telegramApp,
        mode: LaunchMode.externalNonBrowserApplication,
      );
      if (opened) return true;
    } catch (_) {
      // Telegram o‘rnatilmagan bo‘lsa, brauzerdagi havola sinaladi.
    }

    try {
      return await launchUrl(telegramWeb, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
