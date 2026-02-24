import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/commission.dart';
import '../models/user.dart';
import '../services/commission_service.dart';

/// Commission service provider
final commissionServiceProvider = Provider<CommissionService>((ref) {
  return CommissionService();
});

/// Admin dashboard stats provider
final adminDashboardStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final service = ref.watch(commissionServiceProvider);
  return service.getDashboardStats();
});

/// All users provider (admin)
final adminUsersProvider = FutureProvider<List<User>>((ref) async {
  final service = ref.watch(commissionServiceProvider);
  return service.getAllUsers();
});

/// All commissions provider (admin)
final adminCommissionsProvider = FutureProvider<List<Commission>>((ref) async {
  final service = ref.watch(commissionServiceProvider);
  return service.getAllCommissions();
});

/// Pending commissions provider (admin)
final adminPendingCommissionsProvider = FutureProvider<List<Commission>>((
  ref,
) async {
  final service = ref.watch(commissionServiceProvider);
  return service.getAllPendingCommissions();
});

/// Locked users provider (admin)
final adminLockedUsersProvider = FutureProvider<List<User>>((ref) async {
  final service = ref.watch(commissionServiceProvider);
  return service.getLockedUsers();
});

/// User commission summary provider
final userCommissionSummaryProvider =
    FutureProvider.family<CommissionSummary, String>((ref, userId) async {
      final service = ref.watch(commissionServiceProvider);
      return service.getCommissionSummary(userId);
    });

/// User commissions list provider
final userCommissionsProvider = FutureProvider.family<List<Commission>, String>(
  (ref, userId) async {
    final service = ref.watch(commissionServiceProvider);
    return service.getUserCommissions(userId);
  },
);
