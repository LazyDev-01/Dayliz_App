import 'package:flutter/foundation.dart';
import '../../domain/entities/user_consent.dart';
import '../../domain/repositories/consent_repository.dart';

/// DPDP Act 2023 Compliant Consent Manager
/// 
/// This service manages user consent in compliance with the Digital Personal
/// Data Protection Act 2023. It provides a high-level interface for consent
/// operations while ensuring legal compliance and audit trail maintenance.
/// 
/// CRITICAL: This implementation must maintain strict compliance with DPDP Act 2023
/// requirements including consent granularity, withdrawal mechanisms, and audit trails.
class DPDPConsentManager {
  final ConsentRepository _repository;
  
  // Current version of legal documents
  static const String _currentLegalVersion = '1.0.0';
  
  // Cache for frequently accessed consent data
  final Map<String, ConsentSummary> _consentCache = {};
  
  DPDPConsentManager(this._repository);

  /// Initializes consent for a new user with essential consents
  /// 
  /// This should be called during user registration or first app launch
  /// to establish the minimum required consents for app functionality.
  Future<ConsentSummary> initializeUserConsents({
    required String userId,
    required ConsentSource source,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Essential consents required for basic app functionality
      final essentialConsents = {
        ConsentType.essential: {
          'initialized_at': DateTime.now().toIso8601String(),
          'app_version': _getAppVersion(),
          ...?metadata,
        },
        ConsentType.location: {
          'purpose': 'delivery_optimization',
          'initialized_at': DateTime.now().toIso8601String(),
          ...?metadata,
        },
        ConsentType.thirdPartySharing: {
          'purpose': 'service_delivery',
          'partners': ['delivery_agents', 'payment_processors'],
          'initialized_at': DateTime.now().toIso8601String(),
          ...?metadata,
        },
      };

      final grantedConsents = await _repository.grantMultipleConsents(
        userId: userId,
        consents: essentialConsents,
        source: source,
        version: _currentLegalVersion,
      );

      debugPrint('🔒 DPDP: Initialized ${grantedConsents.length} essential consents for user $userId');

      // Clear cache and return fresh summary
      _consentCache.remove(userId);
      return await getConsentSummary(userId);
    } catch (e) {
      debugPrint('❌ DPDP: Failed to initialize user consents: $e');
      rethrow;
    }
  }

  /// Requests consent for a specific type with user interaction
  /// 
  /// This method should be used when requesting consent through UI interactions
  /// and includes validation to ensure the request is appropriate.
  Future<bool> requestConsent({
    required String userId,
    required ConsentType type,
    required ConsentSource source,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Check if consent already exists
      final existingConsent = await _repository.getConsent(
        userId: userId,
        type: type,
      );

      if (existingConsent?.isValid == true) {
        debugPrint('🔒 DPDP: Consent for $type already granted for user $userId');
        return true;
      }

      // Validate that this consent type can be requested
      if (!_canRequestConsent(type, source)) {
        debugPrint('❌ DPDP: Cannot request consent for $type from source $source');
        return false;
      }

      // Grant the consent
      final consent = await _repository.grantConsent(
        userId: userId,
        type: type,
        source: source,
        version: _currentLegalVersion,
        metadata: {
          'requested_at': DateTime.now().toIso8601String(),
          'app_version': _getAppVersion(),
          ...?metadata,
        },
      );

      debugPrint('✅ DPDP: Granted consent for ${type.displayName} to user $userId');

      // Clear cache
      _consentCache.remove(userId);

      return consent.isValid;
    } catch (e) {
      debugPrint('❌ DPDP: Failed to request consent: $e');
      return false;
    }
  }

  /// Withdraws consent for a specific type
  /// 
  /// Implements the user's right to withdraw consent as required by DPDP Act 2023
  Future<bool> withdrawConsent({
    required String userId,
    required ConsentType type,
    required String reason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Check if consent can be withdrawn
      if (!type.canBeWithdrawn) {
        debugPrint('❌ DPDP: Cannot withdraw essential consent for $type');
        return false;
      }

      // Check if consent exists and is currently granted
      final existingConsent = await _repository.getConsent(
        userId: userId,
        type: type,
      );

      if (existingConsent?.isValid != true) {
        debugPrint('🔒 DPDP: No active consent found for $type for user $userId');
        return true; // Already withdrawn or never granted
      }

      // Revoke the consent
      await _repository.revokeConsent(
        userId: userId,
        type: type,
        reason: reason,
        metadata: {
          'withdrawn_at': DateTime.now().toIso8601String(),
          'app_version': _getAppVersion(),
          'user_initiated': true,
          ...?metadata,
        },
      );

      debugPrint('🔒 DPDP: Withdrew consent for ${type.displayName} from user $userId');

      // Clear cache
      _consentCache.remove(userId);

      return true;
    } catch (e) {
      debugPrint('❌ DPDP: Failed to withdraw consent: $e');
      return false;
    }
  }

  /// Checks if a user has granted a specific consent
  /// 
  /// This is the primary method for checking consent before processing data
  Future<bool> hasConsent({
    required String userId,
    required ConsentType type,
  }) async {
    try {
      // Check cache first for performance
      final cachedSummary = _consentCache[userId];
      if (cachedSummary != null) {
        return cachedSummary.hasConsent(type);
      }

      // Fetch from repository
      return await _repository.hasConsent(
        userId: userId,
        type: type,
      );
    } catch (e) {
      debugPrint('❌ DPDP: Failed to check consent: $e');
      // Fail securely - assume no consent if we can't verify
      return false;
    }
  }

  /// Gets a comprehensive consent summary for a user
  /// 
  /// Includes caching for performance optimization
  Future<ConsentSummary> getConsentSummary(String userId) async {
    try {
      // Check cache first
      final cached = _consentCache[userId];
      if (cached != null && _isCacheValid(cached)) {
        return cached;
      }

      // Fetch fresh data
      final summary = await _repository.getConsentSummary(userId);
      
      // Cache the result
      _consentCache[userId] = summary;
      
      return summary;
    } catch (e) {
      debugPrint('❌ DPDP: Failed to get consent summary: $e');
      rethrow;
    }
  }

  /// Validates user compliance with DPDP Act 2023
  /// 
  /// Checks if the user has all required consents for app functionality
  Future<ConsentComplianceResult> validateCompliance(String userId) async {
    try {
      return await _repository.validateUserCompliance(userId);
    } catch (e) {
      debugPrint('❌ DPDP: Failed to validate compliance: $e');
      rethrow;
    }
  }

  /// Exports user consent data for data portability (DPDP Act 2023 requirement)
  /// 
  /// Returns all consent data in a portable format
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    try {
      final consentData = await _repository.exportUserConsentData(userId);
      
      return {
        'user_id': userId,
        'export_timestamp': DateTime.now().toIso8601String(),
        'legal_version': _currentLegalVersion,
        'dpdp_compliance': 'Digital Personal Data Protection Act 2023',
        'consent_data': consentData,
        'export_format_version': '1.0.0',
      };
    } catch (e) {
      debugPrint('❌ DPDP: Failed to export user data: $e');
      rethrow;
    }
  }

  /// Handles user data deletion (right to be forgotten)
  /// 
  /// CRITICAL: This should only be called as part of complete user account deletion
  Future<void> deleteUserData({
    required String userId,
    required String deletionReason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _repository.deleteUserConsentData(
        userId: userId,
        deletionReason: deletionReason,
        metadata: {
          'deleted_at': DateTime.now().toIso8601String(),
          'dpdp_compliance': 'right_to_be_forgotten',
          'app_version': _getAppVersion(),
          ...?metadata,
        },
      );

      // Clear cache
      _consentCache.remove(userId);

      debugPrint('🔒 DPDP: Deleted consent data for user $userId');
    } catch (e) {
      debugPrint('❌ DPDP: Failed to delete user data: $e');
      rethrow;
    }
  }

  /// Gets consent history for audit purposes
  /// 
  /// Returns complete audit trail for a specific consent type
  Future<List<UserConsent>> getConsentHistory({
    required String userId,
    required ConsentType type,
  }) async {
    try {
      return await _repository.getConsentHistory(
        userId: userId,
        type: type,
      );
    } catch (e) {
      debugPrint('❌ DPDP: Failed to get consent history: $e');
      rethrow;
    }
  }

  /// Clears consent cache for a user
  /// 
  /// Should be called when consent data is updated outside this manager
  void clearCache(String userId) {
    _consentCache.remove(userId);
  }

  /// Clears all consent cache
  /// 
  /// Should be called during app logout or data refresh
  void clearAllCache() {
    _consentCache.clear();
  }

  // Private helper methods

  bool _canRequestConsent(ConsentType type, ConsentSource source) {
    // Essential consents should only be granted during initialization
    if (type.isEssential && source != ConsentSource.onboarding && source != ConsentSource.registration) {
      return false;
    }
    
    return true;
  }

  bool _isCacheValid(ConsentSummary summary) {
    // Cache is valid for 5 minutes
    const cacheValidityDuration = Duration(minutes: 5);
    return DateTime.now().difference(summary.lastUpdated) < cacheValidityDuration;
  }

  String _getAppVersion() {
    // This should be replaced with actual app version
    return '1.0.0';
  }

  /// Gets statistics for compliance reporting
  Future<ConsentStatistics> getStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _repository.getConsentStatistics(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      debugPrint('❌ DPDP: Failed to get consent statistics: $e');
      rethrow;
    }
  }

  /// Bulk updates multiple consents (useful for settings screen)
  Future<bool> updateMultipleConsents({
    required String userId,
    required Map<ConsentType, bool> consentUpdates,
    required String reason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final List<ConsentType> toGrant = [];
      final List<ConsentType> toRevoke = [];

      // Categorize updates
      for (final entry in consentUpdates.entries) {
        if (entry.value) {
          toGrant.add(entry.key);
        } else if (entry.key.canBeWithdrawn) {
          toRevoke.add(entry.key);
        }
      }

      // Grant new consents
      if (toGrant.isNotEmpty) {
        final grantConsents = <ConsentType, Map<String, dynamic>?>{};
        for (final type in toGrant) {
          grantConsents[type] = {
            'bulk_update': true,
            'updated_at': DateTime.now().toIso8601String(),
            ...?metadata,
          };
        }

        await _repository.grantMultipleConsents(
          userId: userId,
          consents: grantConsents,
          source: ConsentSource.settings,
          version: _currentLegalVersion,
        );
      }

      // Revoke consents
      if (toRevoke.isNotEmpty) {
        await _repository.revokeMultipleConsents(
          userId: userId,
          types: toRevoke,
          reason: reason,
          metadata: {
            'bulk_update': true,
            'updated_at': DateTime.now().toIso8601String(),
            ...?metadata,
          },
        );
      }

      // Clear cache
      _consentCache.remove(userId);

      debugPrint('✅ DPDP: Updated ${consentUpdates.length} consents for user $userId');
      return true;
    } catch (e) {
      debugPrint('❌ DPDP: Failed to update multiple consents: $e');
      return false;
    }
  }
}
