import 'package:flutter_test/flutter_test.dart';
import 'package:pop_ui/src/reports.dart';

void main() {
  test(
    'CSV escapes quoted multiline names and prevents spreadsheet formulas',
    () {
      final csv = reportCsv([
        ['Name', 'Balance'],
        ['A, "B"\nC', -123],
        [' =HYPERLINK("https://example.invalid")', 0],
        ['हिन्दी', null],
      ]);
      expect(csv, contains('"A, ""B""\nC","-123"'));
      expect(csv, contains('"\' =HYPERLINK(""https://example.invalid"")","0"'));
      expect(csv, endsWith('"हिन्दी",""'));
      expect(csv.split('\r\n'), hasLength(4));
    },
  );
}
