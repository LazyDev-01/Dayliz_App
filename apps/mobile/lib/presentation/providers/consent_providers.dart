import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/dpdp_consent_manager.dart';
import '../../data/repositories/supabase_consent_repository.dart';
import '../../domain/entities/user_consent.dart';
import '../../domain/repositories/consent_repository.dart';

/// Providers for DPDP Consent Management System
/// 
/// These providers manage the consent-related state and services
/// for DPDP Act 2023 compliance throughout the application.

// Repository provider
final consentRepositoryProvider = Provider<ConsentRepository>((ref) {
  return SupabaseConsentRepository(Supabase.instance.client);
});

// Consent manager provider
final consentManagerProvider = Provider<DPDPConsentManager>((ref) {
  final repository = ref.read(consentRepositoryProvider);
  return DPDPConsentManager(repository);
});

// Current user ID provider (placeholder - should be replaced with actual auth)
final currentUserIdProvider = Provider<String>((ref) {
  // TODO: Replace with actual user authentication
  // For now, return a test UUID that matches Supabase format
  return '00000000-0000-0000-0000-000000000000';
});

// Consent summary provider
final consentSummaryProvider = FutureProvider<ConsentSummary>((ref) async {
  final consentManager = ref.read(consentManagerProvider);
  final userId = ref.read(currentUserIdProvider);
  
  return await consentManager.getConsentSummary(userId);
});

// Individual consent check provider
final consentCheckProvider = FutureProvider.family<bool, ConsentType>((ref, type) async {
  final consentManager = ref.read(consentManagerProvider);
  final userId = ref.read(currentUserIdProvider);
  
  return await consentManager.hasConsent(userId: userId, type: type);
});

// Consent compliance provider
final consentComplianceProvider = FutureProvider<ConsentComplianceResult>((ref) async {
  final consentManager = ref.read(consentManagerProvider);
  final userId = ref.read(currentUserIdProvider);
  
  return await consentManager.validateCompliance(userId);
});

// Consent history provider for a specific type
final consentHistoryProvider = FutureProvider.family<List<UserConsent>, ConsentType>((ref, type) async {
  final consentManager = ref.read(consentManagerProvider);
  final userId = ref.read(currentUserIdProvider);
  
  return await consentManager.getConsentHistory(userId: userId, type: type);
});

// Consent statistics provider
final consentStatisticsProvider = FutureProvider<ConsentStatistics>((ref) async {
  final consentManager = ref.read(consentManagerProvider);
  
  return await consentManager.getStatistics();
});

/// Consent state notifier for managing consent operations
class ConsentNotifier extends StateNotifier<AsyncValue<ConsentSummary>> {
  final DPDPConsentManager _consentManager;
  final String _userId;

  ConsentNotifier(this._consentManager, this._userId) : super(const AsyncValue.loading()) {
    _loadConsentSummary();
  }

  Future<void> _loadConsentSummary() async {
    try {
      state = const AsyncValue.loading();
      final summary = await _consentManager.getConsentSummary(_userId);
      state = AsyncValue.data(summary);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Grants consent for a specific type
  Future<bool> grantConsent({
    required ConsentType type,
    required ConsentSource source,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final success = await _consentManager.requestConsent(
        userId: _userId,
        type: type,
        source: source,
        metadata: metadata,
      );

      if (success) {
        await _loadConsentSummary();
      }

      return success;
    } catch (e) {
      return false;
    }
  }

  /// Withdraws consent for a specific type
  Future<bool> withdrawConsent({
    required ConsentType type,
    required String reason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final success = await _consentManager.withdrawConsent(
        userId: _userId,
        type: type,
        reason: reason,
        metadata: metadata,
      );

      if (success) {
        await _loadConsentSummary();
      }

      return success;
    } catch (e) {
      return false;
    }
  }

  /// Updates multiple consents at once
  Future<bool> updateMultipleConsents({
    required Map<ConsentType, bool> consentUpdates,
    required String reason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final success = await _consentManager.updateMultipleConsents(
        userId: _userId,
        consentUpdates: consentUpdates,
        reason: reason,
        metadata: metadata,
      );

      if (success) {
        await _loadConsentSummary();
      }

      return success;
    } catch (e) {
      return false;
    }
  }

  /// Refreshes the consent summary
  Future<void> refresh() async {
    await _loadConsentSummary();
  }

  /// Exports user consent data
  Future<Map<String, dynamic>?> exportUserData() async {
    try {
      return await _consentManager.exportUserData(_userId);
    } catch (e) {
      return null;
    }
  }
}

// Consent state notifier provider
final consentNotifierProvider = StateNotifierProvider<ConsentNotifier, AsyncValue<ConsentSummary>>((ref) {
  final consentManager = ref.read(consentManagerProvider);
  final userId = ref.read(currentUserIdProvider);
  
  return ConsentNotifier(consentManager, userId);
});

/// Helper providers for common consent checks

// Essential consents check
final hasEssentialConsentsProvider = FutureProvider<bool>((ref) async {
  final summary = await ref.read(consentSummaryProvider.future);
  return summary.hasAllEssentialConsents;
});

// Marketing consent check
final hasMarketingConsentProvider = FutureProvider<bool>((ref) async {
  return await ref.read(consentCheckProvider(ConsentType.marketing).future);
});

// Analytics consent check
final hasAnalyticsConsentProvider = FutureProvider<bool>((ref) async {
  return await ref.read(consentCheckProvider(ConsentType.analytics).future);
});

// Location consent check
final hasLocationConsentProvider = FutureProvider<bool>((ref) async {
  return await ref.read(consentCheckProvider(ConsentType.location).future);
});

// Personalization consent check
final hasPersonalizationConsentProvider = FutureProvider<bool>((ref) async {
  return await ref.read(consentCheckProvider(ConsentType.personalization).future);
});

/// Consent initialization provider for new users
final consentInitializationProvider = FutureProvider<ConsentSummary>((ref) async {
  final consentManager = ref.read(consentManagerProvider);
  final userId = ref.read(currentUserIdProvider);
  
  return await consentManager.initializeUserConsents(
    userId: userId,
    source: ConsentSource.onboarding,
    metadata: {
      'initialization_timestamp': DateTime.now().toIso8601String(),
      'app_version': '1.0.0', // TODO: Get actual app version
    },
  );
});

/// Consent validation provider for app functionality
final consentValidationProvider = FutureProvider<bool>((ref) async {
  final compliance = await ref.read(consentComplianceProvider.future);
  return compliance.isCompliant;
});

/// Provider for checking if user can use specific features based on consent
final featureAccessProvider = FutureProvider.family<bool, String>((ref, feature) async {
  final summary = await ref.read(consentSummaryProvider.future);
  
  switch (feature) {
    case 'location_services':
      return summary.hasConsent(ConsentType.location);
    case 'marketing_notifications':
      return summary.hasConsent(ConsentType.marketing);
    case 'analytics_tracking':
      return summary.hasConsent(ConsentType.analytics);
    case 'personalized_content':
      return summary.hasConsent(ConsentType.personalization);
    case 'basic_functionality':
      return summary.hasAllEssentialConsents;
    default:
      return false;
  }
});

/// Provider for consent-dependent UI state
final consentDependentUIProvider = Provider<ConsentDependentUI>((ref) {
  return ConsentDependentUI(ref);
});

/// Helper class for consent-dependent UI logic
class ConsentDependentUI {
  final Ref _ref;

  ConsentDependentUI(this._ref);

  /// Checks if a feature should be visible based on consent
  Future<bool> shouldShowFeature(String feature) async {
    return await _ref.read(featureAccessProvider(feature).future);
  }

  /// Gets the appropriate message for a consent-gated feature
  String getConsentMessage(ConsentType type) {
    switch (type) {
      case ConsentType.location:
        return 'Location access is required for delivery services. You can enable this in Privacy Preferences.';
      case ConsentType.marketing:
        return 'Marketing consent is required for promotional notifications. You can enable this in Privacy Preferences.';
      case ConsentType.analytics:
        return 'Analytics consent helps us improve the app experience. You can enable this in Privacy Preferences.';
      case ConsentType.personalization:
        return 'Personalization consent enables customized content. You can enable this in Privacy Preferences.';
      default:
        return 'This feature requires additional consent. Please check your Privacy Preferences.';
    }
  }

  /// Checks if the user needs to update their consent preferences
  Future<bool> needsConsentUpdate() async {
    final compliance = await _ref.read(consentComplianceProvider.future);
    return !compliance.isCompliant;
  }
}
