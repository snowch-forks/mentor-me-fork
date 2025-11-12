// lib/utils/file_export.dart
// Platform-agnostic file export interface

export 'file_export_stub.dart'
    if (dart.library.html) 'file_export_web.dart';
