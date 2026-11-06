/// RFC4180 CSV with formula-injection protection for user-entered text.
String reportCsv(List<List<Object?>> rows) => rows
    .map(
      (row) => row
          .map((value) {
            var text = value?.toString() ?? '';
            if (value is String && RegExp(r'^[\s]*[=+@\-]').hasMatch(text)) {
              text = "'$text";
            }
            return '"${text.replaceAll('"', '""')}"';
          })
          .join(','),
    )
    .join('\r\n');
