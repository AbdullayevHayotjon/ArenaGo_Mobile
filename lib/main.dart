import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'controllers/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final controller = AppController();
  await controller.initialize();
  runApp(ArenaGoApp(controller: controller));
}
