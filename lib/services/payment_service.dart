import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_method.dart';
import 'firestore_service.dart';

/// Payment Service
/// Handles payment processing and payment method management
class PaymentService {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _paymentsCollection = 'payments';
  static const String _paymentMethodsCollection = 'paymentMethods';

  /// Create a payment record
  Future<String> createPayment(Payment payment) async {
    final paymentId = await _firestoreService.createDocumentWithAutoId(
      collection: _paymentsCollection,
      data: payment.toMap(),
    );
    return paymentId;
  }

  /// Get payment by ID
  Future<Payment?> getPaymentById(String paymentId) async {
    final data = await _firestoreService.getDocument(
      collection: _paymentsCollection,
      docId: paymentId,
    );

    if (data == null) return null;
    return Payment.fromMap(data);
  }

  /// Update payment status
  Future<void> updatePaymentStatus(
    String paymentId,
    PaymentStatus status,
  ) async {
    await _firestoreService.updateDocument(
      collection: _paymentsCollection,
      docId: paymentId,
      data: {'status': status.name},
    );
  }

  /// Process payment (integration point for payment gateway)
  Future<bool> processPayment({
    required String rideId,
    required String payerId,
    required String receiverId,
    required double amount,
    required PaymentMethodType method,
  }) async {
    try {
      // Create payment record
      final payment = Payment(
        id: '',
        rideId: rideId,
        payerId: payerId,
        receiverId: receiverId,
        amount: amount,
        method: method,
        status: PaymentStatus.pending,
        timestamp: DateTime.now(),
      );

      final paymentId = await createPayment(payment);

      // TODO: Integrate with actual payment gateway (Stripe, JazzCash, EasyPaisa, etc.)
      // For now, simulate successful payment for cash
      if (method == PaymentMethodType.cash) {
        await updatePaymentStatus(paymentId, PaymentStatus.completed);
        return true;
      }

      // For card/wallet, you would call the payment gateway API here
      // Example:
      // final result = await paymentGateway.charge(amount, paymentMethod);
      // if (result.success) {
      //   await updatePaymentStatus(paymentId, PaymentStatus.completed);
      //   return true;
      // }

      return false;
    } catch (e) {
      print('Error processing payment: $e');
      return false;
    }
  }

  /// Refund payment
  Future<bool> refundPayment(String paymentId) async {
    try {
      final payment = await getPaymentById(paymentId);
      if (payment == null || payment.status != PaymentStatus.completed) {
        return false;
      }

      // TODO: Integrate with payment gateway refund API
      // For now, just update status
      await updatePaymentStatus(paymentId, PaymentStatus.refunded);
      return true;
    } catch (e) {
      print('Error refunding payment: $e');
      return false;
    }
  }

  /// Get payment history for user (as payer)
  Future<List<Payment>> getPaymentHistory(String userId) async {
    final docs = await _firestoreService.advancedQuery(
      collection: _paymentsCollection,
      conditions: [
        QueryCondition(field: 'payerId', operator: '==', value: userId),
      ],
      orderByField: 'timestamp',
      descending: true,
      limit: 50,
    );

    return docs.map((doc) => Payment.fromMap(doc)).toList();
  }

  /// Get earnings for driver
  Future<List<Payment>> getEarnings(String driverId) async {
    final docs = await _firestoreService.advancedQuery(
      collection: _paymentsCollection,
      conditions: [
        QueryCondition(field: 'receiverId', operator: '==', value: driverId),
        QueryCondition(
          field: 'status',
          operator: '==',
          value: PaymentStatus.completed.name,
        ),
      ],
      orderByField: 'timestamp',
      descending: true,
      limit: 50,
    );

    return docs.map((doc) => Payment.fromMap(doc)).toList();
  }

  /// Calculate total earnings for driver
  Future<double> getTotalEarnings(String driverId) async {
    final earnings = await getEarnings(driverId);
    return earnings.fold<double>(0, (sum, payment) => sum + payment.amount);
  }

  /// Get payments for a specific ride
  Future<List<Payment>> getPaymentsByRide(String rideId) async {
    final docs = await _firestoreService.queryDocuments(
      collection: _paymentsCollection,
      field: 'rideId',
      value: rideId,
    );

    return docs.map((doc) => Payment.fromMap(doc)).toList();
  }

  /// Add payment method for user
  Future<String> addPaymentMethod(
    String userId,
    PaymentMethod paymentMethod,
  ) async {
    final methodId = await _firestoreService.createDocumentWithAutoId(
      collection: '$_paymentMethodsCollection/$userId/methods',
      data: paymentMethod.toMap(),
    );

    // If this is set as default, unset other defaults
    if (paymentMethod.isDefault) {
      await _setDefaultPaymentMethod(userId, methodId);
    }

    return methodId;
  }

  /// Set default payment method
  Future<void> _setDefaultPaymentMethod(String userId, String methodId) async {
    // Get all payment methods
    final methods = await getPaymentMethods(userId);

    // Update all to not default
    final batch = _firestore.batch();
    for (final method in methods) {
      if (method.id != methodId) {
        final ref = _firestore
            .collection(_paymentMethodsCollection)
            .doc(userId)
            .collection('methods')
            .doc(method.id);
        batch.update(ref, {'isDefault': false});
      }
    }

    // Set the new default
    final newDefaultRef = _firestore
        .collection(_paymentMethodsCollection)
        .doc(userId)
        .collection('methods')
        .doc(methodId);
    batch.update(newDefaultRef, {'isDefault': true});

    await batch.commit();
  }

  /// Get payment methods for user
  Future<List<PaymentMethod>> getPaymentMethods(String userId) async {
    final snapshot = await _firestore
        .collection(_paymentMethodsCollection)
        .doc(userId)
        .collection('methods')
        .get();

    return snapshot.docs
        .map((doc) => PaymentMethod.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
  }

  /// Get default payment method
  Future<PaymentMethod?> getDefaultPaymentMethod(String userId) async {
    final methods = await getPaymentMethods(userId);
    try {
      return methods.firstWhere((method) => method.isDefault);
    } catch (e) {
      return methods.isNotEmpty ? methods.first : null;
    }
  }

  /// Delete payment method
  Future<void> deletePaymentMethod(String userId, String methodId) async {
    await _firestore
        .collection(_paymentMethodsCollection)
        .doc(userId)
        .collection('methods')
        .doc(methodId)
        .delete();
  }

  /// Get payment statistics
  Future<Map<String, dynamic>> getPaymentStatistics(String userId) async {
    final payments = await getPaymentHistory(userId);
    final earnings = await getEarnings(userId);

    final totalSpent = payments
        .where((p) => p.status == PaymentStatus.completed)
        .fold<double>(0, (sum, p) => sum + p.amount);

    final totalEarned = earnings.fold<double>(0, (sum, p) => sum + p.amount);

    return {
      'totalSpent': totalSpent,
      'totalEarned': totalEarned,
      'totalTransactions': payments.length,
      'completedPayments': payments
          .where((p) => p.status == PaymentStatus.completed)
          .length,
      'pendingPayments': payments
          .where((p) => p.status == PaymentStatus.pending)
          .length,
      'failedPayments': payments
          .where((p) => p.status == PaymentStatus.failed)
          .length,
    };
  }

  /// Listen to payment changes
  Stream<Payment?> listenToPayment(String paymentId) {
    return _firestoreService
        .listenToDocument(collection: _paymentsCollection, docId: paymentId)
        .map((data) => data != null ? Payment.fromMap(data) : null);
  }
}
