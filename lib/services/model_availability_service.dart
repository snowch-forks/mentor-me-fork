// lib/services/model_availability_service.dart
// Service to check which Claude models are actually available

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'debug_service.dart';

class ModelInfo {
  final String id;
  final String displayName;
  final String description;
  final bool isAvailable;
  final String? errorMessage;

  ModelInfo({
    required this.id,
    required this.displayName,
    required this.description,
    this.isAvailable = true,
    this.errorMessage,
  });
}

class ModelAvailabilityService {
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String _proxyUrl = 'http://localhost:3000/api/claude/messages';

  final DebugService _debug = DebugService();

  // All possible models we want to support
  static final List<ModelInfo> allModels = [
    // Claude 4 Models (Current)
    ModelInfo(
      id: 'claude-sonnet-4-20250514',
      displayName: 'Sonnet 4.5 (Recommended)',
      description: 'Best balance of speed, cost, and intelligence',
    ),
    ModelInfo(
      id: 'claude-sonnet-4-20241022',
      displayName: 'Sonnet 4',
      description: 'Previous Sonnet 4 version',
    ),
    ModelInfo(
      id: 'claude-opus-4-20250514',
      displayName: 'Opus 4 (Most Powerful)',
      description: 'Highest intelligence, higher cost',
    ),
    
    // Claude 3.5 Models (Legacy)
    ModelInfo(
      id: 'claude-3-5-sonnet-20241022',
      displayName: '3.5 Sonnet (Legacy)',
      description: 'Previous generation model',
    ),
    ModelInfo(
      id: 'claude-3-5-haiku-20241022',
      displayName: '3.5 Haiku (Legacy)',
      description: 'Fastest legacy model',
    ),
  ];

  /// Check which models are actually available with the given API key
  Future<List<ModelInfo>> checkAvailableModels(String apiKey) async {
    await _debug.info('ModelAvailability', 'Starting model availability check for ${allModels.length} models');

    if (apiKey.isEmpty) {
      await _debug.warning('ModelAvailability', 'No API key configured, marking all models as unavailable');
      return allModels.map((m) => ModelInfo(
        id: m.id,
        displayName: m.displayName,
        description: m.description,
        isAvailable: false,
        errorMessage: 'No API key configured',
      )).toList();
    }

    final results = <ModelInfo>[];

    for (final model in allModels) {
      final isAvailable = await _testModel(model.id, apiKey);
      results.add(ModelInfo(
        id: model.id,
        displayName: model.displayName,
        description: model.description,
        isAvailable: isAvailable.isAvailable,
        errorMessage: isAvailable.errorMessage,
      ));
    }

    final availableCount = results.where((r) => r.isAvailable).length;
    await _debug.info(
      'ModelAvailability',
      'Model check complete: $availableCount/${results.length} available',
      metadata: {
        'available_models': results.where((r) => r.isAvailable).map((r) => r.id).toList().join(', '),
        'unavailable_models': results.where((r) => !r.isAvailable).map((r) => r.id).toList().join(', '),
      },
    );

    return results;
  }

  /// Test a single model with a minimal request
  Future<({bool isAvailable, String? errorMessage})> _testModel(
    String modelId,
    String apiKey,
  ) async {
    try {
      final url = kIsWeb ? _proxyUrl : _apiUrl;

      await _debug.debug('ModelAvailability', 'Testing model: $modelId at $url');

      final startTime = DateTime.now();

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: json.encode({
          'model': modelId,
          'max_tokens': 10,
          'messages': [
            {
              'role': 'user',
              'content': 'Hi',
            }
          ],
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout'),
      );

      final duration = DateTime.now().difference(startTime);

      if (response.statusCode == 200) {
        await _debug.info(
          'ModelAvailability',
          'Model $modelId is available',
          metadata: {
            'model': modelId,
            'duration_ms': duration.inMilliseconds,
            'status': 'available',
          },
        );
        return (isAvailable: true, errorMessage: null);
      } else if (response.statusCode == 404) {
        // Model not found
        final errorData = json.decode(response.body);
        if (errorData['error']?['type'] == 'not_found_error') {
          await _debug.warning(
            'ModelAvailability',
            'Model $modelId not found',
            metadata: {
              'model': modelId,
              'status_code': 404,
              'error_type': 'not_found_error',
            },
          );
          return (
            isAvailable: false,
            errorMessage: 'Model not available',
          );
        }
      } else if (response.statusCode == 401) {
        await _debug.error(
          'ModelAvailability',
          'Invalid API key when testing $modelId',
          metadata: {
            'model': modelId,
            'status_code': 401,
          },
        );
        return (
          isAvailable: false,
          errorMessage: 'Invalid API key',
        );
      }

      await _debug.warning(
        'ModelAvailability',
        'Unexpected status for $modelId: ${response.statusCode}',
        metadata: {
          'model': modelId,
          'status_code': response.statusCode,
          'response_body': response.body.substring(0, response.body.length > 200 ? 200 : response.body.length),
        },
      );

      return (
        isAvailable: false,
        errorMessage: 'Error ${response.statusCode}',
      );
    } catch (e, stackTrace) {
      // Detailed error logging for network failures
      final errorStr = e.toString();
      String errorCategory = 'unknown';
      String userMessage = 'Connection failed';

      if (errorStr.contains('Failed to fetch') || errorStr.contains('ClientException')) {
        errorCategory = 'proxy_connection';
        userMessage = kIsWeb
            ? 'Cannot connect to proxy server at localhost:3000'
            : 'Cannot connect to Claude API';
      } else if (errorStr.contains('Timeout')) {
        errorCategory = 'timeout';
        userMessage = 'Request timed out';
      } else if (errorStr.contains('Failed host lookup')) {
        errorCategory = 'dns_failure';
        userMessage = 'Network connection failed';
      }

      await _debug.error(
        'ModelAvailability',
        'Error testing model $modelId: $userMessage',
        metadata: {
          'model': modelId,
          'error_type': errorCategory,
          'error_message': errorStr,
          'platform': kIsWeb ? 'web' : 'mobile',
          'endpoint': kIsWeb ? _proxyUrl : _apiUrl,
        },
        stackTrace: stackTrace.toString(),
      );

      debugPrint('Error testing model $modelId: $e');
      return (
        isAvailable: false,
        errorMessage: userMessage,
      );
    }
  }

  /// Quick check if a specific model is available (for error handling)
  Future<bool> isModelAvailable(String modelId, String apiKey) async {
    final result = await _testModel(modelId, apiKey);
    return result.isAvailable;
  }

  /// Get recommended fallback model if current model is unavailable
  String getRecommendedFallback(String unavailableModelId) {
    // If Sonnet 4.5 is unavailable, try Sonnet 4
    if (unavailableModelId == 'claude-sonnet-4-20250514') {
      return 'claude-sonnet-4-20241022';
    }
    
    // If any Sonnet 4 is unavailable, try 3.5 Sonnet
    if (unavailableModelId.contains('sonnet-4')) {
      return 'claude-3-5-sonnet-20241022';
    }
    
    // If Opus is unavailable, try Sonnet 4.5
    if (unavailableModelId.contains('opus')) {
      return 'claude-sonnet-4-20250514';
    }
    
    // Default fallback
    return 'claude-3-5-sonnet-20241022';
  }

  /// Parse error from API response to determine if it's a model availability issue
  static bool isModelNotFoundError(String errorBody) {
    try {
      final data = json.decode(errorBody);
      return data['error']?['type'] == 'not_found_error' &&
             data['error']?['message']?.toString().toLowerCase().contains('model') == true;
    } catch (e) {
      return false;
    }
  }
}