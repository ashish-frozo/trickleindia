import 'package:flutter/material.dart';
import 'package:pop_domain/pop_domain.dart';
import 'package:pop_ui/pop_ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController(
    MemoryStore(),
    const String.fromEnvironment(
      'API_URL',
      defaultValue: 'http://localhost:3000',
    ),
    portal: true,
  );
  await controller.init();
  runApp(PopApp(controller: controller));
}
