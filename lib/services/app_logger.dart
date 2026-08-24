import 'package:flutter/foundation.dart';

abstract final class AppLogger {
  static void error(String area, Object error, StackTrace stackTrace) {
    if (!kDebugMode) return;

    debugPrint('[$area ERROR] $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
