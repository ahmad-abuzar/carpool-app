enum PaymentMethodType { cash, card, wallet }

enum PaymentStatus { pending, completed, failed, refunded }

class PaymentMethod {
  final String id;
  final PaymentMethodType type;
  final String displayName; // e.g., "Cash", "Visa ****1234", "PayPal"
  final bool isDefault;
  final String? cardLast4;
  final String? iconAsset;

  const PaymentMethod({
    required this.id,
    required this.type,
    required this.displayName,
    this.isDefault = false,
    this.cardLast4,
    this.iconAsset,
  });

  // Firebase serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'displayName': displayName,
      'isDefault': isDefault,
      'cardLast4': cardLast4,
      'iconAsset': iconAsset,
    };
  }

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      id: map['id'] as String,
      type: PaymentMethodType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => PaymentMethodType.cash,
      ),
      displayName: map['displayName'] as String,
      isDefault: map['isDefault'] as bool? ?? false,
      cardLast4: map['cardLast4'] as String?,
      iconAsset: map['iconAsset'] as String?,
    );
  }
}

class Payment {
  final String id;
  final String rideId;
  final String payerId;
  final String receiverId;
  final double amount;
  final PaymentMethodType method;
  final PaymentStatus status;
  final DateTime timestamp;

  const Payment({
    required this.id,
    required this.rideId,
    required this.payerId,
    required this.receiverId,
    required this.amount,
    required this.method,
    required this.status,
    required this.timestamp,
  });

  // Firebase serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rideId': rideId,
      'payerId': payerId,
      'receiverId': receiverId,
      'amount': amount,
      'method': method.name,
      'status': status.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as String,
      rideId: map['rideId'] as String,
      payerId: map['payerId'] as String,
      receiverId: map['receiverId'] as String,
      amount: (map['amount'] as num).toDouble(),
      method: PaymentMethodType.values.firstWhere(
        (e) => e.name == map['method'],
        orElse: () => PaymentMethodType.cash,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PaymentStatus.pending,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }
}
