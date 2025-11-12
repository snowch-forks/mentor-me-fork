// lib/services/on_device_ai_service.dart
// Service to check for on-device AI capabilities (Gemini Nano, AICore, etc.)

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'debug_service.dart';

/// Holds information about on-device AI availability
class OnDeviceAIInfo {
  final bool isAICoreInstalled;
  final bool isGeminiNanoAvailable;
  final String? aicoreVersion;
  final String? errorMessage;
  final bool isSupported; // Whether device supports on-device AI at all
  final Map<String, dynamic>? additionalInfo;

  OnDeviceAIInfo({
    required this.isAICoreInstalled,
    required this.isGeminiNanoAvailable,
    this.aicoreVersion,
    this.errorMessage,
    required this.isSupported,
    this.additionalInfo,
  });

  bool get isAvailable => isAICoreInstalled && isGeminiNanoAvailable;

  @override
  String toString() {
    return 'OnDeviceAIInfo('
        'isAICoreInstalled: $isAICoreInstalled, '
        'isGeminiNanoAvailable: $isGeminiNanoAvailable, '
        'version: $aicoreVersion, '
        'isSupported: $isSupported)';
  }
}

/// Service to detect and interact with on-device AI capabilities
class OnDeviceAIService {
  static const MethodChannel _channel = MethodChannel('com.mentorme/on_device_ai');
  final DebugService _debug = DebugService();

  static final OnDeviceAIService _instance = OnDeviceAIService._internal();
  factory OnDeviceAIService() => _instance;
  OnDeviceAIService._internal();

  /// Check if on-device AI (Gemini Nano via AICore) is available
  Future<OnDeviceAIInfo> checkAvailability() async {
    // Web doesn't support on-device AI
    if (kIsWeb) {
      return OnDeviceAIInfo(
        isAICoreInstalled: false,
        isGeminiNanoAvailable: false,
        isSupported: false,
        errorMessage: 'Web platform does not support on-device AI',
      );
    }

    try {
      await _debug.info('OnDeviceAIService', 'Checking on-device AI availability');

      final result = await _channel.invokeMethod<Map<Object?, Object?>>('checkAvailability');

      if (result == null) {
        return OnDeviceAIInfo(
          isAICoreInstalled: false,
          isGeminiNanoAvailable: false,
          isSupported: false,
          errorMessage: 'Platform returned null result',
        );
      }

      // Convert additionalInfo from Map<Object?, Object?> to Map<String, dynamic>
      Map<String, dynamic>? additionalInfo;
      if (result['additionalInfo'] != null) {
        final rawAdditionalInfo = result['additionalInfo'] as Map<Object?, Object?>;
        additionalInfo = rawAdditionalInfo.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }

      final info = OnDeviceAIInfo(
        isAICoreInstalled: result['isAICoreInstalled'] as bool? ?? false,
        isGeminiNanoAvailable: result['isGeminiNanoAvailable'] as bool? ?? false,
        aicoreVersion: result['aicoreVersion'] as String?,
        isSupported: result['isSupported'] as bool? ?? true,
        errorMessage: result['errorMessage'] as String?,
        additionalInfo: additionalInfo,
      );

      await _debug.info('OnDeviceAIService', 'Availability check completed', metadata: {
        'isAICoreInstalled': info.isAICoreInstalled,
        'isGeminiNanoAvailable': info.isGeminiNanoAvailable,
        'version': info.aicoreVersion,
      });

      return info;
    } on PlatformException catch (e, stackTrace) {
      await _debug.error(
        'OnDeviceAIService',
        'Platform error checking availability: ${e.message}',
        stackTrace: stackTrace.toString(),
        metadata: {'code': e.code, 'message': e.message},
      );

      return OnDeviceAIInfo(
        isAICoreInstalled: false,
        isGeminiNanoAvailable: false,
        isSupported: false,
        errorMessage: 'Platform error: ${e.message}',
      );
    } catch (e, stackTrace) {
      await _debug.error(
        'OnDeviceAIService',
        'Error checking on-device AI availability: ${e.toString()}',
        stackTrace: stackTrace.toString(),
      );

      return OnDeviceAIInfo(
        isAICoreInstalled: false,
        isGeminiNanoAvailable: false,
        isSupported: false,
        errorMessage: 'Error: ${e.toString()}',
      );
    }
  }

  /// Test on-device AI with a simple prompt
  Future<String?> testInference(String prompt) async {
    if (kIsWeb) {
      return null;
    }

    try {
      final response = await _channel.invokeMethod<String>('testInference', {
        'prompt': prompt,
      });

      return response;
    } catch (e) {
      await _debug.warning(
        'OnDeviceAIService',
        'Failed to test inference',
        metadata: {'error': e.toString()},
      );
      return null;
    }
  }

  /// Request AICore download/installation (if supported)
  Future<bool> requestAICoreInstallation() async {
    if (kIsWeb) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('requestInstallation');
      return result ?? false;
    } catch (e) {
      await _debug.warning(
        'OnDeviceAIService',
        'Failed to request AICore installation',
        metadata: {'error': e.toString()},
      );
      return false;
    }
  }
}
