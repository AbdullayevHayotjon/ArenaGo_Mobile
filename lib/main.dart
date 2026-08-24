import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'controllers/app_controller.dart';
import 'services/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.error(
      'FLUTTER',
      details.exception,
      details.stack ?? StackTrace.current,
    );
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    AppLogger.error('ASYNC', error, stackTrace);
    return false;
  };
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final controller = AppController();
  await controller.initialize();
  runApp(ArenaGoApp(controller: controller));
}
