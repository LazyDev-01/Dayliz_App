/// User Consent Entity for DPDP Act 2023 Compliance
/// 
/// This entity represents user consent for various data processing activities
/// as required by the Digital Personal Data Protection Act 2023.
/// 
/// CRITICAL: This implementation must maintain audit trails and comply with
/// DPDP Act 2023 requirements for consent management.
class UserConsent {
  final String id;
  final String userId;
  final ConsentType type;
  final bool isGranted;
  final DateTime grantedAt;
  final DateTime? revokedAt;
  final String? revokedReason;
  final ConsentSource source;
  final String version; // Legal document version when consent was given
  final Map<String, dynamic>? metadata;

  const UserConsent({
    required this.id,
    required this.userId,
    required this.type,
    required this.isGranted,
    required this.grantedAt,
    this.revokedAt,
    this.revokedReason,
    required this.source,
    required this.version,
    this.metadata,
  });

  /// Creates a new consent grant
  factory UserConsent.grant({
    required String id,
    required String userId,
    required ConsentType type,
    required ConsentSource source,
    required String version,
    Map<String, dynamic>? metadata,
  }) {
    return UserConsent(
      id: id,
      userId: userId,
      type: type,
      isGranted: true,
      grantedAt: DateTime.now(),
      source: source,
      version: version,
      metadata: metadata,
    );
  }

  /// Creates a revoked consent
  UserConsent revoke({
    required String reason,
    Map<String, dynamic>? additionalMetadata,
  }) {
    return UserConsent(
      id: id,
      userId: userId,
      type: type,
      isGranted: false,
      grantedAt: grantedAt,
      revokedAt: DateTime.now(),
      revokedReason: reason,
      source: source,
      version: version,
      metadata: {
        ...?metadata,
        ...?additionalMetadata,
        'revocation_timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Checks if consent is currently valid
  bool get isValid {
    return isGranted && revokedAt == null;
  }

  /// Checks if consent has expired (if applicable)
  bool get isExpired {
    // For DPDP Act 2023, consent doesn't automatically expire
    // but can be revoked by user at any time
    return false;
  }

  /// Gets the duration since consent was granted
  Duration get consentAge {
    return DateTime.now().difference(grantedAt);
  }

  /// Converts to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'is_granted': isGranted,
      'granted_at': grantedAt.toIso8601String(),
      'revoked_at': revokedAt?.toIso8601String(),
      'revoked_reason': revokedReason,
      'source': source.name,
      'version': version,
      'metadata': metadata,
    };
  }

  /// Creates from JSON
  factory UserConsent.fromJson(Map<String, dynamic> json) {
    return UserConsent(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: ConsentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ConsentType.unknown,
      ),
      isGranted: json['is_granted'] as bool,
      grantedAt: DateTime.parse(json['granted_at'] as String),
      revokedAt: json['revoked_at'] != null 
          ? DateTime.parse(json['revoked_at'] as String) 
          : null,
      revokedReason: json['revoked_reason'] as String?,
      source: ConsentSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => ConsentSource.unknown,
      ),
      version: json['version'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserConsent &&
        other.id == id &&
        other.userId == userId &&
        other.type == type &&
        other.isGranted == isGranted;
  }

  @override
  int get hashCode {
    return Object.hash(id, userId, type, isGranted);
  }

  @override
  String toString() {
    return 'UserConsent(id: $id, type: $type, isGranted: $isGranted, grantedAt: $grantedAt)';
  }
}

/// Types of consent required under DPDP Act 2023
enum ConsentType {
  /// Essential data processing for service delivery
  essential('Essential Services', 'Required for basic app functionality'),
  
  /// Location data processing for delivery optimization
  location('Location Data', 'GPS location for delivery optimization'),
  
  /// Marketing communications and promotional content
  marketing('Marketing Communications', 'Promotional emails, SMS, and notifications'),
  
  /// Analytics and app usage tracking
  analytics('Analytics & Usage', 'App usage analytics and performance tracking'),
  
  /// Personalization and recommendation features
  personalization('Personalization', 'Personalized content and product recommendations'),
  
  /// Third-party data sharing for service providers
  thirdPartySharing('Third-party Sharing', 'Sharing data with delivery partners and payment processors'),
  
  /// Cookies and tracking technologies
  cookies('Cookies & Tracking', 'Cookies and similar tracking technologies'),
  
  /// Unknown or legacy consent type
  unknown('Unknown', 'Unknown consent type');

  const ConsentType(this.displayName, this.description);

  final String displayName;
  final String description;

  /// Whether this consent type is required for basic app functionality
  bool get isEssential {
    return this == ConsentType.essential || 
           this == ConsentType.location ||
           this == ConsentType.thirdPartySharing;
  }

  /// Whether this consent can be withdrawn by the user
  bool get canBeWithdrawn {
    return this != ConsentType.essential;
  }
}

/// Source of consent (how it was obtained)
enum ConsentSource {
  /// Consent given during app onboarding
  onboarding('Onboarding Flow'),
  
  /// Consent given in settings/preferences screen
  settings('Settings Screen'),
  
  /// Consent given during feature usage
  featurePrompt('Feature Prompt'),
  
  /// Consent given during registration
  registration('Registration Process'),
  
  /// Consent updated via legal screen
  legalScreen('Legal Screen'),
  
  /// System-generated or migrated consent
  system('System Generated'),
  
  /// Unknown source
  unknown('Unknown Source');

  const ConsentSource(this.displayName);

  final String displayName;
}

/// Consent summary for a user
class ConsentSummary {
  final String userId;
  final Map<ConsentType, UserConsent?> consents;
  final DateTime lastUpdated;
  final int totalConsents;
  final int grantedConsents;
  final int revokedConsents;

  const ConsentSummary({
    required this.userId,
    required this.consents,
    required this.lastUpdated,
    required this.totalConsents,
    required this.grantedConsents,
    required this.revokedConsents,
  });

  /// Creates a consent summary from a list of consents
  factory ConsentSummary.fromConsents(String userId, List<UserConsent> consentList) {
    final Map<ConsentType, UserConsent?> consentMap = {};
    
    // Initialize all consent types
    for (final type in ConsentType.values) {
      consentMap[type] = null;
    }
    
    // Add actual consents (latest for each type)
    for (final consent in consentList) {
      final existing = consentMap[consent.type];
      if (existing == null || consent.grantedAt.isAfter(existing.grantedAt)) {
        consentMap[consent.type] = consent;
      }
    }

    final granted = consentMap.values
        .where((c) => c?.isValid == true)
        .length;
    
    final revoked = consentMap.values
        .where((c) => c != null && !c.isValid)
        .length;

    final lastUpdate = consentList.isNotEmpty
        ? consentList
            .map((c) => c.revokedAt ?? c.grantedAt)
            .reduce((a, b) => a.isAfter(b) ? a : b)
        : DateTime.now();

    return ConsentSummary(
      userId: userId,
      consents: consentMap,
      lastUpdated: lastUpdate,
      totalConsents: consentList.length,
      grantedConsents: granted,
      revokedConsents: revoked,
    );
  }

  /// Checks if a specific consent type is granted
  bool hasConsent(ConsentType type) {
    return consents[type]?.isValid == true;
  }

  /// Gets the consent for a specific type
  UserConsent? getConsent(ConsentType type) {
    return consents[type];
  }

  /// Checks if all essential consents are granted
  bool get hasAllEssentialConsents {
    return ConsentType.values
        .where((type) => type.isEssential)
        .every((type) => hasConsent(type));
  }

  /// Gets compliance status for DPDP Act 2023
  ConsentComplianceStatus get complianceStatus {
    if (!hasAllEssentialConsents) {
      return ConsentComplianceStatus.nonCompliant;
    }
    
    if (grantedConsents == 0) {
      return ConsentComplianceStatus.noConsents;
    }
    
    return ConsentComplianceStatus.compliant;
  }
}

/// Compliance status for consent management
enum ConsentComplianceStatus {
  compliant('Compliant', 'All required consents are properly managed'),
  nonCompliant('Non-Compliant', 'Missing essential consents'),
  noConsents('No Consents', 'No consent records found'),
  unknown('Unknown', 'Unable to determine compliance status');

  const ConsentComplianceStatus(this.displayName, this.description);

  final String displayName;
  final String description;
}
