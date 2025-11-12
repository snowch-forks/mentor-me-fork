// lib/utils/file_export_stub.dart
// Stub for non-web platforms

Future<void> downloadFile(String content, String filename, String mimeType) async {
  // Not supported on mobile - will use clipboard instead
  throw UnsupportedError('File download is only supported on web');
}
