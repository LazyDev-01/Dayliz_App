import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Google Places API service with built-in cost controls
class GooglePlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  static String get _apiKey => ApiConfig.googlePlacesApiKey;

  // Cost control settings from configuration
  static int get _maxRequestsPerMinute => ApiConfig.placesApiLimits['maxRequestsPerMinute']!;
  static int get _maxRequestsPerHour => ApiConfig.placesApiLimits['maxRequestsPerHour']!;
  static int get _maxRequestsPerDay => ApiConfig.placesApiLimits['maxRequestsPerDay']!;
  static const Duration _cacheDuration = Duration(hours: 1); // Cache results

  // Rate limiting
  static final List<DateTime> _requestTimes = [];
  static final Map<String, _CachedResult> _cache = {};

  /// Search for places with cost controls
  static Future<List<Map<String, dynamic>>> searchPlaces({
    required String query,
    String? region,
    String? language,
  }) async {
    try {
      // Input validation
      if (query.trim().isEmpty || query.length < 2) {
        debugPrint('🚫 [Places] Query too short, skipping API call');
        return [];
      }

      // API key validation
      if (!ApiConfig.isGooglePlacesConfigured) {
        debugPrint('⚠️ [Places] API key not configured, using fallback');
        return _getFallbackResults(query);
      }

      // Use default values from config
      region ??= ApiConfig.defaultRegion;
      language ??= ApiConfig.defaultLanguage;

      // Check cache first (save money!)
      final cacheKey = '${query.toLowerCase()}_${region}_$language';
      if (_cache.containsKey(cacheKey)) {
        final cached = _cache[cacheKey]!;
        if (DateTime.now().difference(cached.timestamp) < _cacheDuration) {
          debugPrint('💰 [Places] Using cached result for "$query"');
          return cached.results;
        } else {
          _cache.remove(cacheKey); // Remove expired cache
        }
      }

      // Rate limiting check
      if (!_canMakeRequest()) {
        debugPrint('🚫 [Places] Rate limit exceeded, using fallback');
        return _getFallbackResults(query);
      }

      // Make API request
      debugPrint('📡 [Places] Making API request for "$query"');
      final results = await _makeApiRequest(query, region, language);

      // Cache the results
      _cache[cacheKey] = _CachedResult(
        results: results,
        timestamp: DateTime.now(),
      );

      // Clean old cache entries
      _cleanCache();

      return results;

    } catch (e) {
      debugPrint('❌ [Places] API error: $e');
      return _getFallbackResults(query);
    }
  }

  /// Check if we can make a request (rate limiting)
  static bool _canMakeRequest() {
    final now = DateTime.now();

    // Remove old requests
    _requestTimes.removeWhere((time) =>
        now.difference(time) > const Duration(days: 1));

    // Check limits
    final lastMinute = _requestTimes.where((time) =>
        now.difference(time) < const Duration(minutes: 1)).length;
    final lastHour = _requestTimes.where((time) =>
        now.difference(time) < const Duration(hours: 1)).length;
    final lastDay = _requestTimes.where((time) =>
        now.difference(time) < const Duration(days: 1)).length;

    if (lastMinute >= _maxRequestsPerMinute) {
      debugPrint('🚫 [Places] Rate limit: $lastMinute requests in last minute');
      return false;
    }

    if (lastHour >= _maxRequestsPerHour) {
      debugPrint('🚫 [Places] Rate limit: $lastHour requests in last hour');
      return false;
    }

    if (lastDay >= _maxRequestsPerDay) {
      debugPrint('🚫 [Places] Rate limit: $lastDay requests in last day');
      return false;
    }

    return true;
  }

  /// Make the actual API request
  static Future<List<Map<String, dynamic>>> _makeApiRequest(
    String query,
    String? region,
    String? language,
  ) async {
    // Record request time
    _requestTimes.add(DateTime.now());

    // Build URL with cost-optimized parameters
    final url = Uri.parse('$_baseUrl/textsearch/json').replace(
      queryParameters: {
        'query': query,
        'key': _apiKey,
        if (region != null) 'region': region,
        if (language != null) 'language': language,
        'fields': 'place_id,name,formatted_address,geometry', // Only essential fields
        'type': 'establishment', // Reduce irrelevant results
      },
    );

    final response = await http.get(url).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('API request timed out'),
    );

    if (response.statusCode != 200) {
      throw Exception('API request failed: ${response.statusCode}');
    }

    final data = json.decode(response.body);

    if (data['status'] != 'OK') {
      if (data['status'] == 'OVER_QUERY_LIMIT') {
        debugPrint('💸 [Places] API quota exceeded!');
      }
      throw Exception('API error: ${data['status']}');
    }

    // Parse results
    final results = <Map<String, dynamic>>[];
    for (final place in data['results'] ?? []) {
      final geometry = place['geometry']?['location'];
      if (geometry != null) {
        results.add({
          'place_id': place['place_id'] ?? '',
          'name': place['name'] ?? '',
          'formatted_address': place['formatted_address'] ?? '',
          'lat': geometry['lat']?.toDouble() ?? 0.0,
          'lng': geometry['lng']?.toDouble() ?? 0.0,
          'types': List<String>.from(place['types'] ?? []),
        });
      }
    }

    debugPrint('✅ [Places] Found ${results.length} results for "$query"');
    return results;
  }

  /// Get fallback results when API is unavailable
  static List<Map<String, dynamic>> _getFallbackResults(String query) {
    // Return local/cached results for common areas
    final fallbackResults = <Map<String, dynamic>>[];

    // Add some common Tura locations as fallback
    if (query.toLowerCase().contains('tura') ||
        query.toLowerCase().contains('meghalaya')) {
      fallbackResults.addAll([
        {
          'place_id': 'fallback_tura_main_bazaar',
          'name': 'Main Bazaar, Tura',
          'formatted_address': 'Main Bazaar, Tura, Meghalaya 794001, India',
          'lat': 25.5138,
          'lng': 90.2065,
          'types': ['establishment'],
        },
        {
          'place_id': 'fallback_tura_civil_hospital',
          'name': 'Civil Hospital, Tura',
          'formatted_address': 'Civil Hospital Road, Tura, Meghalaya 794001, India',
          'lat': 25.5145,
          'lng': 90.2070,
          'types': ['hospital'],
        },
      ]);
    }

    debugPrint('🔄 [Places] Using ${fallbackResults.length} fallback results');
    return fallbackResults;
  }

  /// Clean old cache entries
  static void _cleanCache() {
    final now = DateTime.now();
    _cache.removeWhere((key, value) =>
        now.difference(value.timestamp) > _cacheDuration);
  }

  /// Get current usage statistics
  static Map<String, int> getUsageStats() {
    final now = DateTime.now();
    return {
      'requests_last_minute': _requestTimes.where((time) =>
          now.difference(time) < const Duration(minutes: 1)).length,
      'requests_last_hour': _requestTimes.where((time) =>
          now.difference(time) < const Duration(hours: 1)).length,
      'requests_last_day': _requestTimes.where((time) =>
          now.difference(time) < const Duration(days: 1)).length,
      'cache_entries': _cache.length,
    };
  }
}

/// Cached result structure
class _CachedResult {
  final List<Map<String, dynamic>> results;
  final DateTime timestamp;

  _CachedResult({
    required this.results,
    required this.timestamp,
  });
}
