import 'package:flutter/services.dart';

Future<void> exportReport(String filename, String content) =>
    Clipboard.setData(ClipboardData(text: content));
