import 'package:flutter/material.dart';
import 'package:pop_domain/pop_domain.dart';
import 'package:pop_ui/pop_ui.dart';

import 'store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController(
    EncryptedStore(),
    const String.fromEnvironment(
      'API_URL',
      defaultValue: 'http://10.0.2.2:3000',
    ),
  );
  try {
    await controller.init();
    runApp(PopApp(controller: controller));
  } catch (_) {
    try {
      await controller.store.close();
    } catch (_) {}
    controller.dispose();
    runApp(SecureStartupFailure(onRetry: main));
  }
}
