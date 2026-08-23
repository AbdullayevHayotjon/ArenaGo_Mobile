import 'package:flutter/material.dart';

import 'controllers/app_controller.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/pin_screen.dart';
import 'theme/app_theme.dart';

class ArenaGoApp extends StatelessWidget {
  const ArenaGoApp({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => MaterialApp(
        title: 'ArenaGo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: controller.themeMode,
        locale: Locale(controller.language),
        home: switch (controller.stage) {
          AppStage.login => LoginScreen(controller: controller),
          AppStage.createPin => PinScreen(controller: controller, create: true),
          AppStage.unlock => PinScreen(controller: controller, create: false),
          AppStage.home => HomeScreen(controller: controller),
        },
      ),
    );
  }
}
