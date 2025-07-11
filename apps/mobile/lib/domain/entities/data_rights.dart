import 'dart:io';

/// Data Rights Entities for DPDP Act 2023 Compliance
/// 
/// These entities represent user data rights and related operations
/// as mandated by the Digital Personal Data Protection Act 2023.

/// Export formats supported for data export
enum DataExportFormat {
  json('json'),
  csv('csv');

  const DataExportFormat(this.extension);
  final String extension;
}

/// Types of data rights actions
enum DataRightsAction {
  export,
  correction,
  deletion,
}

/// Scope of data deletion
enum DataDeletionScope {
  profile,      // Only profile data
  orders,       // Only order history
  complete,     // Complete account deletion
}

/// Result of data export operation
class DataExportResult {
  final bool success;
  final File? file;
  final DataExportFormat? format;
  final DateTime exportedAt;
  final int? recordCount;
  final int? fileSizeBytes;
  final String? error;

  const DataExportResult({
    required this.success,
    this.file,
    this.format,
    required this.exportedAt,
    this.recordCount,
    this.fileSizeBytes,
    this.error,
  });

  /// Gets human-readable file size
  String get fileSizeFormatted {
    if (fileSizeBytes == null) return 'Unknown';
    
    final bytes = fileSizeBytes!;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Gets export summary for user display
  String get summary {
    if (!success) return error ?? 'Export failed';
    
    return 'Exported ${recordCount ?? 0} records (${fileSizeFormatted}) in ${format?.extension.toUpperCase()} format';
  }
}

/// Request for data correction
class DataCorrectionRequest {
  final String field;
  final String currentValue;
  final String newValue;
  final String reason;
  final DateTime requestedAt;
  final Map<String, dynamic>? metadata;

  const DataCorrectionRequest({
    required this.field,
    required this.currentValue,
    required this.newValue,
    required this.reason,
    required this.requestedAt,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'field': field,
      'current_value': currentValue,
      'new_value': newValue,
      'reason': reason,
      'requested_at': requestedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory DataCorrectionRequest.fromJson(Map<String, dynamic> json) {
    return DataCorrectionRequest(
      field: json['field'] as String,
      currentValue: json['current_value'] as String,
      newValue: json['new_value'] as String,
      reason: json['reason'] as String,
      requestedAt: DateTime.parse(json['requested_at'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Result of data correction request
class DataCorrectionResult {
  final bool success;
  final String? correctionId;
  final Map<String, DataCorrectionRequest>? acceptedCorrections;
  final Map<String, String>? rejectedCorrections;
  final int? estimatedProcessingDays;
  final DateTime requestedAt;
  final String? error;

  const DataCorrectionResult({
    required this.success,
    this.correctionId,
    this.acceptedCorrections,
    this.rejectedCorrections,
    this.estimatedProcessingDays,
    required this.requestedAt,
    this.error,
  });

  /// Gets summary of correction request
  String get summary {
    if (!success) return error ?? 'Correction request failed';
    
    final accepted = acceptedCorrections?.length ?? 0;
    final rejected = rejectedCorrections?.length ?? 0;
    
    return 'Correction request submitted: $accepted accepted, $rejected rejected. '
           'Processing time: ${estimatedProcessingDays ?? 30} days.';
  }
}

/// Result of data deletion request
class DataDeletionResult {
  final bool success;
  final String? deletionId;
  final DataDeletionScope? scope;
  final bool? requiresApproval;
  final int? estimatedProcessingDays;
  final DateTime requestedAt;
  final String? error;

  const DataDeletionResult({
    required this.success,
    this.deletionId,
    this.scope,
    this.requiresApproval,
    this.estimatedProcessingDays,
    required this.requestedAt,
    this.error,
  });

  /// Gets summary of deletion request
  String get summary {
    if (!success) return error ?? 'Deletion request failed';
    
    final scopeText = scope?.name ?? 'unknown';
    final approvalText = requiresApproval == true ? ' (requires approval)' : '';
    
    return 'Deletion request submitted for $scopeText data$approvalText. '
           'Processing time: ${estimatedProcessingDays ?? 30} days.';
  }
}

/// Status of a data rights request
class DataRightsRequestStatus {
  final String id;
  final String userId;
  final DataRightsAction action;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? estimatedCompletion;
  final String? reason;
  final Map<String, dynamic>? details;
  final String? processingNotes;

  const DataRightsRequestStatus({
    required this.id,
    required this.userId,
    required this.action,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.estimatedCompletion,
    this.reason,
    this.details,
    this.processingNotes,
  });

  factory DataRightsRequestStatus.fromJson(Map<String, dynamic> json) {
    return DataRightsRequestStatus(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      action: DataRightsAction.values.firstWhere(
        (e) => e.name == json['action'],
        orElse: () => DataRightsAction.export,
      ),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'] as String) 
          : null,
      estimatedCompletion: json['estimated_completion'] != null 
          ? DateTime.parse(json['estimated_completion'] as String) 
          : null,
      reason: json['reason'] as String?,
      details: json['details'] as Map<String, dynamic>?,
      processingNotes: json['processing_notes'] as String?,
    );
  }

  /// Whether the request is still pending
  bool get isPending {
    return status == 'pending' || status == 'pending_approval' || status == 'processing';
  }

  /// Whether the request is completed
  bool get isCompleted {
    return status == 'completed' || status == 'approved';
  }

  /// Whether the request was rejected or failed
  bool get isFailed {
    return status == 'rejected' || status == 'failed' || status == 'cancelled';
  }

  /// Gets user-friendly status text
  String get statusText {
    switch (status) {
      case 'pending':
        return 'Pending Review';
      case 'pending_approval':
        return 'Pending Approval';
      case 'processing':
        return 'Processing';
      case 'completed':
        return 'Completed';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'failed':
        return 'Failed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  /// Gets estimated days remaining for completion
  int? get daysRemaining {
    if (estimatedCompletion == null || isCompleted || isFailed) return null;
    
    final remaining = estimatedCompletion!.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  /// Gets action description
  String get actionDescription {
    switch (action) {
      case DataRightsAction.export:
        return 'Data Export';
      case DataRightsAction.correction:
        return 'Data Correction';
      case DataRightsAction.deletion:
        return 'Data Deletion';
    }
  }
}

/// Validation result for correction requests
class CorrectionValidationResult {
  final bool isValid;
  final String? reason;

  const CorrectionValidationResult({
    required this.isValid,
    this.reason,
  });
}

/// Validation result for deletion requests
class DeletionValidationResult {
  final bool canDelete;
  final String? reason;

  const DeletionValidationResult({
    required this.canDelete,
    this.reason,
  });
}
