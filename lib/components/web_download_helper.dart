// web_download_helper.dart
import 'dart:html' as html;

/// Basic anchor click (used in downloadFile)
void triggerSimpleWebDownload(String url, String fileName) {
  final anchor = html.AnchorElement(href: url)
    ..target = 'blank'
    ..download = fileName
    ..click();
  print("✅ Web download triggered.");
}

/// Append-click-remove anchor (used in openFileFromUrlWeb)
void triggerFullWebDownload(String url) {
  final anchor = html.AnchorElement(href: url)
    ..target = 'blank'
    ..download = url.split('/').last;
  html.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
}
