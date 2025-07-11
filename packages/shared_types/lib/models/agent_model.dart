import 'package:equatable/equatable.dart';

/// Agent status enumeration
enum AgentStatus {
  pending,
  verified,
  active,
  inactive,
  suspended,
}

/// Document type enumeration for Indian verification
enum DocumentType {
  aadhaar,
  govtId,
  pan,
  drivingLicense,
}

/// Document status enumeration
enum DocumentStatus {
  pending,
  verified,
  rejected,
}

/// Agent model for delivery agents
class AgentModel extends Equatable {
  final String id;
  final String userId;
  final String agentId; // Simple ID for login
  final String fullName;
  final String phone;
  final String? email;
  final String? assignedZone;
  final AgentStatus status;
  final int totalDeliveries;
  final double totalEarnings;
  final DateTime joinDate;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AgentModel({
    required this.id,
    required this.userId,
    required this.agentId,
    required this.fullName,
    required this.phone,
    this.email,
    this.assignedZone,
    this.status = AgentStatus.pending,
    this.totalDeliveries = 0,
    this.totalEarnings = 0.0,
    required this.joinDate,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create AgentModel from JSON
  factory AgentModel.fromJson(Map<String, dynamic> json) {
    return AgentModel(
      id: json['id'],
      userId: json['user_id'],
      agentId: json['agent_id'],
      fullName: json['full_name'],
      phone: json['phone'],
      email: json['email'],
      assignedZone: json['assigned_zone'],
      status: AgentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AgentStatus.pending,
      ),
      totalDeliveries: json['total_deliveries'] ?? 0,
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0.0,
      joinDate: DateTime.parse(json['join_date']),
      isVerified: json['is_verified'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  /// Convert AgentModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'agent_id': agentId,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'assigned_zone': assignedZone,
      'status': status.name,
      'total_deliveries': totalDeliveries,
      'total_earnings': totalEarnings,
      'join_date': joinDate.toIso8601String(),
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  AgentModel copyWith({
    String? id,
    String? userId,
    String? agentId,
    String? fullName,
    String? phone,
    String? email,
    String? assignedZone,
    AgentStatus? status,
    int? totalDeliveries,
    double? totalEarnings,
    DateTime? joinDate,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AgentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      agentId: agentId ?? this.agentId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      assignedZone: assignedZone ?? this.assignedZone,
      status: status ?? this.status,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      joinDate: joinDate ?? this.joinDate,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        agentId,
        fullName,
        phone,
        email,
        assignedZone,
        status,
        totalDeliveries,
        totalEarnings,
        joinDate,
        isVerified,
        createdAt,
        updatedAt,
      ];
}