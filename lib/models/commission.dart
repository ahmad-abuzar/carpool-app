/// Commission record for tracking 5% earnings deduction per ride
enum CommissionStatus { pending, paid }

class Commission {
  final String id;
  final String userId;
  final String rideId;
  final double rideEarnings; // Total ride earning
  final double commissionAmount; // 5% of rideEarnings
  final CommissionStatus status;
  final DateTime createdAt;
  final DateTime? paidAt;

  const Commission({
    required this.id,
    required this.userId,
    required this.rideId,
    required this.rideEarnings,
    required this.commissionAmount,
    this.status = CommissionStatus.pending,
    required this.createdAt,
    this.paidAt,
  });

  /// Calculate commission from ride earnings
  static double calculateCommission(double earnings) => earnings * 0.05;

  Commission copyWith({CommissionStatus? status, DateTime? paidAt}) {
    return Commission(
      id: id,
      userId: userId,
      rideId: rideId,
      rideEarnings: rideEarnings,
      commissionAmount: commissionAmount,
      status: status ?? this.status,
      createdAt: createdAt,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'rideId': rideId,
      'rideEarnings': rideEarnings,
      'commissionAmount': commissionAmount,
      'status': status.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'paidAt': paidAt?.millisecondsSinceEpoch,
    };
  }

  factory Commission.fromMap(Map<String, dynamic> map) {
    return Commission(
      id: map['id'] as String,
      userId: map['userId'] as String,
      rideId: map['rideId'] as String,
      rideEarnings: (map['rideEarnings'] as num).toDouble(),
      commissionAmount: (map['commissionAmount'] as num).toDouble(),
      status: CommissionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CommissionStatus.pending,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      paidAt: map['paidAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['paidAt'] as int)
          : null,
    );
  }
}

/// Summary of a user's commission state (used in admin panel)
class CommissionSummary {
  final double totalEarnings;
  final double totalCommissionOwed;
  final double totalCommissionPaid;
  final int completedRidesSinceLastPayment;
  final bool isLocked;

  const CommissionSummary({
    this.totalEarnings = 0,
    this.totalCommissionOwed = 0,
    this.totalCommissionPaid = 0,
    this.completedRidesSinceLastPayment = 0,
    this.isLocked = false,
  });
}
