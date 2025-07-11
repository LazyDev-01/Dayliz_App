import '../entities/user_consent.dart';

/// Repository interface for managing user consent data
/// 
/// This repository handles all consent-related data operations
/// in compliance with DPDP Act 2023 requirements.
/// 
/// CRITICAL: All consent operations must maintain audit trails
/// and comply with Indian data protection laws.
abstract class ConsentRepository {
  /// Grants consent for a specific type
  /// 
  /// [userId] - The user granting consent
  /// [type] - The type of consent being granted
  /// [source] - How the consent was obtained
  /// [version] - Version of legal documents when consent was given
  /// [metadata] - Additional context about the consent
  Future<UserConsent> grantConsent({
    required String userId,
    required ConsentType type,
    required ConsentSource source,
    required String version,
    Map<String, dynamic>? metadata,
  });

  /// Revokes consent for a specific type
  /// 
  /// [userId] - The user revoking consent
  /// [type] - The type of consent being revoked
  /// [reason] - Reason for revocation
  /// [metadata] - Additional context about the revocation
  Future<UserConsent> revokeConsent({
    required String userId,
    required ConsentType type,
    required String reason,
    Map<String, dynamic>? metadata,
  });

  /// Gets the current consent status for a user and type
  /// 
  /// Returns the most recent consent record for the specified type
  Future<UserConsent?> getConsent({
    required String userId,
    required ConsentType type,
  });

  /// Gets all consent records for a user
  /// 
  /// [includeRevoked] - Whether to include revoked consents in the result
  Future<List<UserConsent>> getUserConsents({
    required String userId,
    bool includeRevoked = false,
  });

  /// Gets a comprehensive consent summary for a user
  /// 
  /// This includes current status for all consent types and statistics
  Future<ConsentSummary> getConsentSummary(String userId);

  /// Gets consent history for a specific type
  /// 
  /// Returns all consent records (grants and revocations) for audit purposes
  Future<List<UserConsent>> getConsentHistory({
    required String userId,
    required ConsentType type,
  });

  /// Checks if a user has granted a specific consent
  /// 
  /// This is a convenience method for quick consent checks
  Future<bool> hasConsent({
    required String userId,
    required ConsentType type,
  });

  /// Updates consent metadata without changing the grant/revoke status
  /// 
  /// Useful for adding additional context or updating tracking information
  Future<UserConsent> updateConsentMetadata({
    required String consentId,
    required Map<String, dynamic> metadata,
  });

  /// Bulk grant multiple consents (e.g., during onboarding)
  /// 
  /// [consents] - Map of consent types to their metadata
  /// [source] - How all these consents were obtained
  /// [version] - Version of legal documents when consents were given
  Future<List<UserConsent>> grantMultipleConsents({
    required String userId,
    required Map<ConsentType, Map<String, dynamic>?> consents,
    required ConsentSource source,
    required String version,
  });

  /// Bulk revoke multiple consents
  /// 
  /// [types] - List of consent types to revoke
  /// [reason] - Reason for revocation
  /// [metadata] - Additional context about the revocation
  Future<List<UserConsent>> revokeMultipleConsents({
    required String userId,
    required List<ConsentType> types,
    required String reason,
    Map<String, dynamic>? metadata,
  });

  /// Gets consent statistics for compliance reporting
  /// 
  /// [startDate] - Start date for the reporting period
  /// [endDate] - End date for the reporting period
  Future<ConsentStatistics> getConsentStatistics({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Exports user consent data for DPDP Act 2023 data portability
  /// 
  /// Returns all consent data for a user in a portable format
  Future<Map<String, dynamic>> exportUserConsentData(String userId);

  /// Deletes all consent data for a user (right to be forgotten)
  /// 
  /// CRITICAL: This should only be called as part of complete user data deletion
  /// and must maintain audit logs as required by law
  Future<void> deleteUserConsentData({
    required String userId,
    required String deletionReason,
    Map<String, dynamic>? metadata,
  });

  /// Validates consent compliance for a user
  /// 
  /// Checks if the user has all required consents for app functionality
  Future<ConsentComplianceResult> validateUserCompliance(String userId);

  /// Gets users who need consent renewal or updates
  /// 
  /// Useful for compliance monitoring and user outreach
  Future<List<String>> getUsersNeedingConsentUpdate({
    ConsentType? specificType,
    Duration? olderThan,
  });

  /// Archives old consent records while maintaining audit trail
  /// 
  /// Helps with data management while preserving legal requirements
  Future<void> archiveOldConsents({
    required Duration retentionPeriod,
    bool dryRun = false,
  });
}

/// Statistics for consent management and compliance reporting
class ConsentStatistics {
  final int totalUsers;
  final int usersWithConsents;
  final int usersWithoutConsents;
  final Map<ConsentType, int> consentsByType;
  final Map<ConsentType, int> revokedByType;
  final Map<ConsentSource, int> consentsBySource;
  final DateTime generatedAt;
  final DateTime? periodStart;
  final DateTime? periodEnd;

  const ConsentStatistics({
    required this.totalUsers,
    required this.usersWithConsents,
    required this.usersWithoutConsents,
    required this.consentsByType,
    required this.revokedByType,
    required this.consentsBySource,
    required this.generatedAt,
    this.periodStart,
    this.periodEnd,
  });

  /// Calculates consent adoption rate
  double get adoptionRate {
    return totalUsers > 0 ? usersWithConsents / totalUsers : 0.0;
  }

  /// Gets the most popular consent type
  ConsentType? get mostPopularConsentType {
    if (consentsByType.isEmpty) return null;
    
    return consentsByType.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Gets the most common consent source
  ConsentSource? get mostCommonSource {
    if (consentsBySource.isEmpty) return null;
    
    return consentsBySource.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}

/// Result of consent compliance validation
class ConsentComplianceResult {
  final String userId;
  final ConsentComplianceStatus status;
  final List<ConsentType> missingEssentialConsents;
  final List<ConsentType> expiredConsents;
  final List<ConsentIssue> issues;
  final DateTime validatedAt;

  const ConsentComplianceResult({
    required this.userId,
    required this.status,
    required this.missingEssentialConsents,
    required this.expiredConsents,
    required this.issues,
    required this.validatedAt,
  });

  /// Whether the user is compliant with DPDP Act 2023
  bool get isCompliant {
    return status == ConsentComplianceStatus.compliant &&
           missingEssentialConsents.isEmpty &&
           issues.isEmpty;
  }

  /// Gets a human-readable compliance summary
  String get complianceSummary {
    if (isCompliant) {
      return 'User is fully compliant with DPDP Act 2023 requirements.';
    }
    
    final List<String> issueDescriptions = [];
    
    if (missingEssentialConsents.isNotEmpty) {
      issueDescriptions.add(
        'Missing essential consents: ${missingEssentialConsents.map((c) => c.displayName).join(', ')}'
      );
    }
    
    if (expiredConsents.isNotEmpty) {
      issueDescriptions.add(
        'Expired consents: ${expiredConsents.map((c) => c.displayName).join(', ')}'
      );
    }
    
    if (issues.isNotEmpty) {
      issueDescriptions.add(
        'Additional issues: ${issues.length} found'
      );
    }
    
    return issueDescriptions.join('; ');
  }
}

/// Specific consent compliance issue
class ConsentIssue {
  final ConsentIssueType type;
  final ConsentType? consentType;
  final String description;
  final ConsentIssueSeverity severity;
  final Map<String, dynamic>? metadata;

  const ConsentIssue({
    required this.type,
    this.consentType,
    required this.description,
    required this.severity,
    this.metadata,
  });
}

/// Types of consent compliance issues
enum ConsentIssueType {
  missingConsent,
  expiredConsent,
  invalidConsent,
  conflictingConsent,
  auditTrailGap,
  technicalError,
}

/// Severity levels for consent issues
enum ConsentIssueSeverity {
  low,
  medium,
  high,
  critical,
}
