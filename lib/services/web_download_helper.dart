// lib/services/web_download_helper.dart
// Web-specific file download functionality

import 'dart:convert';
import 'dart:html' as html;

/// Trigger a file download in the web browser
void downloadFile(String jsonString, String filename) {
  final bytes = utf8.encode(jsonString);
  final blob = html.Blob([bytes], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
