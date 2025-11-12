// lib/services/web_download_helper_stub.dart
// Stub for non-web platforms

/// Trigger a file download (stub - not available on this platform)
void downloadFile(String jsonString, String filename) {
  throw UnsupportedError('Web downloads are only available on web platform');
}
