// lib/services/model_download_service.dart
// Service to download and manage Gemma 3-1B-IT model for on-device inference

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'debug_service.dart';
import 'storage_service.dart';

enum ModelDownloadStatus {
  notDownloaded,
  downloading,
  downloaded,
  failed,
}

class ModelDownloadProgress {
  final int bytesReceived;
  final int totalBytes;
  final double progress; // 0.0 to 1.0

  ModelDownloadProgress({
    required this.bytesReceived,
    required this.totalBytes,
  }) : progress = totalBytes > 0 ? bytesReceived / totalBytes : 0.0;

  int get megabytesReceived => (bytesReceived / (1024 * 1024)).round();
  int get totalMegabytes => (totalBytes / (1024 * 1024)).round();
}

/// Service for downloading and managing AI models.
///
/// **SINGLETON**: This class implements the singleton pattern to ensure only one
/// instance exists across the application. This prevents multiple concurrent
/// downloads of the same model file, which would cause file corruption and
/// wasted bandwidth.
///
/// **Thread Safety**: The singleton pattern combined with Dart's single-threaded
/// event loop ensures that download operations are properly synchronized.
/// Multiple calls to [downloadModel] will return the same Future if a download
/// is already in progress.
///
/// Usage:
/// ```dart
/// final service = ModelDownloadService(); // Always returns the same instance
/// await service.downloadModel();
/// ```
class ModelDownloadService {
  // Singleton implementation
  static final ModelDownloadService _instance = ModelDownloadService._internal();

  /// Factory constructor that always returns the same singleton instance.
  /// This ensures only one ModelDownloadService exists in the application.
  factory ModelDownloadService() => _instance;

  /// Private constructor for singleton pattern.
  ModelDownloadService._internal();

  final DebugService _debug = DebugService();
  final StorageService _storage = StorageService();

  // Hugging Face model URL (Gemma 3-1B-IT INT4 quantized)
  // LiteRT .task files include both model and tokenization built-in!
  // Model: Gemma 3-1B-IT, INT4 quantized (multi-prefill-seq_q4_ekv2048)
  // Size: 554.6 MB (optimized for on-device inference)
  // License: Gemma Terms of Use (open for research and commercial use with attribution)
  //
  // IMPORTANT: Model is GATED and requires HuggingFace authentication
  // User must:
  // 1. Create account at https://huggingface.co/join
  // 2. Accept license at https://huggingface.co/litert-community/Gemma3-1B-IT
  // 3. Generate token at https://huggingface.co/settings/tokens (Read access)
  // 4. Enter token in app's AI Settings screen
  //
  // WHY THIS MODEL?
  // - This is the EXACT model used by Google's official AI Edge Gallery demo
  // - Compatible with LiteRT LLM library (NOT the old MediaPipe API)
  // - TinyLlama and older models crash with MediaPipe - this works!
  // - Officially supported by Google's LiteRT team
  //
  // LIBRARY CHANGE:
  // - Switched from com.google.mediapipe:tasks-genai to com.google.ai.edge.litertlm
  // - New API: Engine/Conversation instead of LlmInference
  //
  // Available .task files from HF repo:
  // - Gemma3-1B-IT_multi-prefill-seq_q4_ekv2048.task (554.6 MB) ← Using this! (Google's demo)
  // - gemma3-1b-it-int4.task (555 MB INT4)
  // - gemma3-1b-it-int4-web.task (700 MB INT4 for web)
  static const String _modelUrl =
      'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/Gemma3-1B-IT_multi-prefill-seq_q4_ekv2048.task?download=true';

  static const String _modelFileName = 'Gemma3-1B-IT_multi-prefill-seq_q4_ekv2048.task';

  ModelDownloadStatus _status = ModelDownloadStatus.notDownloaded;
  ModelDownloadProgress? _progress;
  String? _errorMessage;
  Future<bool>? _downloadFuture; // Keep download future alive
  Function(ModelDownloadProgress)? _currentProgressCallback; // Store current callback

  ModelDownloadStatus get status => _status;
  ModelDownloadProgress? get progress => _progress;
  String? get errorMessage => _errorMessage;

  /// Check if model is already downloaded
  Future<bool> isModelDownloaded() async {
    try {
      final modelFile = await _getModelFile();
      final exists = await modelFile.exists();

      // Update status based on file existence
      if (exists) {
        // File exists - mark as downloaded
        _status = ModelDownloadStatus.downloaded;
        await _debug.info('ModelDownloadService', 'Model found on device', metadata: {
          'path': modelFile.path,
          'size': await modelFile.length(),
        });
      } else if (_status != ModelDownloadStatus.downloading) {
        // File doesn't exist and not currently downloading
        _status = ModelDownloadStatus.notDownloaded;
      }

      return exists;
    } catch (e, stackTrace) {
      await _debug.error(
        'ModelDownloadService',
        'Error checking model: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      return false;
    }
  }

  /// Get model file path (.task file)
  Future<File> _getModelFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${directory.path}/models');

    // Create models directory if it doesn't exist
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }

    return File('${modelsDir.path}/$_modelFileName');
  }

  /// Get model file path (for use in native code)
  Future<String> getModelPath() async {
    final file = await _getModelFile();
    return file.path;
  }

  /// Set or clear the progress callback for an ongoing download
  /// This allows UI to reconnect to a background download
  void setProgressCallback(Function(ModelDownloadProgress)? callback) {
    _currentProgressCallback = callback;
  }

  /// Download the Gemma 3-1B-IT model with progress tracking
  /// Downloads a single .task file (554.6 MB) that includes model + tokenization
  ///
  /// Requires HuggingFace token for authentication (gated model).
  /// Token is loaded from settings automatically.
  ///
  /// **CONCURRENCY PROTECTION**: If a download is already in progress, this method
  /// will NOT start a new download. Instead, it will:
  /// 1. Update the progress callback to the new one (if provided)
  /// 2. Return the existing download Future
  ///
  /// This prevents multiple simultaneous downloads that would:
  /// - Corrupt the model file (multiple writes to same file)
  /// - Waste bandwidth (downloading the same 554 MB file multiple times)
  /// - Cause race conditions in file system operations
  ///
  /// The download continues in the background even if the calling widget is disposed,
  /// allowing users to navigate away and return later to check progress.
  Future<bool> downloadModel({
    Function(ModelDownloadProgress)? onProgress,
  }) async {
    // Update the progress callback (allows reconnecting after screen disposal)
    _currentProgressCallback = onProgress;

    // CRITICAL: Check if download is already in progress
    // This prevents multiple concurrent downloads to the same file
    if (_downloadFuture != null && _status == ModelDownloadStatus.downloading) {
      await _debug.info(
        'ModelDownloadService',
        'Download already in progress, returning existing future',
        metadata: {
          'currentProgress': _progress?.progress,
          'bytesReceived': _progress?.megabytesReceived,
        },
      );
      return _downloadFuture!;
    }

    // Store the download future to keep it alive even if caller disposes
    // This future is shared across all callers until download completes
    _downloadFuture = _performDownload();
    return _downloadFuture!;
  }

  /// Internal method that performs the actual download.
  ///
  /// **IMPORTANT**: This method sets [_status] to [ModelDownloadStatus.downloading]
  /// IMMEDIATELY (synchronously) at the start, before any await. This ensures that
  /// any subsequent calls to [downloadModel] will detect the in-progress download
  /// and return the same Future, preventing concurrent downloads.
  Future<bool> _performDownload() async {
    try {
      // Set status IMMEDIATELY (synchronously) to prevent concurrent downloads
      _status = ModelDownloadStatus.downloading;
      _errorMessage = null;

      // Load HuggingFace token from settings
      final settings = await _storage.loadSettings();
      final hfToken = settings['huggingfaceToken'] as String?;

      if (hfToken == null || hfToken.isEmpty) {
        throw Exception('HuggingFace token is required. Please enter your token in AI Settings.');
      }

      // Enable wake lock to prevent phone from sleeping during download
      await WakelockPlus.enable();
      await _debug.info('ModelDownloadService', 'Wake lock enabled for download');

      await _debug.info('ModelDownloadService', 'Starting model download', metadata: {
        'url': _modelUrl,
        'fileName': _modelFileName,
        'hasToken': hfToken.isNotEmpty,
      });

      final modelFile = await _getModelFile();

      // If file already exists, delete it first
      if (await modelFile.exists()) {
        await modelFile.delete();
      }

      // Create HTTP client
      final client = http.Client();

      try {
        // Download the .task file with progress tracking
        await _debug.info('ModelDownloadService', 'Downloading Gemma 3-1B-IT model (554.6 MB)...');

        final request = http.Request('GET', Uri.parse(_modelUrl));

        // Add HuggingFace token for authentication
        request.headers['Authorization'] = 'Bearer $hfToken';

        final response = await client.send(request);

        if (response.statusCode != 200) {
          // Provide helpful error messages for common authentication issues
          if (response.statusCode == 401 || response.statusCode == 403) {
            throw Exception(
              'Authentication failed (HTTP ${response.statusCode}). '
              'Please check:\n'
              '1. Your HuggingFace token is valid\n'
              '2. You accepted the license at huggingface.co/litert-community/Gemma3-1B-IT\n'
              '3. Token has "Read" access'
            );
          }
          throw Exception('Failed to download model: HTTP ${response.statusCode}');
        }

        final totalBytes = response.contentLength ?? 0;
        int bytesReceived = 0;

        // Open file for writing
        final sink = modelFile.openWrite();

        // Download with progress tracking
        await for (final chunk in response.stream) {
          sink.add(chunk);
          bytesReceived += chunk.length;

          // Update progress
          _progress = ModelDownloadProgress(
            bytesReceived: bytesReceived,
            totalBytes: totalBytes,
          );

          // Notify callback if one is currently registered
          if (_currentProgressCallback != null) {
            _currentProgressCallback!(_progress!);
          }

          // Log progress every 100 MB
          if (bytesReceived % (100 * 1024 * 1024) < chunk.length) {
            await _debug.info('ModelDownloadService', 'Download progress', metadata: {
              'bytesReceived': bytesReceived,
              'totalBytes': totalBytes,
              'progress': _progress!.progress,
            });
          }
        }

        await sink.close();

        // Verify file was written correctly
        final fileSize = await modelFile.length();
        if (fileSize == 0) {
          throw Exception('Downloaded file is empty');
        }

        await _debug.info('ModelDownloadService', 'Model downloaded successfully', metadata: {
          'path': modelFile.path,
          'size': fileSize,
          'sizeMB': (fileSize / (1024 * 1024)).round(),
        });

        _status = ModelDownloadStatus.downloaded;

        // Clear the future reference - allows new downloads to start
        _downloadFuture = null;
        _currentProgressCallback = null;

        // Disable wake lock after successful download
        await WakelockPlus.disable();
        await _debug.info('ModelDownloadService', 'Wake lock disabled after successful download');

        return true;
      } finally {
        client.close();
      }
    } catch (e, stackTrace) {
      _status = ModelDownloadStatus.failed;
      _errorMessage = e.toString();
      // Clear the future reference on failure - allows retry attempts
      _downloadFuture = null;
      _currentProgressCallback = null;

      // Disable wake lock after failed download
      try {
        await WakelockPlus.disable();
        await _debug.info('ModelDownloadService', 'Wake lock disabled after download failure');
      } catch (wakeError) {
        await _debug.error('ModelDownloadService', 'Failed to disable wake lock: $wakeError');
      }

      await _debug.error(
        'ModelDownloadService',
        'Model download failed: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );

      return false;
    }
  }

  /// Delete the downloaded model
  Future<bool> deleteModel() async {
    try {
      final modelFile = await _getModelFile();

      bool deleted = false;

      if (await modelFile.exists()) {
        await modelFile.delete();
        deleted = true;
      }

      if (deleted) {
        _status = ModelDownloadStatus.notDownloaded;
        _progress = null;
        await _debug.info('ModelDownloadService', 'Model deleted');
      }

      return deleted;
    } catch (e, stackTrace) {
      await _debug.error(
        'ModelDownloadService',
        'Failed to delete model: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );
      return false;
    }
  }

  /// Get model size info
  Future<int?> getModelSize() async {
    try {
      final modelFile = await _getModelFile();

      if (await modelFile.exists()) {
        return await modelFile.length();
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cancel ongoing download
  void cancelDownload() {
    // TODO: Implement download cancellation
    _status = ModelDownloadStatus.notDownloaded;
    _progress = null;
  }
}
