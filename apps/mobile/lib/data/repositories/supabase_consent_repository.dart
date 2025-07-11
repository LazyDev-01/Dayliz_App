import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/user_consent.dart';
import '../../domain/repositories/consent_repository.dart';

/// Supabase implementation of ConsentRepository
/// 
/// This implementation stores consent data in Supabase with proper
/// audit trails and DPDP Act 2023 compliance features.
/// 
/// Database Schema Required:
/// - user_consents table with RLS policies
/// - consent_audit_log table for audit trails
/// - consent_statistics view for reporting
class SupabaseConsentRepository implements ConsentRepository {
  final SupabaseClient _client;
  final Uuid _uuid = const Uuid();

  SupabaseConsentRepository(this._client);

  @override
  Future<UserConsent> grantConsent({
    required String userId,
    required ConsentType type,
    required ConsentSource source,
    required String version,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Check if there's an existing active consent
      final existing = await getConsent(userId: userId, type: type);
      if (existing?.isValid == true) {
        return existing!;
      }

      // Create new consent
      final consent = UserConsent.grant(
        id: _uuid.v4(),
        userId: userId,
        type: type,
        source: source,
        version: version,
        metadata: metadata,
      );

      // Insert into database
      await _client.from('user_consents').insert(consent.toJson());

      // Log the action for audit trail
      await _logConsentAction(
        userId: userId,
        action: 'grant',
        consentType: type,
        consentId: consent.id,
        metadata: {
          'source': source.name,
          'version': version,
          ...?metadata,
        },
      );

      return consent;
    } catch (e) {
      throw Exception('Failed to grant consent: $e');
    }
  }

  @override
  Future<UserConsent> revokeConsent({
    required String userId,
    required ConsentType type,
    required String reason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Get existing consent
      final existing = await getConsent(userId: userId, type: type);
      if (existing == null || !existing.isValid) {
        throw Exception('No active consent found to revoke');
      }

      // Create revoked consent
      final revokedConsent = existing.revoke(
        reason: reason,
        additionalMetadata: metadata,
      );

      // Update in database
      await _client
          .from('user_consents')
          .update(revokedConsent.toJson())
          .eq('id', existing.id);

      // Log the action for audit trail
      await _logConsentAction(
        userId: userId,
        action: 'revoke',
        consentType: type,
        consentId: existing.id,
        metadata: {
          'reason': reason,
          ...?metadata,
        },
      );

      return revokedConsent;
    } catch (e) {
      throw Exception('Failed to revoke consent: $e');
    }
  }

  @override
  Future<UserConsent?> getConsent({
    required String userId,
    required ConsentType type,
  }) async {
    try {
      final response = await _client
          .from('user_consents')
          .select()
          .eq('user_id', userId)
          .eq('type', type.name)
          .order('granted_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      return UserConsent.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get consent: $e');
    }
  }

  @override
  Future<List<UserConsent>> getUserConsents({
    required String userId,
    bool includeRevoked = false,
  }) async {
    try {
      var query = _client
          .from('user_consents')
          .select()
          .eq('user_id', userId);

      if (!includeRevoked) {
        query = query.eq('is_granted', true).isFilter('revoked_at', null);
      }

      final response = await query.order('granted_at', ascending: false);

      return response.map((json) => UserConsent.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get user consents: $e');
    }
  }

  @override
  Future<ConsentSummary> getConsentSummary(String userId) async {
    try {
      final consents = await getUserConsents(userId: userId, includeRevoked: true);
      return ConsentSummary.fromConsents(userId, consents);
    } catch (e) {
      throw Exception('Failed to get consent summary: $e');
    }
  }

  @override
  Future<List<UserConsent>> getConsentHistory({
    required String userId,
    required ConsentType type,
  }) async {
    try {
      final response = await _client
          .from('user_consents')
          .select()
          .eq('user_id', userId)
          .eq('type', type.name)
          .order('granted_at', ascending: false);

      return response.map((json) => UserConsent.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get consent history: $e');
    }
  }

  @override
  Future<bool> hasConsent({
    required String userId,
    required ConsentType type,
  }) async {
    try {
      final consent = await getConsent(userId: userId, type: type);
      return consent?.isValid == true;
    } catch (e) {
      // Fail securely - assume no consent if we can't verify
      return false;
    }
  }

  @override
  Future<UserConsent> updateConsentMetadata({
    required String consentId,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      // Get existing consent
      final response = await _client
          .from('user_consents')
          .select()
          .eq('id', consentId)
          .single();

      final consent = UserConsent.fromJson(response);

      // Update metadata
      final updatedMetadata = {
        ...?consent.metadata,
        ...metadata,
        'metadata_updated_at': DateTime.now().toIso8601String(),
      };

      // Update in database
      await _client
          .from('user_consents')
          .update({'metadata': updatedMetadata})
          .eq('id', consentId);

      // Return updated consent
      return UserConsent.fromJson({
        ...response,
        'metadata': updatedMetadata,
      });
    } catch (e) {
      throw Exception('Failed to update consent metadata: $e');
    }
  }

  @override
  Future<List<UserConsent>> grantMultipleConsents({
    required String userId,
    required Map<ConsentType, Map<String, dynamic>?> consents,
    required ConsentSource source,
    required String version,
  }) async {
    try {
      final List<UserConsent> grantedConsents = [];

      for (final entry in consents.entries) {
        final consent = await grantConsent(
          userId: userId,
          type: entry.key,
          source: source,
          version: version,
          metadata: entry.value,
        );
        grantedConsents.add(consent);
      }

      return grantedConsents;
    } catch (e) {
      throw Exception('Failed to grant multiple consents: $e');
    }
  }

  @override
  Future<List<UserConsent>> revokeMultipleConsents({
    required String userId,
    required List<ConsentType> types,
    required String reason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final List<UserConsent> revokedConsents = [];

      for (final type in types) {
        try {
          final consent = await revokeConsent(
            userId: userId,
            type: type,
            reason: reason,
            metadata: metadata,
          );
          revokedConsents.add(consent);
        } catch (e) {
          // Continue with other consents even if one fails
          print('Failed to revoke consent for $type: $e');
        }
      }

      return revokedConsents;
    } catch (e) {
      throw Exception('Failed to revoke multiple consents: $e');
    }
  }

  @override
  Future<ConsentStatistics> getConsentStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // This would typically use a database view or stored procedure
      // For now, implementing basic statistics
      
      var query = _client.from('user_consents').select();
      
      if (startDate != null) {
        query = query.gte('granted_at', startDate.toIso8601String());
      }
      
      if (endDate != null) {
        query = query.lte('granted_at', endDate.toIso8601String());
      }

      final response = await query;
      final consents = response.map((json) => UserConsent.fromJson(json)).toList();

      // Calculate statistics
      final uniqueUsers = consents.map((c) => c.userId).toSet();
      final consentsByType = <ConsentType, int>{};
      final revokedByType = <ConsentType, int>{};
      final consentsBySource = <ConsentSource, int>{};

      for (final consent in consents) {
        if (consent.isGranted) {
          consentsByType[consent.type] = (consentsByType[consent.type] ?? 0) + 1;
        } else {
          revokedByType[consent.type] = (revokedByType[consent.type] ?? 0) + 1;
        }
        
        consentsBySource[consent.source] = (consentsBySource[consent.source] ?? 0) + 1;
      }

      return ConsentStatistics(
        totalUsers: uniqueUsers.length,
        usersWithConsents: uniqueUsers.length,
        usersWithoutConsents: 0, // Would need additional query
        consentsByType: consentsByType,
        revokedByType: revokedByType,
        consentsBySource: consentsBySource,
        generatedAt: DateTime.now(),
        periodStart: startDate,
        periodEnd: endDate,
      );
    } catch (e) {
      throw Exception('Failed to get consent statistics: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> exportUserConsentData(String userId) async {
    try {
      final consents = await getUserConsents(userId: userId, includeRevoked: true);
      final auditLogs = await _getAuditLogs(userId);

      return {
        'user_id': userId,
        'consents': consents.map((c) => c.toJson()).toList(),
        'audit_logs': auditLogs,
        'export_timestamp': DateTime.now().toIso8601String(),
        'total_consents': consents.length,
      };
    } catch (e) {
      throw Exception('Failed to export user consent data: $e');
    }
  }

  @override
  Future<void> deleteUserConsentData({
    required String userId,
    required String deletionReason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Log the deletion for audit purposes
      await _logConsentAction(
        userId: userId,
        action: 'delete_all',
        consentType: null,
        consentId: null,
        metadata: {
          'deletion_reason': deletionReason,
          'deleted_at': DateTime.now().toIso8601String(),
          ...?metadata,
        },
      );

      // Delete consent records
      await _client.from('user_consents').delete().eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete user consent data: $e');
    }
  }

  @override
  Future<ConsentComplianceResult> validateUserCompliance(String userId) async {
    try {
      final summary = await getConsentSummary(userId);
      
      final missingEssential = ConsentType.values
          .where((type) => type.isEssential && !summary.hasConsent(type))
          .toList();

      final status = summary.complianceStatus;
      
      return ConsentComplianceResult(
        userId: userId,
        status: status,
        missingEssentialConsents: missingEssential,
        expiredConsents: [], // DPDP doesn't have expiring consents
        issues: [],
        validatedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to validate user compliance: $e');
    }
  }

  @override
  Future<List<String>> getUsersNeedingConsentUpdate({
    ConsentType? specificType,
    Duration? olderThan,
  }) async {
    try {
      // This would typically be implemented with a more complex query
      // For now, returning empty list as placeholder
      return [];
    } catch (e) {
      throw Exception('Failed to get users needing consent update: $e');
    }
  }

  @override
  Future<void> archiveOldConsents({
    required Duration retentionPeriod,
    bool dryRun = false,
  }) async {
    try {
      // Implementation would move old records to archive table
      // For now, this is a placeholder
      if (!dryRun) {
        // Actual archiving logic would go here
      }
    } catch (e) {
      throw Exception('Failed to archive old consents: $e');
    }
  }

  // Private helper methods

  Future<void> _logConsentAction({
    required String userId,
    required String action,
    ConsentType? consentType,
    String? consentId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _client.from('consent_audit_log').insert({
        'id': _uuid.v4(),
        'user_id': userId,
        'action': action,
        'consent_type': consentType?.name,
        'consent_id': consentId,
        'timestamp': DateTime.now().toIso8601String(),
        'metadata': metadata,
      });
    } catch (e) {
      // Log audit failures but don't fail the main operation
      print('Failed to log consent action: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getAuditLogs(String userId) async {
    try {
      final response = await _client
          .from('consent_audit_log')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Failed to get audit logs: $e');
      return [];
    }
  }
}
