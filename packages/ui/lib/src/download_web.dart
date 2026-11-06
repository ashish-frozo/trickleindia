import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<void> exportReport(String filename, String content) async {
  final blob = web.Blob(
    [('\uFEFF$content').toJS].toJS,
    web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  final link = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;
  web.document.body!.append(link);
  link.click();
  link.remove();
  // Give the browser a task to start the download before revoking its object URL.
  Future<void>.delayed(
    const Duration(seconds: 1),
    () => web.URL.revokeObjectURL(url),
  );
}
