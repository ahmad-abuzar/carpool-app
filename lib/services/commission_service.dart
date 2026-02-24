import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/commission.dart';
import '../models/user.dart';
import 'firestore_service.dart';

/// Commission Service
/// Handles earnings tracking, 5% commission calculation, and profile locking
class CommissionService {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _commissionsCollection = 'commissions';
  static const String _usersCollection = 'users';
  static const double commissionRate = 0.05; // 5%
  static const int ridesBeforeLock = 4;

  /// Record earnings from a completed ride and create commission record
  Future<void> recordRideEarning({
    required String userId,
    required String rideId,
    required double rideEarnings,
  }) async {
    try {
      final commissionAmount = Commission.calculateCommission(rideEarnings);

      // Create commission record
      final commission = Commission(
        id: '',
        userId: userId,
        rideId: rideId,
        rideEarnings: rideEarnings,
        commissionAmount: commissionAmount,
        status: CommissionStatus.pending,
        createdAt: DateTime.now(),
      );

      await _firestoreService.createDocumentWithAutoId(
        collection: _commissionsCollection,
        data: commission.toMap(),
      );

      // Update user's commission tracking fields
      await _firestore.collection(_usersCollection).doc(userId).update({
        'totalCommissionOwed': FieldValue.increment(commissionAmount),
        'completedRidesSinceLastPayment': FieldValue.increment(1),
      });

      // Check if profile should be locked (4 rides completed)
      final userData = await _firestoreService.getDocument(
        collection: _usersCollection,
        docId: userId,
      );

      if (userData != null) {
        final ridesSincePayment =
            (userData['completedRidesSinceLastPayment'] as int? ?? 0);
        if (ridesSincePayment >= ridesBeforeLock) {
          await lockProfile(userId);
        }
      }

      print('✅ Commission recorded: Rs $commissionAmount for ride $rideId');
    } catch (e) {
      print('❌ Error recording ride earning: $e');
    }
  }

  /// Lock user's profile (admin action or automatic after 4 rides)
  Future<void> lockProfile(String userId) async {
    await _firestore.collection(_usersCollection).doc(userId).update({
      'isProfileLocked': true,
    });
    print('🔒 Profile locked for user $userId');
  }

  /// Unlock user's profile (admin action)
  Future<void> unlockProfile(String userId) async {
    await _firestore.collection(_usersCollection).doc(userId).update({
      'isProfileLocked': false,
    });
    print('🔓 Profile unlocked for user $userId');
  }

  /// Mark commission as paid (admin action)
  Future<void> markCommissionPaid({
    required String userId,
    required double amount,
  }) async {
    try {
      // Get all pending commissions for user
      final pendingDocs = await _firestore
          .collection(_commissionsCollection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: CommissionStatus.pending.name)
          .get();

      // Mark them as paid
      final batch = _firestore.batch();
      for (final doc in pendingDocs.docs) {
        batch.update(doc.reference, {
          'status': CommissionStatus.paid.name,
          'paidAt': DateTime.now().millisecondsSinceEpoch,
        });
      }
      await batch.commit();

      // Update user commission tracking
      await _firestore.collection(_usersCollection).doc(userId).update({
        'totalCommissionPaid': FieldValue.increment(amount),
        'totalCommissionOwed': 0.0,
        'completedRidesSinceLastPayment': 0,
        'isProfileLocked': false,
      });

      print('✅ Commission paid for user $userId: Rs $amount');
    } catch (e) {
      print('❌ Error marking commission paid: $e');
    }
  }

  /// Get commission summary for a user
  Future<CommissionSummary> getCommissionSummary(String userId) async {
    try {
      final userData = await _firestoreService.getDocument(
        collection: _usersCollection,
        docId: userId,
      );

      if (userData == null) return const CommissionSummary();

      final allCommissions = await _firestore
          .collection(_commissionsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final totalEarnings = allCommissions.docs.fold<double>(
        0,
        (sum, doc) =>
            sum + ((doc.data()['rideEarnings'] as num?)?.toDouble() ?? 0),
      );

      return CommissionSummary(
        totalEarnings: totalEarnings,
        totalCommissionOwed:
            (userData['totalCommissionOwed'] as num?)?.toDouble() ?? 0,
        totalCommissionPaid:
            (userData['totalCommissionPaid'] as num?)?.toDouble() ?? 0,
        completedRidesSinceLastPayment:
            userData['completedRidesSinceLastPayment'] as int? ?? 0,
        isLocked: userData['isProfileLocked'] as bool? ?? false,
      );
    } catch (e) {
      print('❌ Error getting commission summary: $e');
      return const CommissionSummary();
    }
  }

  /// Get all commissions for a user
  Future<List<Commission>> getUserCommissions(String userId) async {
    try {
      final docs = await _firestore
          .collection(_commissionsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return docs.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Commission.fromMap(data);
      }).toList();
    } catch (e) {
      print('❌ Error getting user commissions: $e');
      return [];
    }
  }

  /// Get all pending commissions (admin)
  Future<List<Commission>> getAllPendingCommissions() async {
    try {
      final docs = await _firestore
          .collection(_commissionsCollection)
          .where('status', isEqualTo: CommissionStatus.pending.name)
          .orderBy('createdAt', descending: true)
          .get();

      return docs.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Commission.fromMap(data);
      }).toList();
    } catch (e) {
      print('❌ Error getting pending commissions: $e');
      return [];
    }
  }

  /// Get all commissions (admin)
  Future<List<Commission>> getAllCommissions() async {
    try {
      final docs = await _firestore
          .collection(_commissionsCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return docs.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Commission.fromMap(data);
      }).toList();
    } catch (e) {
      print('❌ Error getting all commissions: $e');
      return [];
    }
  }

  /// Get all users (admin)
  Future<List<User>> getAllUsers() async {
    try {
      final docs = await _firestore.collection(_usersCollection).get();
      return docs.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return User.fromMap(data);
      }).toList();
    } catch (e) {
      print('❌ Error getting all users: $e');
      return [];
    }
  }

  /// Get locked users (admin)
  Future<List<User>> getLockedUsers() async {
    try {
      final docs = await _firestore
          .collection(_usersCollection)
          .where('isProfileLocked', isEqualTo: true)
          .get();

      return docs.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return User.fromMap(data);
      }).toList();
    } catch (e) {
      print('❌ Error getting locked users: $e');
      return [];
    }
  }

  /// Get admin dashboard stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final allUsers = await getAllUsers();
      final allCommissions = await getAllCommissions();
      final lockedUsers = allUsers.where((u) => u.isProfileLocked).length;
      final activeRiders = allUsers
          .where((u) => u.role == UserRole.driver || u.role == UserRole.both)
          .length;

      final totalCommissionCollected = allCommissions
          .where((c) => c.status == CommissionStatus.paid)
          .fold<double>(0, (sum, c) => sum + c.commissionAmount);

      final totalCommissionPending = allCommissions
          .where((c) => c.status == CommissionStatus.pending)
          .fold<double>(0, (sum, c) => sum + c.commissionAmount);

      return {
        'totalUsers': allUsers.length,
        'activeRiders': activeRiders,
        'lockedProfiles': lockedUsers,
        'totalCommissionCollected': totalCommissionCollected,
        'totalCommissionPending': totalCommissionPending,
        'totalCommissions': allCommissions.length,
      };
    } catch (e) {
      print('❌ Error getting dashboard stats: $e');
      return {};
    }
  }

  /// Check if user profile is locked
  Future<bool> isProfileLocked(String userId) async {
    try {
      final userData = await _firestoreService.getDocument(
        collection: _usersCollection,
        docId: userId,
      );
      return userData?['isProfileLocked'] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }
}
